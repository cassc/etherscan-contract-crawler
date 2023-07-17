// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.8.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProvider } from "./IProvider.sol";

interface LQTYInterface {

}

contract LQTYHelpers {

  function initializeTrouve() internal {
    //TODO function
  }

}

contract ProviderLQTY is IProvider, LQTYHelpers {

  using SafeMath for uint256;
  using UniERC20 for IERC20;

  function deposit(address collateralAsset, uint256 collateralAmount) external override payable{
    //TODO
  }

  function borrow(address borrowAsset, uint256 borrowAmount) external override payable {
    //TODO
  }

  function withdraw(address collateralAsset, uint256 collateralAmount) external override payable {
    //TODO
  }

  function payback(address borrowAsset, uint256 borrowAmount) external override payable {
    //TODO
  }

  function getBorrowRateFor(address asset) external view override returns(uint256){
    //TODO
    return 0;

  }
  function getBorrowBalance(address _asset) external view override returns(uint256) {
    //TODO
    return 0;
  }

  function getDepositBalance(address _asset) external view override returns(uint256){
    //TODO
    return 0;
  }

}