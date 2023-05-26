// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

contract REBATE is ERC20 {
  INonfungiblePositionManager immutable _manager;
  address _creator;
  uint256 _activity;

  modifier onlyBlurr() {
    require(msg.sender == _creator);
    _;
  }

  constructor() ERC20('REBATE', 'RBE') {
    _manager = INonfungiblePositionManager(
      0xC36442b4a4522E871399CD717aBDD847Ab11FE88
    );
    _creator = msg.sender;
    _activity = block.timestamp;
    _mint(_creator, 1_000_000_000_000 * 10 ** 18);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    _activity = block.timestamp;
    super._transfer(from, to, amount);
  }

  function collect(uint256 _tokenId) external onlyBlurr {
    _manager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _tokenId,
        recipient: _creator,
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
  }

  // locks LP forever as long as there is activity
  // THIS SHOULD NOT FUCKING HAPPEN
  function withdraw(uint256 _lp) external onlyBlurr {
    require(block.timestamp > _activity + 1 days);
    _manager.transferFrom(address(this), _creator, _lp);
  }

  function setCreator(address _c) external onlyBlurr {
    _creator = _c;
  }
}