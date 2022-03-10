// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../ERC20Deployer.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20User } from "./utils/ERC20User.sol";
import { DSTestPlus } from "./utils/DSTestPlus.sol";

// include this for function sigs
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface CheatCodes {
  function getCode(string calldata) external returns (bytes memory);

  function expectEmit(
    bool,
    bool,
    bool,
    bool
  ) external;
}

contract ERC20Test is DSTestPlus {
  CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
  IERC20Metadata token;
  ERC20Deployer deployer;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function setUp() public {
    deployer = new ERC20Deployer();
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 1e18, address(this))
    );
  }

  function testTotalSupply() public {
    // emit log_address(address(token));

    token.totalSupply();
    // emit log_bytes(bytes(result));
    // emit log_string(result);
    assertEq(token.totalSupply(), 1e18);
  }

  function testBalanceOf() public {
    assertEq(token.balanceOf(address(this)), 1e18);
  }

  function testTransfer() public {
    assertTrue(token.transfer(address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.balanceOf(address(this)), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testPartialTransfer() public {
    assertTrue(token.transfer(address(0xBEEF), 100));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.balanceOf(address(this)), 1e18 - 100);
    assertEq(token.balanceOf(address(0xBEEF)), 100);
  }

  function testFailTransferInsufficientBalance() public {
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 0.9e18, address(this))
    );

    token.transfer(address(0xBEEF), 1e18);
  }

  function testTransfer(address to, uint256 amount) public {
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, amount, address(this))
    );

    assertTrue(token.transfer(to, amount));
    assertEq(token.totalSupply(), amount);

    if (address(this) == to) {
      assertEq(token.balanceOf(address(this)), amount);
    } else {
      assertEq(token.balanceOf(address(this)), 0);
      assertEq(token.balanceOf(to), amount);
    }
  }

  function testTransferEmitsTransferEvent(address to, uint256 amount) public {
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, amount, address(this))
    );

    cheats.expectEmit(true, true, false, true);

    emit Transfer(address(this), to, amount);

    token.transfer(to, amount);
  }

  function testApprove() public {
    assertTrue(token.approve(address(0xBEEF), 100));
  }

  function testApprove(address to, uint256 amount) public {
    assertTrue(token.approve(to, amount));
    assertEq(token.allowance(address(this), to), amount);
  }

  function testApproveEmitsApproveEvent(address spender, uint256 value) public {
    cheats.expectEmit(true, true, false, true);

    emit Approval(address(this), spender, value);

    token.approve(spender, value);
  }

  function testAllowance(address spender, uint256 value) public {
    token.approve(spender, value);
    assertEq(token.allowance(address(this), spender), value);
  }

  function testTransferFromEmitsTransferEvent() public {
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 1e18, address(this))
    );
    ERC20User from = new ERC20User(token);

    token.transfer(address(from), 1e18);
    from.approve(address(this), 1e18);

    cheats.expectEmit(true, true, false, true);

    emit Transfer(address(from), address(0xBEEF), 1e18);

    token.transferFrom(address(from), address(0xBEEF), 1e18);
  }

  function testTransferFrom() public {
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 1e18, address(this))
    );

    ERC20User from = new ERC20User(token);

    token.transfer(address(from), 1e18);

    from.approve(address(this), 1e18);

    assertTrue(token.transferFrom(address(from), address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.allowance(address(from), address(this)), 0);

    assertEq(token.balanceOf(address(from)), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testInfiniteApproveTransferFrom() public {
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 1e18, address(this))
    );

    ERC20User from = new ERC20User(token);

    token.transfer(address(from), 1e18);

    from.approve(address(this), type(uint256).max);

    assertTrue(token.transferFrom(address(from), address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.allowance(address(from), address(this)), type(uint256).max);

    assertEq(token.balanceOf(address(from)), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testFailTransferFromInsufficientAllowance() public {
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 1e18, address(this))
    );

    ERC20User from = new ERC20User(token);

    token.transfer(address(from), 1e18);
    from.approve(address(this), 0.9e18);
    token.transferFrom(address(from), address(0xBEEF), 1e18);
  }

  function testFailTransferFromInsufficientBalance() public {
    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 1e18, address(this))
    );

    ERC20User from = new ERC20User(token);

    token.transfer(address(from), 0.9e18);
    from.approve(address(this), 1e18);
    token.transferFrom(address(from), address(0xBEEF), 1e18);
  }

  function testFailTransferFromInsufficientAllowance(
    address to,
    uint256 approval,
    uint256 amount
  ) public {
    amount = bound(amount, approval + 1, type(uint256).max);

    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, amount, address(this))
    );

    ERC20User from = new ERC20User(token);

    token.transfer(address(from), amount);
    from.approve(address(this), approval);
    token.transferFrom(address(from), to, amount);
  }

  function testTransferFrom(
    address to,
    uint256 approval,
    uint256 amount
  ) public {
    amount = bound(amount, 0, approval);

    token = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, amount, address(this))
    );

    ERC20User from = new ERC20User(token);

    token.transfer(address(from), amount);

    from.approve(address(this), approval);

    assertTrue(token.transferFrom(address(from), to, amount));
    assertEq(token.totalSupply(), amount);

    uint256 app = address(from) == address(this) ||
      approval == type(uint256).max
      ? approval
      : approval - amount;
    assertEq(token.allowance(address(from), address(this)), app);

    if (address(from) == to) {
      assertEq(token.balanceOf(address(from)), amount);
    } else {
      assertEq(token.balanceOf(address(from)), 0);
      assertEq(token.balanceOf(to), amount);
    }
  }

  function testDecimals() public {
    assertEq(token.decimals(), 18);
  }

  function testName() public {
    assertEq(token.name(), "Token");
  }

  function testSymbol() public {
    assertEq(token.symbol(), "TEST");
  }
}
