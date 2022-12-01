// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol';
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import './interfaces/IUnoAccessManager.sol'; 
import './interfaces/IUnoAssetRouter.sol';

contract UnoFarmFactory{
    /**
     * @dev Contract Variables:
     * accessManager - Role manager contract.
     * assetRouter -  UnoAssetRouter contract. Is given permission to call functions on farms. 
     
     * farmBeacon - Farm contract implementation.
     * Farms - links {lpPools} to the deployed Farm contract.
     * lpPools - list of pools that have corresponding deployed Farm contract.
     */
    IUnoAccessManager public accessManager;
    address public immutable assetRouter;

    address public immutable farmBeacon;
    mapping(address => address) public Farms;
    address[] public pools;

    event FarmDeployed(address indexed farmAddress);

    // ============ Methods ============

    constructor (address _implementation, address _accessManager, address _assetRouter) {
        require (_implementation != address(0), 'BAD_IMPLEMENTATION');
        require (_accessManager != address(0), 'BAD_ACCESS_MANAGER');
        require (_assetRouter != address(0), 'BAD_ASSET_ROUTER');

        farmBeacon = address(new UpgradeableBeacon(_implementation));
        accessManager = IUnoAccessManager(_accessManager);
        assetRouter = _assetRouter;
        IUnoAssetRouter(_assetRouter).initialize(_accessManager, address(this)); 
    }

    /**
     * @dev Creates new farm.
     */
    function createFarm(address pool) external returns (address) {
        require(Farms[pool] == address(0), 'FARM_EXISTS');
        Farms[pool] = _createFarm(pool);
        pools.push(pool);
        return Farms[pool];
    }

    /**
     * @dev Upgrades all farms deployed by this factory using beacon proxy. Only available to the admin.
     */
    function upgradeFarms(address newImplementation) external {
        require(accessManager.hasRole(accessManager.ADMIN_ROLE(), msg.sender), 'CALLER_NOT_ADMIN');
        UpgradeableBeacon(farmBeacon).upgradeTo(newImplementation);
    }

    /**
     * @dev Deploys new Farm contract and calls initialize on it. Emits {FarmDeployed} event.
     */
    function _createFarm(address _pool) internal returns (address) {
        BeaconProxy proxy = new BeaconProxy(
            farmBeacon,
            abi.encodeWithSelector(
                bytes4(keccak256('initialize(address,address)')),
                _pool,
                assetRouter
            )
        );
        emit FarmDeployed(address(proxy));
        return address(proxy);
    }

    function poolLength() external view returns (uint256) {
        return pools.length;
    }
}