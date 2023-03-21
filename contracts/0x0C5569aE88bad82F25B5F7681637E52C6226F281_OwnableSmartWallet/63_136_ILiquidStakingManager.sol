pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ILiquidStakingManager {

    function stakehouse() external view returns (address);

    /// @param _dao address of the DAO
    /// @param _syndicateFactory address of the syndicate factory
    /// @param _smartWalletFactory address of the smart wallet factory
    /// @param _lpTokenFactory LP token factory address required for deployment of savETH vault
    /// @param _stakehouseTicker 3-5 character long name for the stakehouse to be deployed
    function init(
        address _dao,
        address _syndicateFactory,
        address _smartWalletFactory,
        address _lpTokenFactory,
        address _brand,
        address _savETHVaultDeployer,
        address _stakingFundsVaultDeployer,
        address _optionalGatekeeperDeployer,
        uint256 _optionalCommission,
        bool _deployOptionalGatekeeper,
        string calldata _stakehouseTicker
    ) external;

    /// @notice function to check valid BLS public key for LSD network
    /// @param _blsPublicKeyOfKnot BLS public key to check validity for
    /// @return true if BLS public key is a part of LSD network, false otherwise
    function isBLSPublicKeyPartOfLSDNetwork(bytes calldata _blsPublicKeyOfKnot) external view returns (bool);

    /// @notice function to check if BLS public key registered with the network or has been withdrawn before staking
    /// @param _blsPublicKeyOfKnot BLS public key to check validity for
    /// @return true if BLS public key is banned, false otherwise
    function isBLSPublicKeyBanned(bytes calldata _blsPublicKeyOfKnot) external view returns (bool);
}