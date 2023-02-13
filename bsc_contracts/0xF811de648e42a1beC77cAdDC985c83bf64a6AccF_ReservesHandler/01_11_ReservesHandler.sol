// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseSwapper.sol";
import "../../Interactors/ReservesInteractor/ReservesInteractorBase.sol";

interface IReservesHandler {
    function reduceAndDistribute(address market) external;
    function reduceAndDistributeMany(address[] calldata market) external;
}

interface IOTokenForReservesHandler {
    function underlying() external view returns (address);
    function mint(uint mintAmount) external returns (uint);
}

interface IComptrollerForReservesHandler {
    function getAllMarkets() external returns (address[] memory);
}

/**
 * @title Ola's Reserves Handler Contract
 */
contract ReservesHandler is Ownable, ReservesInteractorBase, BaseSwapper, IReservesHandler {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant public nativeCoinUnderlying = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    address immutable unitroller;
    address immutable public partnerCollectorAddress;
    address immutable public olaCollectorAddress;

    uint fullUnit = 1e18;

    // Parts
    uint partnerRawFraction;
    uint partnerSupplyFraction;
    uint olaRawFraction;
    uint olaSupplyFraction;

    uint marketsCount;

    // Note : Saves gas
    mapping(address => address) marketToUnderlying;
    mapping(address => address) underlyingToMarket;

    // ***** Views *****
    function isMarketSupported(address market) public view returns (bool) {
        return marketToUnderlying[market] != address(0);
    }
    function isUnderlyingSupported(address underlying) public view returns (bool) {
        return underlyingToMarket[underlying] != address(0);
    }

    // ***** Main Interface *****

    function reduceAndDistribute(address market) external override onlyEOA {
        reduceReserveAndDistributeInternal(market);
    }

    function reduceAndDistributeMany(address[] calldata markets) external override onlyEOA {
        uint length = markets.length;
        for (uint i = 0; i < length; i++) {
            reduceReserveAndDistributeInternal(markets[i]);
        }
    }

    // ***** Admin Functions *****

    function setSwapPath(address token, address[] calldata swapPath) external onlyOwner {
        require(isUnderlyingSupported(token), "TOKEN_NOT_SUPPORTED");
        setSwapPathInternal(token, swapPath);
    }

    constructor(
        address _unitroller,
        address _factory,
        uint _factoryNumerator,
        uint _factoryDenominator,
        address _wNative,
        address _partnerCollector,
        address _olaCollector
    ) BaseSwapper(_factory, _factoryNumerator, _factoryDenominator, _wNative) {
        unitroller = _unitroller;
        partnerCollectorAddress = _partnerCollector;
        olaCollectorAddress = _olaCollector;
    }

    // ***** Syncing *****

    function syncLenMarkets() external onlyEOA {
        // TODO : Check if there are new markets
        address[] memory allMarkets = IComptrollerForReservesHandler(unitroller).getAllMarkets();

        if (allMarkets.length > marketsCount) {
            syncAllLenMarketsInternal(allMarkets);
        }
    }

    // ***** Inner Initialization *****
    function syncAllLenMarketsInternal(address[] memory allMarkets) internal {
        for (uint i = 0; i< allMarkets.length; i++ ) {
            registerMarketInternal(allMarkets[i]);
        }
    }

    function registerMarketInternal(address market) internal {
        if (isMarketSupported(market)) {
            return;
        }
//        require(!isMarketSupported(market), "MARKET_ALREADY_SUPPORTED");

        address underlying = IOTokenForReservesHandler(market).underlying();

        marketToUnderlying[market] = underlying;
        underlyingToMarket[underlying] = market;


        if (underlying != nativeCoinUnderlying) {
            IERC20(underlying).approve(market, uint256(-1));
        }

        marketsCount++;
    }

    // ***** Inner Core *****

    function reduceReserveAndDistributeInternal(address market) internal {
        address marketUnderlying = marketToUnderlying[market];
        require(marketUnderlying != address(0), "MARKET_NOT_SUPPORTED");

        // First, reduce reserves
        reduceMarketReservesInternal(market);

        // Then, handle the reserves
        distributeAssetInternal(marketUnderlying, market);
    }

    function distributeAssetInternal(address asset, address market) internal {
        uint selfBalance = IERC20(asset).balanceOf(address(this));

        address[] memory swapPath = swapPaths[asset];
        bool requiresConversion = swapPath.length > 0;
        if (requiresConversion) {
            address assetToConvertTo = swapPath[swapPath.length - 1];

            _convertByPath(swapPath, selfBalance);

            // Note : Recursive call to handle the balance of the converted asset
            address matchingMarket = underlyingToMarket[assetToConvertTo];
            require(matchingMarket != address(0), "NO_MATCHING_MARKET");
            distributeAssetInternal(assetToConvertTo, matchingMarket);
        } else {
            (uint partnerRawPart, uint partnerSupplyPart, uint olaRawPart, uint olaSupplyPart) = partitionAsset(selfBalance);


            transferRawAsset(partnerCollectorAddress, asset, partnerRawPart);
            supplyAndSendOTokens(partnerCollectorAddress, asset, market, partnerSupplyPart);

            transferRawAsset(partnerCollectorAddress, asset, partnerRawPart);
            supplyAndSendOTokens(partnerCollectorAddress, asset, market, partnerSupplyPart);
        }
    }

    // ***** Inner Asset management *****

    function supplyAndSendOTokens( address receiver, address asset, address market, uint assetAmount) internal {
        if (assetAmount == 0) {
            return;
        }

        // TODO : CRITICAL : Add case for NATIVE
        uint oTokenBalanceBefore = IERC20(market).balanceOf(address(this));
        IOTokenForReservesHandler(market).mint(assetAmount);
        uint oTokenBalanceAfter = IERC20(market).balanceOf(address(this));

        uint oTokenMinted = oTokenBalanceAfter - oTokenBalanceBefore;

        // NOTE : Edge case for dust amounts
        if (oTokenMinted == 0) {
            return;
        }

        IERC20(market).transfer(receiver, oTokenMinted);
    }

    function transferRawAsset( address receiver, address asset, uint assetAmount) internal {
        if (assetAmount == 0) {
            return;
        }

        if (asset == nativeCoinUnderlying) {
            payable(receiver).transfer(assetAmount);
        } else {
            IERC20(asset).transfer(receiver, assetAmount);
        }
    }

    // ***** Inner Utils *****

    /**
     *  Calculate the actual amount of asset for each purpose.
     */
    function partitionAsset(uint totalAmount) internal view returns (uint partnerRawPart, uint partnerSupplyPart, uint olaRawPart, uint olaSupplyPart) {
        partnerRawPart = fractionFrom(totalAmount, partnerRawFraction);
        partnerSupplyPart = fractionFrom(totalAmount, partnerSupplyFraction);
        olaRawPart = fractionFrom(totalAmount, olaRawFraction);
        olaSupplyPart = fractionFrom(totalAmount, olaSupplyFraction);

        // Sanity
        uint totalSum = partnerRawPart + partnerSupplyPart + olaRawPart + olaSupplyPart;

        // NOTE : The difference should be in dust amount due to rounding error, we will reduce Ola's part in that case
        if (totalSum > totalAmount) {
            uint diff = totalSum - totalAmount;

            if (olaSupplyPart > diff) {
                olaSupplyPart -= diff;
            } else if (olaRawPart > diff) {
                olaRawPart -= diff;
            } else {
                revert("FAULTY_PART_CALCULATION");
            }
        }
    }

    /**
     * Calculate the part (fraction) out of the given amount.
     * @param amount The full amount (in any scale)
     * @param fraction A "decimal" fraction (e.g 0.23 = 23%) (scaled by 1e18)
     */
    function fractionFrom(uint amount, uint fraction) internal view returns (uint) {
        return amount.mul(fraction).div(fullUnit);
    }

    /**
     * It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
     */
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "ReservesHandler: must use EOA");
        _;
    }

    /**
     * Does nothing
     */
    receive() external payable {
    }
}