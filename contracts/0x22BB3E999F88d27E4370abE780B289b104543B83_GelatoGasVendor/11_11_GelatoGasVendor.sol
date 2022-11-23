// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Context} from "../../../lib/Context.sol";

import {TokenHelper} from "../../../core/asset/TokenHelper.sol";

import {IGasVendor, GasFee} from "../IGasVendor.sol";

/**
 * @dev Gelato Ops contract interface.
 *
 * See https://github.com/gelatodigital/ops/blob/master/contracts/Ops.sol.
 */
interface IGelatoOps {
    function gelato() external view returns (address payable);

    function getFeeDetails() external view returns (uint256 fee, address feeToken);
}

struct GelatoGasVendorConstructorParams {
    /**
     * @dev Gelato Ops contract address. Depends on network contract is deployed to, see:
     * https://docs.gelato.network/developer-products/gelato-ops-smart-contract-automation-hub/contract-addresses.
     * Zero address disables Gelato Ops support by the contract.
     */
    address ops;
    /**
     * @dev Gelato Relay contract address. 0xaBcC9b596420A9E9172FD5938620E265a0f9Df92 for all main networks.
     * Zero address disables Gelato Relay support by the contract.
     */
    address relay;
}

/**
 * @dev Contract logic responsible for Gelato-based contract execution automation.
 * Currently two automation scenarios are supported by the implementation:
 * - via Gelato Ops (https://docs.gelato.network/developer-products/gelato-ops-smart-contract-automation-hub)
 * - via Gelato Relay (https://docs.gelato.network/developer-products/gelato-relay-sdk)
 *
 * The relay implementation is based on original Gelato contracts adapted to xSwap specific.
 * Related files (https://github.com/gelatodigital/relay-context-contracts/blob/e39a479f3ca75dc707a29c827c26230c8d1a2f2f):
 * - contracts/GelatoRelayContext.sol
 * - contracts/lib/TokenUtils.sol
 * - contracts/constants/GelatoRelay.sol
 * - contracts/constants/Tokens.sol
 */
contract GelatoGasVendor is IGasVendor {
    address private immutable _ops;
    address private immutable _relay;
    address payable private _opsGelato;

    address private constant GELATO_NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant RELAY_DATA_FEE_COLLECTOR_START = 3 * 32;
    uint256 private constant RELAY_DATA_FEE_TOKEN_START = 2 * 32;
    uint256 private constant RELAY_DATA_FEE_START = 32;

    constructor(GelatoGasVendorConstructorParams memory params_) {
        _ops = params_.ops;
        if (params_.ops != address(0)) {
            try IGelatoOps(params_.ops).gelato() returns (address payable opsGelato_) {
                require(opsGelato_ != address(0), "GV: zero gelato address from ops");
                _opsGelato = opsGelato_;
            } catch {
                revert("GV: gelato from ops fail");
            }
        }
        _relay = params_.relay;
    }

    /**
     * @dev See {IGasVendor-getGasFee}.
     */
    function getGasFee(address msgSender_, bytes calldata msgData_) external view returns (GasFee memory fee) {
        if (_isInOps()) {
            return _getOpsGasFee();
        }

        if (_isInRelay(msgSender_)) {
            return _getRelayGasFee(msgData_);
        }
    }

    /**
     * @dev Ops region
     */

    function _isInOps() private view returns (bool) {
        if (!_isOpsSupported()) {
            return false;
        }

        if (!_opsFeePresented()) {
            return false;
        }

        return true;
    }

    function _isOpsSupported() private view returns (bool) {
        return _ops != address(0);
    }

    function _getOpsGasFee() private view returns (GasFee memory fee) {
        (uint256 opsFee, address opsFeeToken) = _getOpsFeeDetails();
        fee.amount = opsFee;
        fee.token = _convertGelatoToken(opsFeeToken);
        fee.collector = _opsGelato;
    }

    function _getOpsFeeDetails() private view returns (uint256 fee, address feeToken) {
        (fee, feeToken) = IGelatoOps(_ops).getFeeDetails();
    }

    function _opsFeePresented() private view returns (bool) {
        (uint256 fee, address feeToken) = _getOpsFeeDetails();
        return feeToken != address(0) && fee > 0;
    }

    /**
     * @dev Relay region
     */

    function _isInRelay(address msgSender_) private view returns (bool) {
        if (!_isRelaySupported()) {
            return false;
        }

        if (msgSender_ != _relay) {
            return false;
        }

        return true;
    }

    function _isRelaySupported() private view returns (bool) {
        return _relay != address(0);
    }

    function _getRelayGasFee(bytes calldata msgData_) private pure returns (GasFee memory fee) {
        fee.amount = _getRelayFee(msgData_);
        fee.token = _convertGelatoToken(_getRelayFeeToken(msgData_));
        fee.collector = _getRelayFeeCollector(msgData_);
    }

    function _getRelayFeeCollector(bytes calldata msgData_) private pure returns (address feeCollector) {
        feeCollector = abi.decode(msgData_[msgData_.length - RELAY_DATA_FEE_COLLECTOR_START:], (address));
    }

    function _getRelayFeeToken(bytes calldata msgData_) private pure returns (address feeToken) {
        feeToken = abi.decode(msgData_[msgData_.length - RELAY_DATA_FEE_TOKEN_START:], (address));
    }

    function _getRelayFee(bytes calldata msgData_) private pure returns (uint256 fee) {
        fee = abi.decode(msgData_[msgData_.length - RELAY_DATA_FEE_START:], (uint256));
    }

    /**
     * @dev Misc region
     */

    function _convertGelatoToken(address gelatoToken_) private pure returns (address) {
        return gelatoToken_ == GELATO_NATIVE_TOKEN ? TokenHelper.NATIVE_TOKEN : gelatoToken_;
    }
}