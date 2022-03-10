// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20User {
  IERC20Metadata token;

  constructor(IERC20Metadata _token) {
    token = _token;
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    returns (bool)
  {
    return token.approve(spender, amount);
  }

  function transfer(address to, uint256 amount) public virtual returns (bool) {
    return token.transfer(to, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual returns (bool) {
    return token.transferFrom(from, to, amount);
  }
}
