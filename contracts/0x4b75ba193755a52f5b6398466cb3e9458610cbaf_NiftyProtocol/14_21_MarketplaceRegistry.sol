pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceRegistry is Ownable {
    struct Marketplace {
        uint256 feeMultiplier;
        address feeCollector;
        bool isActive;
    }

    event MarketplaceRegister(bytes32 identifier, uint256 feeMultiplier, address feeCollector);
    event MarketplaceUpdateStatus(bytes32 identifier, bool status);
    event MarketplaceSetFees(bytes32 identifier, uint256 feeMultiplier, address feeCollector);

    bool public distributeMarketplaceFees = true;

    mapping(bytes32 => Marketplace) marketplaces;

    function marketplaceDistribution(bool _distributeMarketplaceFees)
        external
        onlyOwner
    {
        distributeMarketplaceFees = _distributeMarketplaceFees;
    }

    function registerMarketplace(bytes32 identifier, uint256 feeMultiplier, address feeCollector) external onlyOwner {
        require(feeMultiplier <= 100, "fee multiplier must be betwen 0 to 100");
        marketplaces[identifier] = Marketplace(feeMultiplier, feeCollector, true);
        emit MarketplaceRegister(identifier, feeMultiplier, feeCollector);
    }

    function setMarketplaceStatus(bytes32 identifier, bool isActive)
        external
        onlyOwner
    {
        marketplaces[identifier].isActive = isActive;
        emit MarketplaceUpdateStatus(identifier, isActive);
    }

    function setMarketplaceFees(
        bytes32 identifier,
        uint256 feeMultiplier,
        address feeCollector
    ) external onlyOwner {
        require(feeMultiplier <= 100, "fee multiplier must be betwen 0 to 100");
        marketplaces[identifier].feeMultiplier = feeMultiplier;
        marketplaces[identifier].feeCollector = feeCollector;
        emit MarketplaceSetFees(identifier, feeMultiplier, feeCollector);
    }
}