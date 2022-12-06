//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;

interface IFeeDistributor {
    function buyFees() external view returns (uint, uint, uint);
    function sellFees() external view returns (uint, uint, uint);
    function liquidityReceiver() external view returns (address);
    function token() external view returns (address);
    function maxSellAmount() external view returns (uint);
    function isFeeExempt(address) external view returns (bool);

    function updateTokenOwner(address) external;
    function transferFee(bool) external payable;
}