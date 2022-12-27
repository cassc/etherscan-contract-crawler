// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

import "./interfaces/IAveragePriceOracle.sol";
import "./interfaces/IPair.sol";

contract AveragePriceOracle is IAveragePriceOracle, Ownable, Initializable {
    using PRBMathUD60x18 for uint256;

    uint256 public constant PERIOD = 12 hours;
    uint256 private constant BASE_PERCENT = 10000;
    uint256 private constant APE_SWAP_PERCENT = 1500;
    uint256 private constant BI_SWAP_PERCENT = 1500;
    uint256 private constant PANCAKE_SWAP_PERCENT = 3500;
    uint256 private constant TWAP_PERCENT = 6500;
    uint256 private constant Q112 = 1 << 112;

    address public zoinks;
    address public apeSwapPair;
    address public biSwapPair;
    address public pancakeSwapPair;
    uint256 public apeSwapAveragePriceLast;
    uint256 public biSwapAveragePriceLast;
    uint256 public pancakeSwapAveragePriceLast;
    uint256 public twapLast;
    uint256 private _apeSwapPriceCumulativeLast;
    uint256 private _biSwapPriceCumulativeLast;
    uint256 private _pancakeSwapPriceCumulativeLast;
    uint32 private _blockTimestampLast;
    
    modifier onlyZoinks {
        require(
            msg.sender == zoinks,
            "AveragePriceOracle: caller is not the Zoinks contract"
        );
        _;
    }

    /**
    * @notice Initializes the contract.
    * @dev To initialize the contract, there must be liquidity on 
    * ApeSwap, BiSwap and PancakeSwap.
    * @param zoinks_ Zoinks token address.
    * @param apeSwapPair_ Pair contract address (from ApeSwap DEX).
    * @param biSwapPair_ Pair contract address (from BiSwap DEX).
    * @param pancakeSwapPair_ Pair contract address (from PancakeSwap DEX).
    */
    function initialize(
        address zoinks_,
        address apeSwapPair_,
        address biSwapPair_,
        address pancakeSwapPair_
    )
        external
        onlyOwner
        initializer
    {
        zoinks = zoinks_;
        apeSwapPair = apeSwapPair_;
        biSwapPair = biSwapPair_;
        pancakeSwapPair = pancakeSwapPair_;
        IPair(apeSwapPair_).sync();
        IPair(biSwapPair_).sync();
        IPair(pancakeSwapPair_).sync();
        (uint112 apeSwapReserve0, uint112 apeSwapReserve1, uint32 blockTimestamp)
            = IPair(apeSwapPair_).getReserves();
        (uint112 biSwapReserve0, uint112 biSwapReserve1, )
            = IPair(biSwapPair_).getReserves();
        (uint112 pancakeSwapReserve0, uint112 pancakeSwapReserve1, )
            = IPair(pancakeSwapPair_).getReserves();
        require(
            apeSwapReserve0 != 0 &&
            apeSwapReserve1 != 0 &&
            biSwapReserve0 != 0 &&
            biSwapReserve1 != 0 &&
            pancakeSwapReserve0 != 0 &&
            pancakeSwapReserve1 != 0,
            "AveragePriceOracle: no reserves"
        );
        _blockTimestampLast = blockTimestamp;
        _apeSwapPriceCumulativeLast = IPair(apeSwapPair_).price1CumulativeLast();
        _biSwapPriceCumulativeLast = IPair(biSwapPair_).price1CumulativeLast();
        _pancakeSwapPriceCumulativeLast = IPair(pancakeSwapPair_).price1CumulativeLast();
    }

    /**
    * @notice Updates the stored time-weighted average price.
    * @dev The function can only be called successfully if the contract has been initialized. 
    * Called by the Zoinks contract once every 12 hours.
    */
    function update() external onlyZoinks {
        IPair(apeSwapPair).sync();
        IPair(biSwapPair).sync();
        IPair(pancakeSwapPair).sync();
        uint32 currentBlockTimestamp = _currentBlockTimestamp();
        uint256 apeSwapPriceCumulative = IPair(apeSwapPair).price1CumulativeLast();
        uint256 biSwapPriceCumulative = IPair(biSwapPair).price1CumulativeLast();
        uint256 pancakeSwapPriceCumulative = IPair(pancakeSwapPair).price1CumulativeLast();
        uint256 timeElapsed = currentBlockTimestamp - _blockTimestampLast;
        require(
            timeElapsed >= PERIOD,
            "AveragePriceOracle: period not elapsed"
        );
        apeSwapAveragePriceLast =
            (apeSwapPriceCumulative - _apeSwapPriceCumulativeLast).div(timeElapsed).div(Q112);
        biSwapAveragePriceLast =
            (biSwapPriceCumulative - _biSwapPriceCumulativeLast).div(timeElapsed).div(Q112);
        pancakeSwapAveragePriceLast =
            (pancakeSwapPriceCumulative - _pancakeSwapPriceCumulativeLast).div(timeElapsed).div(Q112);
        _apeSwapPriceCumulativeLast = apeSwapPriceCumulative;
        _biSwapPriceCumulativeLast = biSwapPriceCumulative;
        _pancakeSwapPriceCumulativeLast = pancakeSwapPriceCumulative;
        _blockTimestampLast = currentBlockTimestamp;
        twapLast =
            ((APE_SWAP_PERCENT.mul(apeSwapAveragePriceLast)
            + BI_SWAP_PERCENT.mul(biSwapAveragePriceLast)
            + PANCAKE_SWAP_PERCENT.mul(pancakeSwapAveragePriceLast))
            .mul(BASE_PERCENT)
            .div(TWAP_PERCENT)).toUint();
    }
 
    /**
    * @notice Retrieves the current block timestamp.
    * @dev Returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1].
    * @return Current block timestamp.
    */
    function _currentBlockTimestamp() private view returns (uint32) {
        return uint32(block.timestamp % (1 << 32));
    }
}