// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./IFeedStrategy.sol";
import "./../../interfaces/IChainlinkPriceFeed.sol";

contract PriceFeedRouterV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable {

    using AddressUpgradeable for address;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    bool public upgradeStatus;
    mapping(string => uint256) public fiatNameToFiatId;
    mapping(uint256 => IFeedStrategy) public fiatIdToUsdStrategies;

    mapping(address => IFeedStrategy) public cryptoToUsdStrategies;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        fiatNameToFiatId["USD"] = 0;

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getPrice(address token, string calldata fiatName)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPrice(token, fiatNameToFiatId[fiatName]);
    }

    function getPrice(address token, uint256 fiatId)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPrice(token, fiatId);
    }

    function getPriceOfAmount(address token, uint256 amount, string calldata fiatName)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPriceOfAmount(token, amount, fiatNameToFiatId[fiatName]);
    }

    function getPriceOfAmount(address token, uint256 amount, uint256 fiatId)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPriceOfAmount(token, amount, fiatId);
    }

    function setCryptoStrategy(address strategy, address coin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        cryptoToUsdStrategies[coin] = IFeedStrategy(strategy);
    }

    function setFiatStrategy(
        string calldata fiatSymbol,
        uint256 fiatId,
        address fiatFeed
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fiatId != 0, "PriceFeed: id 0 reserved for USD");
        fiatNameToFiatId[fiatSymbol] = fiatId;
        fiatIdToUsdStrategies[fiatId] = IFeedStrategy(fiatFeed);
    }

    // 1.0 `token` costs `value` of [fiatId] (in decimals of `token`)
    function _getPrice(address token, uint256 fiatId)
        private
        view
        returns (uint256 value, uint8 decimals)
    {
        IFeedStrategy priceFeed = cryptoToUsdStrategies[token];
        require(
            address(priceFeed) != address(0),
            "PriceFeedRouter: 1no priceFeed"
        );

        (int256 usdPrice, uint8 usdDecimals) = priceFeed.getPrice();
        require(usdPrice > 0, "PriceFeedRouter: 1feed lte 0");

        if (fiatId == 0) {
            return (uint256(usdPrice), usdDecimals);
        } else {
            IFeedStrategy fiatPriceFeed = fiatIdToUsdStrategies[fiatId];
            require(
                address(fiatPriceFeed) != address(0),
                "PriceFeedRouter: 2no priceFeed"
            );

            (int256 fiatPrice, uint8 fiatDecimals) = fiatPriceFeed.getPrice();
            require(fiatPrice > 0, "PriceFeedRouter: 2feed lte 0");

            return (
                (uint256(usdPrice) * 10**fiatDecimals) / uint256(fiatPrice),
                usdDecimals
            );
        }
    }

    function _getPriceOfAmount(address token, uint256 amount, uint256 fiatId)
        private
        view
        returns (uint256 value, uint8 decimals)
    {
        IFeedStrategy priceFeed = cryptoToUsdStrategies[token];
        require(
            address(priceFeed) != address(0),
            "PriceFeedRouter: 1no priceFeed"
        );

        (int256 usdPrice, uint8 usdDecimals) = priceFeed.getPriceOfAmount(amount);
        require(usdPrice > 0, "PriceFeedRouter: 1feed lte 0");

        if (fiatId == 0) {
            return (uint256(usdPrice), usdDecimals);
        } else {
            IFeedStrategy fiatPriceFeed = fiatIdToUsdStrategies[fiatId];
            require(
                address(fiatPriceFeed) != address(0),
                "PriceFeedRouter: 2no priceFeed"
            );

            (int256 fiatPrice, uint8 fiatDecimals) = fiatPriceFeed.getPrice();
            require(fiatPrice > 0, "PriceFeedRouter: 2feed lte 0");

            return (
                (uint256(usdPrice) * 10**fiatDecimals) / uint256(fiatPrice),
                usdDecimals
            );
        }
    }

    function decimalsConverter(uint256 _amount, uint8 _decimalsIn, uint8 _decimalsOut) public pure returns(uint256){
        if(_decimalsIn > _decimalsOut){
            return _amount / 10 ** (_decimalsIn - _decimalsOut);
        }
        else if(_decimalsIn < _decimalsOut){
            return _amount * 10 ** (_decimalsOut - _decimalsIn);
        }
        else{
            return _amount;
        }
    }

    function grantRole(bytes32 role, address account)
    public
    override
    onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "Handler: Not contract");
        }
        _grantRole(role, account);
    }

    function changeUpgradeStatus(bool _status)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }


    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override {
        require(upgradeStatus, "Executor: Upgrade not allowed");
        upgradeStatus = false;
    }
}