// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {SafeERC20, IERC20Permit} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SignatureDecomposer} from "./SignatureDecomposer.sol";

contract PermitResolver is SignatureDecomposer {
    function resolvePermit(address token_, address from_, uint256 amount_, uint256 deadline_, bytes calldata signature_) external {
        SafeERC20.safePermit(IERC20Permit(token_), from_, msg.sender, amount_, deadline_, v(signature_), r(signature_), s(signature_));
    }
}