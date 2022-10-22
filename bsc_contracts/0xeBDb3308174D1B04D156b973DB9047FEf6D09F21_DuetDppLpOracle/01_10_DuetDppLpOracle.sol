//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IUSDOracle.sol";
import "../interfaces/IDPPController.sol";
import "../chainlink/AggregatorV3Interface.sol";
import "../interfaces/IDodoOracle.sol";
import "../lib/Adminable.sol";

contract DuetDppLpOracle is IUSDOracle, Initializable, Adminable {
    address public usdLikeToken;
    IDodoOracle public dodoOracle;
    uint256 public constant decimals = 8;

    struct CtrlInfo {
        IDPPController controller;
        address baseToken;
        address quoteToken;
        uint256 baseTokenDecimals;
        uint256 quoteTokenDecimals;
    }

    constructor() initializer {}

    function initialize(
        address admin_,
        address usdLikeToken_,
        IDodoOracle dodoOracle_
    ) external initializer {
        _setAdmin(admin_);
        usdLikeToken = usdLikeToken_;
        dodoOracle = dodoOracle_;
    }

    function setUsdLikeToken(address usdLikeToken_) external onlyAdmin {
        usdLikeToken = usdLikeToken_;
    }

    function setDodoOracle(IDodoOracle dodoOracle_) external onlyAdmin {
        dodoOracle = dodoOracle_;
    }

    /**
     * !!! UNSAFE !!!
     * !!! FOR DISPLAY ONLY !!!
     * @dev This oracle can only be used for display purposes and cannot be used as any actual value judgment basis.
     * @return Unsafe USD value with precision of 8
     */
    function getPrice(address controllerToken_) external view override returns (uint256) {
        CtrlInfo memory curCtrl = getCtrlInfo(controllerToken_);
        require(curCtrl.quoteToken == usdLikeToken, "DuetDppLpOracle: Invalid LP Token");

        (uint256 baseTokenAmount, uint256 quoteTokenAmount) = curCtrl.controller.recommendBaseAndQuote(
            10**IERC20Metadata(address(curCtrl.controller)).decimals()
        );

        // 1e18
        uint256 baseTokenPrice = dodoOracle.prices(curCtrl.baseToken);
        require(baseTokenPrice > 0, "DuetDppLpOracle: Invalid base token price");

        // 1e8
        uint256 baseTokenValue = convertDecimal(
            (baseTokenAmount * baseTokenPrice) / 1e18,
            curCtrl.baseTokenDecimals,
            decimals
        );

        // 1e8
        uint256 quoteValue = convertDecimal(quoteTokenAmount, curCtrl.quoteTokenDecimals, decimals);
        return baseTokenValue + quoteValue;
    }

    function getCtrlInfo(address controllerToken_) public view returns (CtrlInfo memory ctrlInfo) {
        ctrlInfo.controller = IDPPController(controllerToken_);

        ctrlInfo.baseToken = IDPPController(controllerToken_)._BASE_TOKEN_();
        ctrlInfo.quoteToken = IDPPController(controllerToken_)._QUOTE_TOKEN_();
        ctrlInfo.baseTokenDecimals = IERC20Metadata(ctrlInfo.baseToken).decimals();
        ctrlInfo.quoteTokenDecimals = IERC20Metadata(ctrlInfo.quoteToken).decimals();
    }

    /**
     * @dev convert a value from sourceDecimal to targetDecimal
     */
    function convertDecimal(
        uint256 value_,
        uint256 sourceDecimal_,
        uint256 targetDecimal_
    ) public pure returns (uint256) {
        if (sourceDecimal_ > targetDecimal_) {
            return value_ / (sourceDecimal_ - targetDecimal_);
        }

        if (sourceDecimal_ < targetDecimal_) {
            return value_ * (targetDecimal_ - sourceDecimal_);
        }
        return value_;
    }
}