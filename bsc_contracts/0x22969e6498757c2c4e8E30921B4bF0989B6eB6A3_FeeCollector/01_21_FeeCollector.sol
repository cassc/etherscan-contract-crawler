// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;
pragma abicoder v2;

import "../IndexToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "pancake-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import "../lib/RoutePlanner.sol";

contract FeeCollector is AutomationCompatible {
  using SafeERC20 for IERC20;

  event FeeCollected(address feeReceiver, uint256 fee);

  mapping(address => uint256) lastUpkeep;
  mapping(address => uint256) interval;
  mapping(address => uint256) feeSize; // out of 1_000_000
  mapping(address => address) feeToken;

  IPancakeRouter02 immutable router;

  constructor(IPancakeRouter02 router_) {
    router = router_;
  }

  function register(address token, uint256 interval_, uint256 feeSize_, address feeToken_) external {
    require(msg.sender == IIndexToken(token).getOwner(), "not token owner");
    interval[token] = interval_;
    feeSize[token] = feeSize_;
    feeToken[token] = feeToken_;
  }

  function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
    address token = abi.decode(checkData, (address));
    if (interval[token] == 0) {
      // token not registered
      return (false, "");
    }

    return (block.timestamp - lastUpkeep[token] >= interval[token], abi.encode(token));
  }

  function performUpkeep(bytes calldata performData) external {
    address token = abi.decode(performData, (address));
    require(interval[token] > 0, "token not registered");
    require(feeSize[token] > 0, "token not registered");
    require(block.timestamp - lastUpkeep[token] >= interval[token], "too early");
    lastUpkeep[token] = block.timestamp;
    _collectFee(IIndexToken(token));
  }

  function _collectFee(IIndexToken token) internal {
    uint256 feeSum = 0;
    address feeTok = feeToken[address(token)];
    IIndexToken.Asset[] memory assets = token.getAssets();
    for (uint256 i = 0; i < assets.length; i++) {
      IERC20 asset = IERC20(assets[i].assetToken);
      uint256 assetBalance = asset.balanceOf(address(token));
      uint256 feeFromAsset = assetBalance * feeSize[address(token)] / 1_000_000;
      if (address(asset) == feeTok) {
        feeSum += feeFromAsset;
      } else {
        (uint256 feeSumFromAsset,) = RoutePlanner.findBestRouteExactIn(router, address(asset), feeTok, feeFromAsset);
        feeSum += feeSumFromAsset;
      }
    }

    address feeReceiver = token.getFeeReceiver();
    token.transferAsset(feeTok, feeReceiver, feeSum);
    
    emit FeeCollected(feeReceiver, feeSum);
  }
}