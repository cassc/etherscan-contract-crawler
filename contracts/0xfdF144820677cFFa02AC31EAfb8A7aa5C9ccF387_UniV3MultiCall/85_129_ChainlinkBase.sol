// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AggregatorV3Interface} from "../../interfaces/oracles/chainlink/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Constants} from "../../../Constants.sol";
import {Errors} from "../../../Errors.sol";
import {IOracle} from "../../interfaces/IOracle.sol";

/**
 * @dev supports oracles which are compatible with v2v3 or v3 interfaces
 */
abstract contract ChainlinkBase is IOracle {
    // solhint-disable var-name-mixedcase
    uint256 public immutable BASE_CURRENCY_UNIT;
    mapping(address => address) public oracleAddrs;

    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs,
        uint256 baseCurrencyUnit
    ) {
        uint256 tokenAddrsLength = _tokenAddrs.length;
        if (tokenAddrsLength == 0 || tokenAddrsLength != _oracleAddrs.length) {
            revert Errors.InvalidArrayLength();
        }
        uint8 oracleDecimals;
        uint256 version;
        for (uint256 i; i < tokenAddrsLength; ) {
            if (_tokenAddrs[i] == address(0) || _oracleAddrs[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            oracleDecimals = AggregatorV3Interface(_oracleAddrs[i]).decimals();
            if (10 ** oracleDecimals != baseCurrencyUnit) {
                revert Errors.InvalidOracleDecimals();
            }
            version = AggregatorV3Interface(_oracleAddrs[i]).version();
            if (version != 4) {
                revert Errors.InvalidOracleVersion();
            }
            oracleAddrs[_tokenAddrs[i]] = _oracleAddrs[i];
            unchecked {
                ++i;
            }
        }
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
    }

    function getPrice(
        address collToken,
        address loanToken
    ) external view virtual returns (uint256 collTokenPriceInLoanToken) {
        (uint256 priceOfCollToken, uint256 priceOfLoanToken) = getRawPrices(
            collToken,
            loanToken
        );
        uint256 loanTokenDecimals = IERC20Metadata(loanToken).decimals();
        collTokenPriceInLoanToken = Math.mulDiv(
            priceOfCollToken,
            10 ** loanTokenDecimals,
            priceOfLoanToken
        );
    }

    function getRawPrices(
        address collToken,
        address loanToken
    )
        public
        view
        virtual
        returns (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw)
    {
        (collTokenPriceRaw, loanTokenPriceRaw) = (
            _getPriceOfToken(collToken),
            _getPriceOfToken(loanToken)
        );
    }

    function _getPriceOfToken(
        address token
    ) internal view virtual returns (uint256 tokenPriceRaw) {
        address oracleAddr = oracleAddrs[token];
        if (oracleAddr == address(0)) {
            revert Errors.NoOracle();
        }
        tokenPriceRaw = _checkAndReturnLatestRoundData(oracleAddr);
    }

    function _checkAndReturnLatestRoundData(
        address oracleAddr
    ) internal view virtual returns (uint256 tokenPriceRaw) {
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = AggregatorV3Interface(oracleAddr).latestRoundData();
        if (
            roundId == 0 ||
            answeredInRound < roundId ||
            answer < 1 ||
            updatedAt > block.timestamp ||
            updatedAt + Constants.MAX_PRICE_UPDATE_TIMESTAMP_DIVERGENCE <
            block.timestamp
        ) {
            revert Errors.InvalidOracleAnswer();
        }
        tokenPriceRaw = uint256(answer);
    }
}