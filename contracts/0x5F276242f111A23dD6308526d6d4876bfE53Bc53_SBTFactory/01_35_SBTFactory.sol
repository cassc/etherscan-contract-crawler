// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./SBT.sol";
import "./Beacon.sol";

contract SBTFactory is Initializable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    Beacon internal _beacon;
    mapping(uint256 => address) internal _proxies;
    CountersUpgradeable.Counter internal _proxyIdCounter;

    event ProxyCreated(
        address owner,
        string name,
        string symbol,
        string contractUri,
        string baseUri,
        bool claimable,
        uint256 proxyIndex,
        address proxyAddress
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address implContract) public initializer {
        _beacon = new Beacon(implContract);
        __Ownable_init();
    }

    /// @notice Create SBT proxy contract
    /// @param owner: SBT contract owner
    /// @param name: SBT contract name
    /// @param symbol: SBT contract symbol
    /// @param contractURI: SBT contract contractURI
    /// @param baseURI: SBT contract baseURI of tokenURI
    /// @param claimable: SBT token claimable
    function createProxy(
        address owner,
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory baseURI,
        bool claimable
    ) external virtual {
        BeaconProxy proxy = new BeaconProxy(
            address(_beacon),
            abi.encodeWithSelector(SBT.initialize.selector, owner, name, symbol, contractURI, baseURI, claimable)
        );
        _proxyIdCounter.increment();
        uint256 index = _proxyIdCounter.current();

        _proxies[index] = address(proxy);
        emit ProxyCreated(owner, name, symbol, contractURI, baseURI, claimable, index, address(proxy));
    }

    /// @notice get the current implementation contract address
    function getImplementation() public view returns (address) {
        return _beacon.implementation();
    }

    /// @notice get the beacon contract address
    function getBeacon() public view returns (address) {
        return address(_beacon);
    }

    /// @notice get the beacon proxy contract address by index
    function getProxy(uint256 index) public view returns (address) {
        return _proxies[index];
    }

    /// @notice get the beacon proxies count
    function getProxyCount() public view returns (uint256) {
        return _proxyIdCounter.current();
    }

    /// @notice upgrade all beacon proxies
    /// @param implContract: new implementation contract address
    function upgradeProxies(address implContract) external onlyOwner {
        _beacon.updateContract(implContract);
    }
}