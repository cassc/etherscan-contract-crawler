// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IERC20Decimals is IERC20 {
  function decimals() external view returns (uint8);
}

/**
 * @title WCIBCBSwap
 * @dev Swap WCI for BCB
 */
contract WCIBCBSwap is Ownable {
  using SafeERC20 for IERC20Decimals;

  IERC20Decimals private wciV1;
  IERC20Decimals private wciV2;

  mapping(address => bool) public swapped;

  constructor(address _v1, address _v2) {
    wciV1 = IERC20Decimals(_v1);
    wciV2 = IERC20Decimals(_v2);
  }

  function swap() external {
    require(!swapped[msg.sender], 'SWAP1: already swapped');
    swapped[msg.sender] = true;

    uint256 _v1Bal = wciV1.balanceOf(msg.sender);
    require(_v1Bal > 0, 'SWAP2: no V1 tokens');
    uint256 _v2Amount = (_v1Bal * 10**wciV2.decimals()) / 10**wciV1.decimals();
    require(wciV2.balanceOf(owner()) >= _v2Amount, 'SWAP3: V2 liquidity');
    wciV1.safeTransferFrom(msg.sender, address(this), _v1Bal);
    wciV2.safeTransferFrom(owner(), msg.sender, _v2Amount);
  }

  function v1() external view returns (address) {
    return address(wciV1);
  }

  function v2() external view returns (address) {
    return address(wciV2);
  }

  function setSwapped(address _wallet, bool _swapped) external onlyOwner {
    swapped[_wallet] = _swapped;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20Decimals _token = IERC20Decimals(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.safeTransfer(owner(), _amount);
  }
}