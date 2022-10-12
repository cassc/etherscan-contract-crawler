// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import '../token/IERC20.sol';
import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';

contract OracleWoo is IOracle, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    string  public symbol;
    bytes32 public immutable symbolId;

    IWooracleV1 public immutable feed;
    uint256 public immutable baseDecimals;
    uint256 public immutable quoteDecimals;

    int256  public immutable jumpTimeWindow;

    // stores timestamp/value/jump in 1 slot, instead of 3, to save gas
    // timestamp takes 32 bits, which can hold timestamp range from 1 to 4294967295 (year 2106)
    // value takes 96 bits with accuracy of 1e-18, which can hold value range from 1e-18 to 79,228,162,514.26
    struct Data {
        uint32 timestamp;
        uint96 value;
        int128 jump;
    }
    Data public data;

    constructor (string memory symbol_, address feed_, int256 jumpTimeWindow_) NameVersion('OracleWoo', '3.0.4') {
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));
        feed = IWooracleV1(feed_);
        baseDecimals = IERC20(IWooracleV1(feed_)._BASE_TOKEN_()).decimals();
        quoteDecimals = IERC20(IWooracleV1(feed_)._QUOTE_TOKEN_()).decimals();
        jumpTimeWindow = jumpTimeWindow_;
    }

    function timestamp() external pure returns (uint256) {
        revert('OracleWoo.timestamp: no timestamp');
    }

    function value() public view returns (uint256 val) {
        val = feed._I_();
        if (baseDecimals != quoteDecimals) {
            val = val * (10 ** baseDecimals) / (10 ** quoteDecimals);
        }
    }

    function getValue() external view returns (uint256 val) {
        require((val = value()) != 0, 'OracleWoo.getValue: 0');
    }

    function getValueWithJump() external returns (uint256 val, int256 jump) {
        Data memory d = data;
        if (d.timestamp == block.timestamp) {
            // data already updated in current block
            return (d.value, d.jump);
        }

        val = value();
        require(val != 0 && val <= type(uint96).max);

        int256 interval = (block.timestamp - d.timestamp).utoi();
        if (interval < jumpTimeWindow) {
            jump = d.jump * (jumpTimeWindow - interval) / jumpTimeWindow // previous jump impact
                 + (val.utoi() - uint256(d.value).utoi());               // current jump impact
        } else {
            jump = (val.utoi() - uint256(d.value).utoi()) * jumpTimeWindow / interval; // only current jump impact
        }

        data = Data({
            timestamp: uint32(block.timestamp),
            value:     uint96(val),
            jump:      int128(jump) // never overflows
        });
    }

}

interface IWooracleV1 {
    function _BASE_TOKEN_() external view returns (address);
    function _QUOTE_TOKEN_() external view returns (address);
    function _I_() external view returns (uint256);
}