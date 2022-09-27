// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../exchange/TickPosition.sol";
import "../exchange/LiquidityBitmap.sol";
import "../helper/Timers.sol";
import "../../../interfaces/IPairManager.sol";

contract PairManagerStorage {
    using TickPosition for TickPosition.Data;
    using LiquidityBitmap for mapping(uint128 => uint256);

    // quote asset token address
    IERC20 internal quoteAsset;

    // base asset token address
    IERC20 internal baseAsset;

    // base fee for base asset
    uint256 internal baseFeeFunding;

    // base fee for quote asset
    uint256 internal quoteFeeFunding;

    address public owner;

    bool internal _isInitialized;

    // the smallest number of the price. Eg. 100 for 0.01
    uint256 internal basisPoint;

    // demoninator of the basis point. Eg. 10000 for 0.01
    uint256 public BASE_BASIC_POINT;

    // Max finding word can be 3500
    uint128 public maxFindingWordsIndex;

    // Counter party address
    address public counterParty;

    // Liquidaity pool
    address public liquidityPool;

    uint64 public expireTime;

    // The unit of measurement to express the change in value between two currencies
    struct SingleSlot {
        uint128 pip;
        //0: not set
        //1: buy
        //2: sell
        uint8 isFullBuy;
    }

    enum CurrentLiquiditySide {
        NotSet,
        Buy,
        Sell
    }

    struct LiquidityOfEachPip {
        uint128 pip;
        uint256 liquidity;
    }

    struct StepComputations {
        uint128 pipNext;
    }

    struct ReserveSnapshot {
        uint128 pip;
        uint64 timestamp;
        uint64 blockNumber;
    }

    ReserveSnapshot[] public reserveSnapshots;

    SingleSlot public singleSlot;
    mapping(uint128 => TickPosition.Data) public tickPosition;
    mapping(uint128 => uint256) public tickStore;
    // a packed array of bit, where liquidity is filled or not
    mapping(uint128 => uint256) public liquidityBitmap;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    ///////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// EXTEND VIEWER ///////////////////////////////////

    function balanceBase() public view returns (uint256) {
        return baseAsset.balanceOf(address(this));
    }

    function balanceQuote() public view returns (uint256) {
        return quoteAsset.balanceOf(address(this));
    }

    struct DebtPool {
        uint128 debtQuote;
        uint128 debtBase;
    }

    // @deprecated just hold to upgradeable
    mapping(bytes32 => DebtPool) debtPool;

    uint128 public maxWordRangeForLimitOrder;
    uint128 public maxWordRangeForMarketOrder;

    mapping(address => bool) public liquidityPoolAllowed;
}