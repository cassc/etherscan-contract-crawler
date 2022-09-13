// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./RegistryStructs.sol";

contract MarketplaceRegistry is Initializable, UUPSUpgradeable {
    address public owner;

    Marketplace[] public marketplaces;

    event NewOwner(address indexed owner);
    event NewMarketplace(address indexed proxy, bool isLibrary);
    event UpdateMarketplaceStatus(uint256 marketId, bool newStatus);
    event UpdateMarketplaceProxy(uint256 marketId, address indexed proxy, bool isLibrary);

    function _onlyOwner() private view {
        require(msg.sender == owner);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function initialize() public initializer {
        __UUPSUpgradeable_init();

        owner = msg.sender;
        emit NewOwner(msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setOwner(address _new) external onlyOwner {
        owner = _new;
        emit NewOwner(_new);
    }

    function addMarketplace(address proxy, bool isLib) external onlyOwner {
        marketplaces.push(Marketplace(proxy, isLib, true));
        emit NewMarketplace(proxy, isLib);
    }

    function setMarketplaceStatus(uint256 marketId, bool newStatus) external onlyOwner {
        Marketplace storage market = marketplaces[marketId];
        market.isActive = newStatus;
        emit UpdateMarketplaceStatus(marketId, newStatus);
    }

    function setMarketplaceProxy(
        uint256 marketId,
        address newProxy,
        bool isLib
    ) external onlyOwner {
        Marketplace storage market = marketplaces[marketId];
        market.proxy = newProxy;
        market.isLib = isLib;
        emit UpdateMarketplaceProxy(marketId, newProxy, isLib);
    }
}