// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./TokenHelper.sol";
import "./TokenChecker.sol";
import "./NativeClaimer.sol";
import "./NativeReturnMods.sol";
import "./Swap.sol";
import "./IUseProtocol.sol";
import "./IGasVendor.sol";

/**
 * @dev Vendor-based gas payment protocol
 *
 * - Bound to one {IGasVendor}-compatible contract
 * - Gets fee details from the vendor, validates amount, and sends it to the fee collector
 * - Accepts one input and one dummy output (see explanation below)
 * - The caller must match specified account
 * - Chain ID must match current chain
 * - No extra args
 *
 * @dev The 'V2' introduction:
 *
 * There is an issue w/ some wallets that makes typed data sign fail if a value
 * that is being signed contains an empty array of structures. So happened that
 * the only case for us is the 'GasVendorProtocol' with its empty 'outs'. This
 * issue makes all swaps via such a wallet pretty much impossible since gas
 * protocol is presented in each of them.
 *
 * While we are patiently waiting for them to fix the reported issue, we
 * introduce 'GasVendorProtocolV2'. It requires exactly one dummy output with
 * no meaning other than mitigate the issue.
 */
contract GasVendorProtocolV2 is IUseProtocol, NativeReturnMods {
    address private immutable _vendor;

    constructor(address vendor_) {
        require(vendor_ != address(0), "GP: zero vendor");
        _vendor = vendor_;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain == block.chainid, "GP: wrong chain id");
        require(params_.account == msg.sender, "GP: wrong sender account");
        require(params_.args.length == 0, "GP: unexpected args");

        require(params_.ins.length == 1, "GP: wrong number of ins");
        require(params_.inAmounts.length == 1, "GP: wrong number of in amounts");
        require(params_.outs.length == 1, "GP: wrong number of outs");
        require(params_.outs[0].token == address(0), "GP: wrong dummy out token");
        require(params_.outs[0].minAmount == 0, "GP: wrong dummy out min amount");
        require(params_.outs[0].maxAmount == 0, "GP: wrong dummy out max amount");

        NativeClaimer.State memory nativeClaimer;
        _maybePayGas(params_.ins[0], params_.inAmounts[0], params_.msgSender, params_.msgData, nativeClaimer);
    }

    function _maybePayGas(
        TokenCheck calldata input_,
        uint256 inputAmount_,
        address msgSender,
        bytes calldata msgData,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) {
        if (!_gasFeeEnabled(input_)) {
            return;
        }

        GasFee memory gasFee = IGasVendor(_vendor).getGasFee(msgSender, msgData);
        if (!_shouldPayGasFee(gasFee)) {
            return;
        }

        require(gasFee.amount <= inputAmount_, "GP: gas amount exceeds available");
        TokenChecker.checkMinMaxToken(input_, gasFee.amount, gasFee.token);

        TokenHelper.transferToThis(gasFee.token, msg.sender, gasFee.amount, nativeClaimer_);
        TokenHelper.transferFromThis(gasFee.token, gasFee.collector, gasFee.amount);
    }

    function _gasFeeEnabled(TokenCheck calldata gasOut_) private pure returns (bool) {
        return gasOut_.maxAmount > 0;
    }

    function _shouldPayGasFee(GasFee memory gasFee_) private pure returns (bool) {
        return gasFee_.collector != address(0);
    }
}