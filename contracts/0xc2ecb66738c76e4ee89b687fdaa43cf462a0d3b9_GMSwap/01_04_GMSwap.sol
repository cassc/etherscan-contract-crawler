// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Decimals is IERC20 {
  function decimals() external view returns (uint8);
}

/**
 * @title GMSwap
 * @dev Swap GMv1 for GMv2
 */
contract GMSwap is Ownable {
  IERC20Decimals private gmV1;
  IERC20Decimals private gmV2;

  mapping(address => bool) public swapped;

  constructor(address _v1, address _v2) {
    gmV1 = IERC20Decimals(_v1);
    gmV2 = IERC20Decimals(_v2);
  }

  function swap() external {
    require(!swapped[msg.sender], 'already swapped V1 for V2');
    swapped[msg.sender] = true;

    uint256 _v1Bal = gmV1.balanceOf(msg.sender);
    require(_v1Bal > 0, 'you do not have any V1 tokens');
    uint256 _v2Amount = (_v1Bal * 10**gmV2.decimals()) / 10**gmV1.decimals();
    require(
      gmV2.balanceOf(address(this)) >= _v2Amount,
      'not enough V2 liquidity to complete swap'
    );
    gmV1.transferFrom(msg.sender, address(this), _v1Bal);
    gmV2.transfer(msg.sender, _v2Amount);
  }

  function v1() external view returns (address) {
    return address(gmV1);
  }

  function v2() external view returns (address) {
    return address(gmV2);
  }

  function setSwapped(address _wallet, bool _swapped) external onlyOwner {
    swapped[_wallet] = _swapped;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }
}