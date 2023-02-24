/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IFee.sol";

abstract contract Fee is IFee {
    // quote asset token address
    IERC20 public quoteAsset;

    // base asset token address
    IERC20 public baseAsset;

    // base fee for base asset
    uint256 internal baseFeeFunding;

    // base fee for quote asset
    uint256 internal quoteFeeFunding;

    function _initFee(IERC20 _quoteAsset, IERC20 _baseAsset) internal {
        quoteAsset = _quoteAsset;
        baseAsset = _baseAsset;
    }

    /// @inheritdoc IFee
    function decreaseBaseFeeFunding(uint256 baseFee) public virtual {
        if (baseFee > 0) {
            baseFeeFunding -= baseFee;
        }
    }

    /// @inheritdoc IFee
    function decreaseQuoteFeeFunding(uint256 quoteFee) public virtual {
        if (quoteFee > 0) {
            quoteFeeFunding -= quoteFee;
        }
    }

    /// @inheritdoc IFee
    function increaseBaseFeeFunding(uint256 baseFee) public virtual {
        _increaseBaseFeeFunding(baseFee);
    }

    /// @inheritdoc IFee
    function increaseQuoteFeeFunding(uint256 quoteFee) public virtual {
        _increaseQuoteFeeFunding(quoteFee);
    }

    /// @notice increase the fee base with internal when fill amm and share fee
    function _increaseBaseFeeFunding(uint256 baseFee) internal virtual {
        if (baseFee > 0) {
            baseFeeFunding += baseFee;
        }
    }

    /// @notice increase the fee base with internal when fill amm and share fee
    function _increaseQuoteFeeFunding(uint256 quoteFee) internal virtual {
        if (quoteFee > 0) {
            quoteFeeFunding += quoteFee;
        }
    }

    function resetFee(uint256 baseFee, uint256 quoteFee) external virtual {
        baseFeeFunding -= baseFee;
        quoteFeeFunding -= quoteFee;
    }

    function getFee() external view returns (uint256, uint256) {
        return (baseFeeFunding, quoteFeeFunding);
    }
}