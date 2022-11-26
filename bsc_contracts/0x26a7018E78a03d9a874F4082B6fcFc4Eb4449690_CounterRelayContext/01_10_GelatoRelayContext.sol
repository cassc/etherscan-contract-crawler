// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {GelatoRelayBase} from "./base/GelatoRelayBase.sol";
import {TokenUtils} from "./lib/TokenUtils.sol";

uint256 constant _FEE_COLLECTOR_START = 3 * 32;
uint256 constant _FEE_TOKEN_START = 2 * 32;
uint256 constant _FEE_START = 32;

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeCollectorRelayContext() pure returns (address) {
    return
        abi.decode(
            msg.data[msg.data.length - _FEE_COLLECTOR_START:],
            (address)
        );
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeTokenRelayContext() pure returns (address) {
    return abi.decode(msg.data[msg.data.length - _FEE_TOKEN_START:], (address));
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeRelayContext() pure returns (uint256) {
    return abi.decode(msg.data[msg.data.length - _FEE_START:], (uint256));
}

/**
 * @dev Context variant with feeCollector, feeToken and fee appended to msg.data
 * Expects calldata encoding:
 *   abi.encodePacked(bytes data, address feeCollectorAddress, address feeToken, uint256 fee)
 * Therefore, we're expecting 3 * 32bytes to be appended to normal msgData
 * 32bytes start offsets from calldatasize:
 *     feeCollector: - 32 * 3
 *     feeToken: - 32 * 2
 *     fee: - 32
 */
/// @dev Do not use with GelatoRelayFeeCollector - pick only one
abstract contract GelatoRelayContext is GelatoRelayBase {
    using TokenUtils for address;

    // DANGER! Only use with onlyGelatoRelay `_isGelatoRelay` before transferring
    function _transferRelayFee() internal {
        _getFeeToken().transfer(_getFeeCollector(), _getFee());
    }

    // DANGER! Only use with onlyGelatoRelay `_isGelatoRelay` before transferring
    function _transferRelayFeeCapped(uint256 _maxFee) internal {
        uint256 fee = _getFee();
        require(
            fee <= _maxFee,
            "GelatoRelayContext._transferRelayFeeCapped: maxFee"
        );
        _getFeeToken().transfer(_getFeeCollector(), fee);
    }

    // Do not confuse with OZ Context.sol _msgData()
    function __msgData() internal view returns (bytes calldata) {
        return
            _isGelatoRelay(msg.sender)
                ? msg.data[:msg.data.length - _FEE_COLLECTOR_START]
                : msg.data;
    }

    // Only use with GelatoRelayBase onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFeeCollector() internal pure returns (address) {
        return _getFeeCollectorRelayContext();
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFeeToken() internal pure returns (address) {
        return _getFeeTokenRelayContext();
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFee() internal pure returns (uint256) {
        return _getFeeRelayContext();
    }
}