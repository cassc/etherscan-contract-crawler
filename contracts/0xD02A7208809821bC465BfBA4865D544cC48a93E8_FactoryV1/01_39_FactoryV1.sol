// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./myNFT_V1.sol";
import "./Beacon.sol";

contract FactoryV1 is Initializable, OwnableUpgradeable {
    /// @notice emit when a new proxy is created
    event ProxyCreated(
        address proxyAddress,
        address owner,
        string name,
        string symbol,
        string contractUri,
        uint256 proxyIndex
    );

    using CountersUpgradeable for CountersUpgradeable.Counter;

    Beacon internal beacon;
    CountersUpgradeable.Counter internal proxyIdCounter;
    mapping(uint256 => address) internal proxies;

    // prettier-ignore
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev proxy initializer
     */
    function initialize(address implContract) external virtual initializer {
        beacon = new Beacon(implContract);
        __Ownable_init();
    }

    /// @notice Create nft proxy contract
    /// @param owner: the address that will be the owner of this contract
    /// @param name: nft contract name
    /// @param symbol: nft contract symbol
    /// @param contractURI: nft contract contractURI
    function createProxy(
        address owner,
        string memory name,
        string memory symbol,
        string memory contractURI
    ) external virtual {
        BeaconProxy proxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                myNFTV1.initialize.selector,
                owner,
                name,
                symbol,
                contractURI
            )
        );
        proxyIdCounter.increment();
        uint256 index = proxyIdCounter.current();
        proxies[index] = address(proxy);
        emit ProxyCreated(
            address(proxy),
            owner,
            name,
            symbol,
            contractURI,
            index
        );
    }

    /// @notice get the current implementation contract address
    function getImplementation() external view virtual returns (address) {
        return beacon.implementation();
    }

    /// @notice get the beacon contract address
    function getBeacon() external view virtual returns (address) {
        return address(beacon);
    }

    /// @notice get the beacon proxy contract address by index
    function getProxy(uint256 index) external view virtual returns (address) {
        return proxies[index];
    }

    /// @notice get the beacon proxies count
    function getProxyCount() external view virtual returns (uint256) {
        return proxyIdCounter.current();
    }

    /// @notice upgrade all beacon proxies
    /// @param implContract: new implementation contract address
    function upgradeProxies(address implContract) external virtual onlyOwner {
        beacon.updateContract(implContract);
    }
}