// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {IERC20} from "../../interfaces/IERC20.sol";
import {IEIP20NonStandard} from "../../interfaces/IEIP20NonStandard.sol";
import {Deployments} from "../global/Deployments.sol";

library TokenUtils {
    error ERC20Error();

    function tokenBalance(address token) internal view returns (uint256) {
        return
            token == Deployments.ETH_ADDRESS
                ? address(this).balance
                : IERC20(token).balanceOf(address(this));
    }

    function checkApprove(IERC20 token, address spender, uint256 amount) internal {
        if (address(token) == address(0)) return;

        IEIP20NonStandard(address(token)).approve(spender, 0);
        _checkReturnCode();            
        if (amount > 0) {
            IEIP20NonStandard(address(token)).approve(spender, amount);
            _checkReturnCode();            
        }
    }

    function checkRevoke(IERC20 token, address spender) internal {
        if (address(token) == address(0)) return;

        IEIP20NonStandard(address(token)).approve(spender, 0);
        _checkReturnCode();
    }

    function checkTransfer(IERC20 token, address receiver, uint256 amount) internal {
        IEIP20NonStandard(address(token)).transfer(receiver, amount);
        _checkReturnCode();
    }

    // Supports checking return codes on non-standard ERC20 contracts
    function _checkReturnCode() private pure {
        bool success;
        uint256[1] memory result;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := 1 // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(result, 0, 32)
                    success := mload(result) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }

        if (!success) revert ERC20Error();
    }
}