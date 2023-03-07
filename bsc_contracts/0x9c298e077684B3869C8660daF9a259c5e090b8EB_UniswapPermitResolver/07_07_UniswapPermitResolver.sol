// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {TokenHelper} from "../asset/TokenHelper.sol";

struct TokenPermissions { address token; uint256 amount; }
struct PermitTransferFrom { TokenPermissions permitted; uint256 nonce; uint256 deadline; }
struct SignatureTransferDetails { address to; uint256 requestedAmount; }

interface Permit2 {
    function permitTransferFrom(PermitTransferFrom memory permit, SignatureTransferDetails calldata transferDetails, address owner, bytes calldata signature) external;
}

contract UniswapPermitResolver {
    address constant private PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public immutable xSwap;

    constructor(address xSwap_) { xSwap = xSwap_; }

    function resolvePermit(address token_, address from_, uint256 amount_, uint256 deadline_, bytes calldata signature_) external {
        require(msg.sender == xSwap, "UP: caller must be xSwap");
        uint256 nonce = uint256(keccak256(abi.encodePacked(token_, from_, amount_, deadline_, address(this))));
        Permit2(PERMIT2).permitTransferFrom(PermitTransferFrom({permitted: TokenPermissions({token: token_, amount: amount_}), nonce: nonce, deadline: deadline_}), SignatureTransferDetails({to: address(this), requestedAmount: amount_}), from_, signature_);
        TokenHelper.revokeOfThis(token_, msg.sender);
        TokenHelper.approveOfThis(token_, msg.sender, amount_);
    }
}