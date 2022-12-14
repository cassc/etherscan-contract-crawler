// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface Isettings {
    function networkFee(uint256 chainId) external view returns (uint256);

    function minValidations() external view returns (uint256);

    function isNetworkSupportedChain(uint256 chainID)
        external
        view
        returns (bool);

    function feeRemitance() external view returns (address);

    function railRegistrationFee() external view returns (uint256);

    function railOwnerFeeShare() external view returns (uint256);

    function onlyOwnableRail() external view returns (bool);

    function updatableAssetState() external view returns (bool);

    function minWithdrawableFee() external view returns (uint256);

    function brgToken() external view returns (address);

    function getNetworkSupportedChains()
        external
        view
        returns (uint256[] memory);

    function baseFeePercentage() external view returns (uint256);

    function networkGas(uint256 chainID) external view returns (uint256);

    function gasBank() external view returns (address);

    function baseFeeEnable() external view returns (bool);

    function maxFeeThreshold() external view returns (uint256);

    function approvedToAdd(address token, address user)
        external
        view
        returns (bool);
}