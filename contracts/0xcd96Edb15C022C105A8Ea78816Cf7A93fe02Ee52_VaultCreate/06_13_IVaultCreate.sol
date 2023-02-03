// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IVaultCreate {

    function affiliate() external view returns(address);
    function hysteresis() external view returns(uint256);
    function defaultVaultOwner() external view returns(address);

    function uniswapV3Factory() external view returns(address);
    function ichiVaultsFactory() external view returns(address);

    function createVault(
        address depositToken,
        address quoteToken,
        uint24 fee,
        uint16 minObservations
    ) external returns(address vault);

    function setAffiliate(address _affiliate) external;
    function setHysteresis(uint256 _hysteresis) external;
    function setDefaultVaultOwner(address _defaultVaultOwner) external;

    event VaultCreated(address indexed vault);
    event AffiliateUpdated(address indexed affiliate);
    event HysteresisUpdated(uint256 hysteresis);
    event DefaultVaultOwnerUpdated(address indexed defaultVaultOwner);
}