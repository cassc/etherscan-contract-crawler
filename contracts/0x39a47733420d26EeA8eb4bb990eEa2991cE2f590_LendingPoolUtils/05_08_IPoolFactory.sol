// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

import "../utils/Types.sol";

interface IPoolFactory {
    
    event DeployPool(
        address poolAddress,
        address deployer,
        address implementation,
        FactoryParameters factorySettings,
        GeneralPoolSettings poolSettings
    );

    error InvalidPauseTime();
    error OperationsPaused();
    error LendTokenNotSupported();
    error ColTokenNotSupported();
    error InvalidTokenPair();
    error LendRatio0();
    error InvalidExpiry();
    error ImplementationNotWhitelisted();
    error StrategyNotWhitelisted();
    error TokenNotSupportedWithStrategy();
    error ZeroAddress();
    error InvalidParameters();
    error NotGranted();
    error NotOwner();
    error NotAuthorized();



    function pools(address _pool) external view returns (bool);

    function treasury() external view returns (address);

    function protocolFee() external view returns (uint48);

    function repaymentsPaused() external view returns (bool);

    function isPoolPaused(address _pool, address _lendTokenAddr, address _colTokenAddr) external view returns (bool);

    function allowUpgrade() external view returns (bool);

    function implementations(PoolType _type) external view returns (address);

}