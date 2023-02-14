//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IComputationalView {

    struct AssetInfo {
        address token;
        uint balance;
        uint usdValue;
        uint usdPrice;
    }

    function convertGasToFeeToken(address feeToken, uint gasCost) external view returns (uint);
    function estimateRedemption(address feeToken, uint dxblAmount) external view returns(uint);
    function feeTokenPriceUSD(address feeToken) external view returns (uint);
    function aumUSD() external view returns(uint);
    function currentNavUSD() external view returns(uint);
    function assets() external view returns (AssetInfo[] memory);
    function currentMintRateUSD() external view returns (uint);
    function computeVolumeUSD(address feeToken, uint amount) external view returns(uint);

}