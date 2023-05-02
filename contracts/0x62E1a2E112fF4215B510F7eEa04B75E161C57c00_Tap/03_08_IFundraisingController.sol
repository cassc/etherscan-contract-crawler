pragma solidity ^0.6.0;


abstract contract IFundraisingController {
    function openTrading() external virtual;
    function updateTappedAmount(address _token) external virtual;
    function collateralsToBeClaimed(address _collateral) public view virtual returns (uint256);
    function balanceOf(address _who, address _token) public view virtual returns (uint256);
}