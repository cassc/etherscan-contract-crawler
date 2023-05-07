// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IMark2Market.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IPortfolioManager.sol";

contract Mark2Market is IMark2Market, Initializable, AccessControlUpgradeable, UUPSUpgradeable {

    // ---  fields

    IPortfolioManager public portfolioManager;

    // ---  events

    event PortfolioManagerUpdated(address portfolio);


    // ---  modifiers

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override
    {}


    // ---  setters

    function setPortfolioManager(address _value) external onlyAdmin {
        require(_value != address(0), "Zero address not allowed");
        portfolioManager = IPortfolioManager(_value);
        emit PortfolioManagerUpdated(_value);
    }

    // ---  logic

    function strategyAssets() public view override returns (StrategyAsset[] memory) {

        IPortfolioManager.StrategyWeight[] memory weights = portfolioManager.getAllStrategyWeights();
        uint256 count = weights.length;

        StrategyAsset[] memory assets = new StrategyAsset[](count);

        for (uint8 i = 0; i < count; i++) {
            IPortfolioManager.StrategyWeight memory weight = weights[i];
            IStrategy strategy = IStrategy(weight.strategy);

            assets[i] = StrategyAsset(
                weight.strategy,
                strategy.netAssetValue(),
                strategy.liquidationValue()
            );
        }

        return assets;
    }

    function totalNetAssets() public view override returns (uint256) {
        return _totalAssets(false);
    }

    function totalLiquidationAssets() public view override returns (uint256) {
        return _totalAssets(true);
    }

    function _totalAssets(bool liquidation) internal view returns (uint256) {
        uint256 totalAssetPrice = 0;
        IPortfolioManager.StrategyWeight[] memory weights = portfolioManager.getAllStrategyWeights();

        for (uint8 i = 0; i < weights.length; i++) {
            IStrategy strategy = IStrategy(weights[i].strategy);
            if (liquidation) {
                totalAssetPrice += strategy.liquidationValue();
            } else {
                totalAssetPrice += strategy.netAssetValue();
            }
        }

        return totalAssetPrice;
    }

}