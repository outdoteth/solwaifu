// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import { DSTest } from "ds-test/test.sol";

// prettier-ignore
contract ERC20Deployer is DSTest {
  string _name;
  string _symbol;
  uint256 _decimals;
  uint256 _totalSupply;
  address _creator;

  function deploy(
    // use memory instead of calldata for better composability
    string memory name_,
    string memory symbol_,
    uint256 decimals_,
    uint256 totalSupply_,
    address creator_
  ) public returns (address tokenAddress) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    _totalSupply = totalSupply_;
    _creator = creator_;

    // ----------------------------------------
    // These are all the implementations for the ERC20 functions
    // ----------------------------------------

    // Constructor
    bytes memory deployCode = _deployCode();

    // Entrypoint - Determines which function to jump to
    bytes memory entrypoint = _entrypoint();

    // Revert helper - util function to revert and return false
    bytes memory revertHelper = _revertHelper();

    // ERC20 implementation
    // function totalSupply() public view returns (uint256)
    // function balanceOf(address _owner) public view returns (uint256 balance)
    // function transfer(address _to, uint256 _value) public returns (bool success)    
    // function approve(address _spender, uint256 _value) public returns (bool success)
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    bytes memory totalSupply = __totalSupply();
    bytes memory balanceOf = _balanceOf();
    bytes memory transfer = _transfer();
    bytes memory approve = _approve();
    bytes memory allowance = _allowance();
    bytes memory transferFrom = _transferFrom();

    // ERC20Metadata implementation
    // function decimals() public view returns (uint8)
    // function name() public view returns (string)
    // function symbol() public view returns (string)
    bytes memory decimals = __decimals();
    bytes memory name = __name();
    bytes memory symbol = __symbol();

    { // i put my stack "deep" in ur mom. maybe u should try popping vars next time. dumb compiler.
      // Take the last 2 bytes of the logs to get the JUMPDEST locations for each of the functions.
      // emit log_named_uint("Entrypoint size: ", entrypoint.length);
      // emit log_named_uint("Revert helper size: ", revertHelper.length);
      // emit log_named_uint("totalSupply size: ", totalSupply.length);
      // emit log_named_uint("balanceOf size: ", balanceOf.length);
      // emit log_named_uint("transfer size: ", transfer.length);
      // emit log_named_uint("approve size: ", approve.length);
      // emit log_named_uint("allowance size: ", allowance.length);
      // emit log_named_uint("transferFrom size: ", transferFrom.length);
      // emit log_named_uint("decimals size: ", decimals.length);
      // emit log_named_uint("name size: ", name.length);
      // emit log_named_uint("symbol size: ", symbol.length);

      // emit log("\n\nbytecode jumpdests: ");
      // uint256 revertOffset = entrypoint.length;
      // emit log_named_bytes32("revertHelper ", bytes32(revertOffset));
      // uint256 totalSupplyOffset = revertOffset + revertHelper.length;
      // emit log_named_bytes32("totalSupply ", bytes32(totalSupplyOffset));
      // uint256 balanceOfOffset = totalSupplyOffset + totalSupply.length;
      // emit log_named_bytes32("balanceOf ", bytes32(balanceOfOffset));
      // uint256 transferOffset = balanceOfOffset + balanceOf.length;
      // emit log_named_bytes32("transfer ", bytes32(transferOffset));
      // uint256 approveOffset = transferOffset + transfer.length;
      // emit log_named_bytes32("approve ", bytes32(approveOffset));
      // uint256 allowanceOffset = approveOffset + approve.length;
      // emit log_named_bytes32("allowance ", bytes32(allowanceOffset));
      // uint256 transferFromOffset = allowanceOffset + allowance.length;
      // emit log_named_bytes32("transferFrom ", bytes32(transferFromOffset));
      // uint256 decimalsOffset = transferFromOffset + transferFrom.length;
      // emit log_named_bytes32("decimals ", bytes32(decimalsOffset));
      // uint256 nameOffset = decimalsOffset + decimals.length;
      // emit log_named_bytes32("name ", bytes32(nameOffset));
      // uint256 symbolOffset = nameOffset + name.length;
      // emit log_named_bytes32("symbol ", bytes32(symbolOffset));
    }
    
    // pack in 3 calls to avoid stack too deep error ARGGGHHH
    bytes memory bytecode = abi.encodePacked(
      deployCode, 
      entrypoint, 
      revertHelper,
      totalSupply,
      balanceOf,
      transfer
    );
    bytecode = abi.encodePacked(
      bytecode,
      approve,
      allowance,
      transferFrom,
      decimals,
      name
    );
    bytecode = abi.encodePacked(
      bytecode,
      symbol
    );

    assembly {
      tokenAddress := create(0, add(bytecode, 0x20), mload(bytecode))
    }
  }

  function _deployCode() internal view returns (bytes memory) {
    // constructor logic 
    return abi.encodePacked(
      // save constructor variables
      hex"7f", _totalSupply,    // PUSH32 totalSupply
      hex"73", _creator,        // PUSH20 creator
      hex"55"                   // SSTORE -> give the totalSupply to the creator

      // copy code into memory
      hex"61" hex"0fff"         // PUSH2 0x0fff -> length of runtime code (4095 bytes to give room for editing)
      hex"60" hex"45"           // PUSH1 0x45 -> offset (length of deployCode - all this stuff)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"39"                   // CODECOPY

      // deploy code
      hex"61" hex"0fff"         // PUSH2 0x0156 -> length of runtime code
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"f3"                   // RETURN
    );
  }

  function _entrypoint() internal pure returns (bytes memory) {
    // entrypoint - jumps to correct selector
    return  
        // extract the 4 byte function sig
        hex"60" hex"00"           // PUSH1 0x00 -> calldata offset
        hex"35"                   // CALLDATALOAD
        hex"60" hex"e0"           // PUSH1 0xe0 -> 0xe0 == 224 == 32 bytes - 4 byte function sig
        hex"1c"                   // SHR -> shift right to extract just the 4 byte function sig

        // totalSupply()
        hex"80"                   // DUP1
        hex"63" hex"18160ddd"     // PUSH2 totalSupply() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"0074"         // PUSH2 0x0074 (JUMPDEST)
        hex"57"                   // JUMPI                   

        // balanceOf()
        hex"80"                   // DUP1
        hex"63" hex"70a08231"     // PUSH2 balanceOf() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"009e"         // PUSH2 0x009e (JUMPDEST)
        hex"57"                   // JUMPI   

        // transfer()
        hex"80"                   // DUP1
        hex"63" hex"a9059cbb"     // PUSH2 transfer() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"00ab"         // PUSH2 0x00ab (JUMPDEST)
        hex"57"                   // JUMPI   

        // approve()
        hex"80"                   // DUP1
        hex"63" hex"095ea7b3"     // PUSH2 approve() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"0104"         // PUSH2 0x0104 (JUMPDEST)
        hex"57"                   // JUMPI  

        // allowance()
        hex"80"                   // DUP1
        hex"63" hex"dd62ed3e"     // PUSH2 allowance() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"0155"         // PUSH2 0x0155 (JUMPDEST)
        hex"57"                   // JUMPI  

        // transferFrom()
        hex"80"                   // DUP1
        hex"63" hex"23b872dd"     // PUSH2 transferFrom() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"016b"         // PUSH2 0x016b (JUMPDEST)
        hex"57"                   // JUMPI  

        // decimals()
        hex"80"                   // DUP1
        hex"63" hex"313ce567"     // PUSH2 decimals() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"0221"         // PUSH2 0x0221 (JUMPDEST)
        hex"57"                   // JUMPI  

        // name()
        hex"80"                   // DUP1
        hex"63" hex"06fdde03"     // PUSH2 name() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"024b"         // PUSH2 0x024b (JUMPDEST)
        hex"57"                   // JUMPI  

        // symbol()
        hex"80"                   // DUP1
        hex"63" hex"95d89b41"     // PUSH2 symbol() signature
        hex"14"                   // EQ -> check if we have a sig match
        hex"61" hex"02a5"         // PUSH2 0x02a5 (JUMPDEST)
        hex"57"                   // JUMPI  
    ;
  }

  function _revertHelper() internal pure returns (bytes memory) {
    return     
      // Helper to revert and return (bool success = false)
      // https://www.evm.codes/playground?unit=Wei&callData=0x70a08231000000000000000000000000b4c79dab8f259c7aee6e5b2aa729821864227e840000000000000000000000000000000000000000000000000000000000000011&codeType=Mnemonic&code='~~MSTOREyz20y~REVERT'~z00yzPUSH1%200xy%5Cn%01yz~_
      hex"5b"                   // JUMPDEST
      hex"60" hex"00"           // PUSH1 0x00 -> false
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE
      hex"60" hex"20"           // PUSH1 0x20 -> data len
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"fd"                   // REVERT
    ;
  }

  function __totalSupply() internal view returns (bytes memory) {
    // function totalSupply() external view returns (uint256)
    // https://www.evm.codes/playground?unit=Wei&codeType=Mnemonic&code='%2F%2F%20%7Busqa%20fakqtotal%20supply%20uint256%20herq-%20it%22s%20inlined%20anyway%7Dg32j~~~~~~~md3c21bcecceda1~zmvMSTOREvz20zmvRETURN'~mmmzg1jv%5Cnqe%20m00j%200xgvPUSH%01gjmqvz~_
    return abi.encodePacked(
      hex"5b"                   // JUMPDEST
      hex"7f", _totalSupply,    // PUSH32 totalSupply
      hex"60", hex"00",         // PUSH 0x00 -> memptr
      hex"52"                   // MSTORE
      hex"60" hex"20"           // PUSH 0x20 -> 32 byte len
      hex"60" hex"00"           // PUSH 0x00 -> memptr
      hex"f3"                   // RETURN
    );  
  }

  function _balanceOf() internal pure returns (bytes memory) {
    // function balanceOf(address _owner) public view returns (uint256 balance)
    // https://www.evm.codes/playground?unit=Wei&callData=0x70a08231000000000000000000000000b4c79dab8f259c7aee6e5b2aa729821864227e84&codeType=Mnemonic&code='~04zCALLDATAySywMSTOREz~20zwRETURN'~PUSH1%200xz%5CnyLOADzw~00z%01wyz~_  
    return abi.encodePacked(
      hex"5b"                   // JUMPDEST
      hex"60" hex"04"           // PUSH1 0x04 -> 4 byte offset (ignore function sig)
      hex"35"                   // CALLDATALOAD -> get the address
      hex"54"                   // SLOAD -> get the balance (literally: key(address) -> value(balance))
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE
      hex"60" hex"20"           // PUSH1 0x20 -> (32 byte len)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"f3"                   // RETURN
    );
  }

  function _transfer() internal pure returns (bytes memory) {
    // function transfer(address _to, uint256 _value) public returns (bool success)
    // https://www.evm.codes/playground?unit=Wei&callData=0x70a08231000000000000000000000000b4c79dab8f259c7aee6e5b2aa729821864227e840000000000000000000000000000000000000000000000000000000000000011&codeType=Mnemonic&code='p--%20SETUP%20%7Bno)included%20in%20actual%20contract%7DzpPu)somKdummy!in%20theYz*jjjjjjj00d3c21bcecceda1jZSXzzpcheckY%20has%20enough!-%20otherwisKrevertZS(~2qzGT~4FzJUMPIzzpdeduc)fromY~2qZS(zSUBZSXzzpadd%20to%20_to~0qzS(~2qzADD~0qzSXzzpfirKtransfer%20eventzpeven)Transfer%7BWfrom%2C%20Wto%2C%20uint256%20_value%7D~2qQMX~0qZ*ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef~20QLOG3z~01QMX~20QRETURNzzp79%20byteszp0x4FzzJUMPDEST~00QMX~20QREVERTz'~zPUSH1%200xz%5Cnq4zCALLDATA(p%2F%2F%20j000000ZzCALLERzY%20msg.senderXSTOREWaddress%20indexed%20_Q~00zKe%20*PUSH32%200x)t%20(LOAD!%20balancK%01!()*KQWXYZjpqz~_
    // throw if user does not have enough balance
    // fire Transfer event
    return
      // check msg.sender has enough balance
      hex"5b"                   // JUMPDEST
      hex"33"                   // CALLER
      hex"54"                   // SLOAD -> get the msg.sender's balance
      hex"60" hex"24"           // PUSH1 0x24 -> offset by function sig (4 bytes) + _to (32 bytes)
      hex"35"                   // CALLDATALOAD -> get the _amount
      hex"11"                   // GT -> Check that the user has enough balance
      hex"61" hex"0069"         // PUSH2 0x0069 -> destination of revert helper
      hex"57"                   // JUMPI -> revert tx if user doesn't have enough balance

      // deduct _amount from msg.sender
      hex"60" hex"24"           // PUSH1 0x24 -> function sig (4 bytes) + _to (32 bytes)
      hex"35"                   // CALLDATALOAD -> get the _amount
      hex"33"                   // CALLER
      hex"54"                   // SLOAD -> get the msg.sender's balance
      hex"03"                   // SUB -> get msg.sender's new balance
      hex"33"                   // CALLER
      hex"55"                   // SSTORE

      // add _amount to _to
      hex"60" hex"04"           // PUSH1 0x04 -> offset by function sig (4 bytes)
      hex"35"                   // CALLDATALOAD -> get the _to
      hex"54"                   // SLOAD -> get the _to's balance
      hex"60" hex"24"           // PUSH1 0x24 -> function sig (4 bytes) + _to (32 bytes)
      hex"35"                   // CALLDATALOAD -> get the _amount
      hex"01"                   // ADD -> get _to's new balance
      hex"60" hex"04"           // PUSH1 0x04 -> offset by function sig (4 bytes)
      hex"35"                   // CALLDATALOAD -> get the _to
      hex"55"                   // SSTORE -> update _to's balance

      // fire Transfer(address indexed _from, address indexed _to, uint256 _value) event
      hex"60" hex"24"           // PUSH1 0x24 -> function sig (4 bytes) + _to (32 bytes)
      hex"35"                   // CALLDATALOAD -> get the _amount
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTSORE -> store the _amount in memory
      hex"60" hex"04"           // PUSH1 0x04 -> offset by function sig (4 bytes)
      hex"35"                   // CALLDATALOAD -> get the _to
      hex"33"                   // CALLER -> _from
      hex"7f" hex"ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" // PUSH32 keccak256(Transfer)
      hex"60" hex"20"           // PUSH1 0x20 -> 32 byte len (for _amount)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"a3"                   // LOG3 -> fire the Transfer event

      // return true (10 bytes)
      hex"60" hex"01"           // PUSH1 0x01 -> true
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE -> store true 
      hex"60" hex"20"           // PUSH1 0x20 -> data len
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"f3"                   // RETURN
    ;
  }

  function _approve() internal pure returns (bytes memory) {
    // function approve(address _spender, uint256 _value) public returns (bool success)
    // https://www.evm.codes/playground?unit=Wei&callData=0x70a08231000000000000000000000000b4c79dab8f259c7aee6e5b2aa729821864227e84f000000000000000000000000000000000000000000000000000000000000011&codeType=Mnemonic&code='qfunction%20approve%7Baddress%20_spj%2C%20uint256%20_value%7D%20public%20returns%20%7Bbool%20success%7Dzqkeccack256%7Bmsg.sj%20.%20spj%7D%20%3D%20valuezhERXMw04~2Z40XSHA3KVzzSWAP1zSw24~0Z0VhERN32Q8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925K0XLOG3z'~N1Qz%5CnyhDATAwSTOREK0~q%2F%2F%20jenderhzCALLZ0yCOPYz~X~00zV4yLOADQ%200xNzPUSHKz~2%01KNQVXZhjqwyz~_
    return  
      // get the allowance key - hash(msg.sender . _spender)
      hex"5b"                   // JUMPDEST
      hex"33"                   // CALLER
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE -> Save the caller in memory
      hex"60" hex"20"           // PUSH1 0x20 -> data len (32 bytes)
      hex"60" hex"04"           // PUSH1 0x04 -> offset (function sig is 4 bytes)
      hex"60" hex"20"           // PUSH1 0x20 -> memptr
      hex"37"                   // CALLDATACOPY -> save _spender in memory
      hex"60" hex"40"           // PUSH1 0x40 -> data len (64 bytes -> msg.sender + _spender)     
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"20"                   // SHA3 -> get the allowance key 

      // store the allowance
      hex"60" hex"24"           // PUSH1 0x24 -> get the _value
      hex"35"                   // CALLDATALOAD
      hex"90"                   // SWAP1 -> [value, key] -> [key, value]
      hex"55"                   // SSTORE -> hash(msg.sender . _spender) -> _value

      // fire the Allowance event
      hex"60" hex"20"           // PUSH1 0x20 -> data len (32 bytes)
      hex"60" hex"24"           // PUSH1 0x24 -> offset (function sig 4 bytes + _spender 32 bytes)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"37"                   // CALLDATACOPY -> save _amount in memory
      hex"60" hex"04"           // PUSH1 0x04 -> offset (function sig 4 bytes)
      hex"35"                   // CALLDATALOAD -> get the _spender
      hex"33"                   // CALLER
      hex"7f" hex"8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925" // PUSH32 allowanceEventSignature 
      hex"60" hex"20"           // PUSH1 0x20 -> data len (32 bytes)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"a3"                   // LOG3 -> fire Allowance event

      // return true
      hex"60" hex"01"           // PUSH1 0x01 -> true
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE -> store true 
      hex"60" hex"20"           // PUSH1 0x20 -> data len
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"f3"                   // RETURN
    ;
  }

  function _allowance() internal pure returns (bytes memory) {
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    // https://www.evm.codes/playground?unit=Wei&callData=0x70a08231000000000000000000000000b4c79dab8f259c7aee6e5b2aa729821864227e84000000000000000000000000000000000000000000000000000000000000beef&codeType=Mnemonic&code='qpprovJK%2C%20X_valueZjbool%20successGVkeccack256%7Bmsg.sh%20.%20KQ%3D%20valuezzqllowancJowner%2C%20yKZ%20viewjXremainingG~40~04WCALLDATACOPYz~40WSHA3zzSLOADzWMSTOREz~20WRETURNzz'~zPUSH1%200xz%5CnyaddresI_qVfunction%20aj%20returnI%7BhenderZQpublicXuint256%20W~00zV%2F%2F%20Q%7D%20KsphJe%7ByIs%20G%7Dz%01GIJKQVWXZhjqyz~_
    return
      hex"5b"                   // JUMPDEST
      hex"60" hex"40"           // PUSH1 0x40 -> data len (64 bytes)
      hex"60" hex"04"           // PUSH1 0x04 -> offset (function sig 4 bytes)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"37"                   // CALLDATACOPY -> store _owner and _spender in memory

      hex"60" hex"40"           // PUSH1 0x40 -> data len (64 bytes)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"20"                   // SHA3 -> get the key for the allowance

      hex"54"                   // SLOAD -> get the allowance

      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE -> save the allowance in memory
      hex"60" hex"20"           // PUSH1 0x20 -> data len (32 bytes)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"f3"                   // RETURN
    ;
  }

  function _transferFrom() internal pure returns (bytes memory) {
    // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    // https://www.evm.codes/playground?unit=Wei&callData=0x23b872dd000000000000000000000000000000000000000000000000000000000000beef000000000000000000000000000000000000000000000000000000000000dead0000000000000000000000000000000000000000000000000000000000000fff&codeType=Mnemonic&code='YSETUP%20%7Bnot%20included%20in%22contract%7DzYgive%20_from%20balance%260000fff%20coinsVZZZZZabcdVZZZZZbeefzS*zYset%20approvalX%20to%26000000fffVZZZZZbeef~00zM*%3BSTORE)VabcdefzSWAP1zS*YSETUP%20%5E%5EzzzYtransferFrom%7B%3Afrom%25%3Ato%25uint256%20_value%7D%20public%20returns%20%7Bbool%20success%7D~0y(~4yzzYifKgt%20!%2BzGT~00%23%3C%23herezzYor%20ifKgt-X~0y~00zM*z%3B*)(~4yzGTzzYjumpi%20revert~12%20Yjump%20%3CzzYif-X%20eq%26fffff)(VNNNNNNNNzEQ~02zJUMPI%20Yskip%22sub%20from%20the-zYjumpizzYelse-X%24~4yz)(zSUB)zS*zY!%2B%24zJUMPDEST%20Yskip%20to%20here%20if-%20%3D%3D%20max%20int~4yz~0y(zSUB~0yzS*zY!to%5D%20addKsstore~4yz~2y(zADD~2yzS*zYlog%22Transfer%20%7Bfrom%25to%25amount%7D%20event~4yz~00%20zM*~2yz~0yzVddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efz~20~00zLOG3zzzYreturn%20truez'~zPUSH1%26z%5Cny4zCALLDATALOADZ000000000000Y%2F%2F%20X%5B_%2B%5Bmsg.sender%5DVzPUSH32%26NffffffffK%20_value%20-%20allowance*STOREz)~40~00zSHA3(zSLOADz!balanceOf%5B_%22%20the%20%23%20Yrevert%20%24%20subKsstore%25%2C%20%26%200x%2Bfrom%5D%3Aaddress%20_%3BCALLER~20zM%3CdestzJUMPI%01%3C%3B%3A%2B%26%25%24%23%22!()*-KNVXYZyz~_
    return
      // 13 bytes
      hex"5b"                   // JUMPDEST
      // Check balanceOf[_from] > _value
      hex"60" hex"04"           // PUSH1 0x04 -> offset for _from (sig 4 bytes)
      hex"35"                   // CALLDATALOAD -> get _from
      hex"54"                   // SLOAD -> get _from balance

      hex"60" hex"44"           // PUSH1 0x44 -> offset for _value (sig 4 bytes, _from 32 bytes, _to 32 bytes)
      hex"35"                   // CALLDATALOAD -> get _value
      hex"11"                   // GT -> check if _value > balanceOf[_from]
      hex"61" hex"0069"         // PUSH2 0x0069 -> destination of revert helper
      hex"57"                   // JUMPI -> if not enough balance then revert

      // Check allowance[_from][msg.sender] > _value (29 bytes)
      hex"60" hex"04"           // PUSH 0x04 -> offset for _from
      hex"35"                   // CALLDATALOAD -> get _from
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE -> store the cller

      hex"33"                   // CALLER
      hex"60" hex"20"           // PUSH1 0x20 -> memptr
      hex"52"                   // MSTORE -> store the caller

      hex"60" hex"40"           // PUSH1 0x40 -> 64 byte data len
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"20"                   // SHA3
      hex"54"                   // SLOAD -> get allowance[_from][msg.sender]

      hex"60" hex"44"           // PUSH1 0x44 -> offset for _value
      hex"35"                   // CALLDATALOAD -> get _value
      hex"11"                   // GT
      hex"61" hex"0069"         // PUSH2 0x0069 -> destination of revert helper
      hex"57"                   // JUMPI -> if not enough allowance then revert

      hex"60" hex"40"           // PUSH1 0x40 -> 64 byte data len
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"20"                   // SHA3
      hex"54"                   // SLOAD -> get allowance[_from][msg.sender]

      // Check if allowance == maxValue (38 bytes)
      hex"7f" hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" // PUSH32 maxValue
      hex"14"                   // EQ -> check if allowance == maxValue

      // !!!!!!!!!!!!!!!!!!!!!!! //
      // !!!!!! IMPORTANT !!!!!! //
      // THIS JUMPDEST MUST BE SET BY TAKING THE transferFrom OFFSET and adding 98 bytes!!
      hex"61" hex"01CC"         // PUSH2 0x01CC -> jumpdest to skip subbing from allowance
      // !!!!!! IMPORTANT !!!!!! //
      // !!!!!!!!!!!!!!!!!!!!!!! //
      
      hex"57"                   // JUMPI

      // Subtract _value from allowance if it's not maxValue already (16 bytes)
      hex"60" hex"44"           // PUSH1 0x44 -> offset for _value
      hex"35"                   // CALLDATALOAD -> get _value

      hex"60" hex"40"           // PUSH1 0x40 -> 64 byte data len
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"20"                   // SHA3
      hex"54"                   // SLOAD -> get allowance[_from][msg.sender]

      hex"03"                   // SUB -> subtract _value from allowance[from][msg.sender]

      hex"60" hex"40"           // PUSH1 0x40 -> 64 byte data len
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"20"                   // SHA3 -> get key(allowance[from][msg.sender])
      hex"55"                   // SSTORE -> update the allowance
      
      // Subtract _value from balanceOf[_from] (13 bytes) +97 bytes from JUMPDEST^^
      hex"5b"                   // JUMPDEST
      hex"60" hex"44"           // PUSH1 0x44 -> offset for _value
      hex"35"                   // CALLDATALOAD -> get _value

      hex"60" hex"04"           // PUSH1 0x04 -> offset for _from (sig 4 bytes)
      hex"35"                   // CALLDATALOAD -> get _from
      hex"54"                   // SLOAD -> get _from balance

      hex"03"                   // SUB -> subtract _value from balanceOf[from]
      hex"60" hex"04"           // PUSH1 0x04 -> offset for _from (sig 4 bytes)
      hex"35"                   // CALLDATALOAD -> get _from
      hex"55"                   // SSTORE -> update balanceOf[_from]

      // Add _value to balanceOf[_to] (12 bytes)
      hex"60" hex"44"           // PUSH1 0x44 -> offset for _value
      hex"35"                   // CALLDATALOAD -> get _value

      hex"60" hex"24"           // PUSH1 0x24 -> offset for _to
      hex"35"                   // CALLDATALOAD -> get _to
      hex"54"                   // SLOAD -> get _from balance

      hex"01"                   // ADD -> add _value to balanceOf[_from]
      hex"60" hex"24"           // PUSH1 0x24 -> offset for _to
      hex"35"                   // CALLDATALOAD -> get _to
      hex"55"                   // SSTORE -> update balanceOf[_to]

      hex"60" hex"44"           // PUSH1 0x44 -> 0x44 offset (4 byte, 32 byte, 32 byte) get the _value
      hex"35"                   // CALLDATALOAD -> get the _value
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTSORE -> store the _value in memory
      hex"60" hex"24"           // PUSH1 0x24 -> offset (4 byte, 32 byte) get the _to
      hex"35"                   // CALLDATALOAD -> get the _to
      hex"60" hex"04"           // PUSH1 0x04 -> offset (4 byte) get the _from
      hex"35"
      hex"7f" hex"ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" // PUSH32 keccak256(Transfer)
      hex"60" hex"20"           // PUSH1 0x20 -> 32 byte len (for _value)
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"a3"                   // LOG3 -> fire the Transfer event

      // return true (10 bytes)
      hex"60" hex"01"           // PUSH1 0x01 -> true
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE -> store true 
      hex"60" hex"20"           // PUSH1 0x20 -> data len
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"f3"                   // RETURN
    ;
  }

  function __decimals() internal view returns (bytes memory) {
    // function decimals() public view returns (uint8)
    return abi.encodePacked(
        hex"5b"                 // JUMPDEST
        hex"7f", _decimals,     // PUSH32 decimals
        hex"60" hex"00"         // PUSH1 0x00 -> memptr
        hex"52"                 // MSTORE
        hex"60" hex"20"         // PUSH1 0x20 -> data len (32 bytes)
        hex"60" hex"00"         // PUSH1 0x00 -> memptr
        hex"f3"                 // RETURN
    );
  }

  function __name() internal view returns (bytes memory) {
    return abi.encodePacked(
      hex"5b"                   // JUMPDEST

      // Not sure what this does but apparently you need 0x20 in the return value
      // to match the string encoding spec
      hex"60" hex"20"           // PUSH1 0x20
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE

      // Store the length of the name
      hex"7f", bytes(_name).length, // PUSH1 nameLen -> length of the name
      hex"60" hex"20"           // PUSH1 0x20 -> memptr
      hex"52",                  // MSTORE

      // Store the name
      uint8(0x5f + bytes(_name).length), bytes(_name), // PUSH name
      hex"7f", (32 - bytes(_name).length) * 8, // PUSH1 shift amount
      hex"1b"                   // SHL -> shift the name to pad zeroes at the end
      hex"60" hex"40"           // PUSH1 0x20 -> memptr
      hex"52"                   // MSTORE

      hex"60" hex"60"           // PUSH1 0x40 -> data len 64 bytes
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"f3"                   // RETURN
    );
  }

  function __symbol() internal view returns (bytes memory) {
    return abi.encodePacked(
      hex"5b"                   // JUMPDEST

      // Not sure what this does but apparently you need 0x20 in the return value
      // to match the string encoding spec
      hex"60" hex"20"           // PUSH1 0x20
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"52"                   // MSTORE

      // Store the length of the name
      hex"7f", bytes(_symbol).length, // PUSH1 nameLen -> length of the name
      hex"60" hex"20"           // PUSH1 0x20 -> memptr
      hex"52",                  // MSTORE

      // Store the name
      uint8(0x5f + bytes(_symbol).length), bytes(_symbol), // PUSH name
      hex"7f", (32 - bytes(_symbol).length) * 8, // PUSH1 shift amount
      hex"1b"                   // SHL -> shift the name to pad zeroes at the end
      hex"60" hex"40"           // PUSH1 0x20 -> memptr
      hex"52"                   // MSTORE

      hex"60" hex"60"           // PUSH1 0x40 -> data len 64 bytes
      hex"60" hex"00"           // PUSH1 0x00 -> memptr
      hex"f3"                   // RETURN
    );
  }
}
