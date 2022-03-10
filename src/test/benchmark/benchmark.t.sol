// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { DSTestPlus } from "../utils/DSTestPlus.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20User } from "../utils/ERC20User.sol";
import "../../ERC20Deployer.sol";
import { ERC20 as SolmateERC20 } from "solmate/tokens/ERC20.sol";
import { ERC20 as OpenZeppelinERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20User } from "../utils/ERC20User.sol";

contract MockSolmateERC20 is SolmateERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) SolmateERC20(_name, _symbol, _decimals) {}

  function mint(address to, uint256 value) public virtual {
    _mint(to, value);
  }

  function burn(address from, uint256 value) public virtual {
    _burn(from, value);
  }
}

contract MockOpenZeppelinERC20 is OpenZeppelinERC20 {
  constructor(string memory _name, string memory _symbol)
    OpenZeppelinERC20(_name, _symbol)
  {}

  function mint(address to, uint256 value) public virtual {
    _mint(to, value);
  }

  function burn(address from, uint256 value) public virtual {
    _burn(from, value);
  }
}

contract BenchmarkMax is DSTestPlus {
  ERC20Deployer deployer;
  IERC20Metadata solwaifuToken;
  ERC20User solwaifuUser;

  MockSolmateERC20 solmateToken;
  ERC20User solmateUser;

  MockOpenZeppelinERC20 openZeppelinToken;
  ERC20User openZeppelinUser;

  function setUp() public {
    deployer = new ERC20Deployer();
    solwaifuToken = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 1e18, address(this))
    );
    solwaifuUser = new ERC20User(IERC20Metadata(address(solwaifuToken)));
    solwaifuToken.transfer(address(solwaifuUser), 500);
    solwaifuUser.approve(address(this), type(uint256).max);

    solmateToken = new MockSolmateERC20("Token", "TEST", 18);
    solmateToken.mint(address(this), 1e18);
    solmateUser = new ERC20User(IERC20Metadata(address(solmateToken)));
    solmateToken.transfer(address(solmateUser), 500);
    solmateUser.approve(address(this), type(uint256).max);

    openZeppelinToken = new MockOpenZeppelinERC20("Token", "TEST");
    openZeppelinToken.mint(address(this), 1e18);
    openZeppelinUser = new ERC20User(
      IERC20Metadata(address(openZeppelinToken))
    );
    openZeppelinToken.transfer(address(openZeppelinUser), 500);
    openZeppelinUser.approve(address(this), type(uint256).max);
  }

  function testTransfer() public {
    startMeasuringGas("openzeppelin: transfer (max)");
    openZeppelinToken.transfer(address(0xBEEF), 100);
    stopMeasuringGas();

    startMeasuringGas("solmate: transfer (max)");
    solmateToken.transfer(address(0xBEEF), 100);
    stopMeasuringGas();

    startMeasuringGas("solwaifu: transfer (max)");
    solwaifuToken.transfer(address(0xBEEF), 100);
    stopMeasuringGas();
  }

  function testTransferFrom() public {
    startMeasuringGas("openzeppelin: transferFrom (max)");
    openZeppelinToken.transferFrom(
      address(openZeppelinUser),
      address(0xBEEF),
      100
    );
    stopMeasuringGas();

    startMeasuringGas("solmate: transferFrom (max)");
    solmateToken.transferFrom(address(solmateUser), address(0xBEEF), 100);
    stopMeasuringGas();

    startMeasuringGas("solwaifu: transferFrom (max)");
    solwaifuToken.transferFrom(address(solwaifuUser), address(0xBEEF), 100);
    stopMeasuringGas();
  }

  function testApprove() public {
    startMeasuringGas("openzeppelin: approve");
    openZeppelinToken.approve(address(0xBEEF), type(uint256).max);
    stopMeasuringGas();

    startMeasuringGas("solmate: approve");
    solmateToken.approve(address(0xBEEF), type(uint256).max);
    stopMeasuringGas();

    startMeasuringGas("solwaifu: approve");
    solwaifuToken.approve(address(0xBEEF), type(uint256).max);
    stopMeasuringGas();
  }

  function testBalanceOf() public {
    startMeasuringGas("openzeppelin: balanceOf");
    openZeppelinToken.balanceOf(address(this));
    stopMeasuringGas();

    startMeasuringGas("solmate: balanceOf");
    solmateToken.balanceOf(address(this));
    stopMeasuringGas();

    startMeasuringGas("solwaifu: balanceOf");
    solwaifuToken.balanceOf(address(this));
    stopMeasuringGas();
  }

  function testAllowance() public {
    startMeasuringGas("openzeppelin: allowance");
    openZeppelinToken.allowance(address(openZeppelinUser), address(this));
    stopMeasuringGas();

    startMeasuringGas("solmate: allowance");
    solmateToken.allowance(address(solmateUser), address(this));
    stopMeasuringGas();

    startMeasuringGas("solwaifu: allowance");
    solwaifuToken.allowance(address(solwaifuUser), address(this));
    stopMeasuringGas();
  }

  function testTotalSupply() public {
    startMeasuringGas("openzeppelin: totalSupply");
    openZeppelinToken.totalSupply();
    stopMeasuringGas();

    startMeasuringGas("solmate: totalSupply");
    solmateToken.totalSupply();
    stopMeasuringGas();

    startMeasuringGas("solwaifu: totalSupply");
    solwaifuToken.totalSupply();
    stopMeasuringGas();
  }
}

contract BenchmarkMin is DSTestPlus {
  ERC20Deployer deployer;
  IERC20Metadata solwaifuToken;
  ERC20User solwaifuUser;

  MockSolmateERC20 solmateToken;
  ERC20User solmateUser;

  MockOpenZeppelinERC20 openZeppelinToken;
  ERC20User openZeppelinUser;

  function setUp() public {
    deployer = new ERC20Deployer();
    solwaifuToken = IERC20Metadata(
      deployer.deploy("Token", "TEST", 18, 1e18, address(this))
    );
    solwaifuToken.transfer(address(0xBEEF), 100);
    solwaifuUser = new ERC20User(IERC20Metadata(address(solwaifuToken)));
    solwaifuToken.transfer(address(solwaifuUser), 500);
    solwaifuUser.approve(address(this), type(uint256).max);

    solmateToken = new MockSolmateERC20("Token", "TEST", 18);
    solmateToken.mint(address(this), 1e18);
    solmateToken.transfer(address(0xBEEF), 100);
    solmateUser = new ERC20User(IERC20Metadata(address(solmateToken)));
    solmateToken.transfer(address(solmateUser), 500);
    solmateUser.approve(address(this), type(uint256).max);

    openZeppelinToken = new MockOpenZeppelinERC20("Token", "TEST");
    openZeppelinToken.mint(address(this), 1e18);
    openZeppelinToken.transfer(address(0xBEEF), 100);
    openZeppelinUser = new ERC20User(
      IERC20Metadata(address(openZeppelinToken))
    );
    openZeppelinToken.transfer(address(openZeppelinUser), 500);
    openZeppelinUser.approve(address(this), type(uint256).max);
  }

  function testTransfer() public {
    startMeasuringGas("openzeppelin: transfer (min)");
    openZeppelinToken.transfer(address(0xBEEF), 1e18 - 600);
    stopMeasuringGas();

    startMeasuringGas("solmate: transfer (min)");
    solmateToken.transfer(address(0xBEEF), 1e18 - 600);
    stopMeasuringGas();

    startMeasuringGas("solwaifu: transfer (min)");
    solwaifuToken.transfer(address(0xBEEF), 1e18 - 600);
    stopMeasuringGas();
  }

  function testTransferFrom() public {
    startMeasuringGas("openzeppelin: transferFrom (min)");
    openZeppelinToken.transferFrom(
      address(openZeppelinUser),
      address(this),
      500
    );
    stopMeasuringGas();

    startMeasuringGas("solmate: transferFrom (min)");
    solmateToken.transferFrom(address(solmateUser), address(this), 500);
    stopMeasuringGas();

    startMeasuringGas("solwaifu: transferFrom (min)");
    solwaifuToken.transferFrom(address(solwaifuUser), address(this), 500);
    stopMeasuringGas();
  }
}
