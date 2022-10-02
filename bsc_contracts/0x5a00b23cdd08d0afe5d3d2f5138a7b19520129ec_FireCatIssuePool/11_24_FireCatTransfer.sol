// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

contract FireCatTransfer is ReentrancyGuardUpgradeable {
    event Withdraw(address sender_, address token_, uint256 amount_);

     /**
     * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
     * @param token_ address.
     * @param from_ address.
     * @param amount_ uint.
     * @return transfer_num.
     */
    function doTransferIn(address token_, address from_, uint amount_) internal returns (uint) {
        uint balanceBefore = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transferFrom(from_, address(this), amount_);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");
        uint balanceAfter = IERC20(token_).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;  // underflow already checked above, just subtract
    }

    /**
     * @dev Performs a transfer out, ideally returning an explanatory error code upon failure tather than reverting.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     * @param token_ address.
     * @param to_ address.
     * @param amount_ uint.
     * @return transfer_num.
     */
    function doTransferOut(address token_, address to_, uint256 amount_) internal returns (uint) {
        uint balanceBefore = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(to_, amount_);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");
        uint balanceAfter = IERC20(token_).balanceOf(address(this));
        require(balanceAfter <= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceBefore - balanceAfter;  // underflow already checked above, just subtract
    }

    /**
    * @notice The interface of IERC20 token withdrawn.
    * @dev Call doTransferOut, transfer token to owner.
    * @param token address.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdraw(address token, address to, uint256 amount) internal returns (uint) {
        require(token != address(0), "TOKEN_CANT_BE_ZERO");
        require(IERC20(token).balanceOf(address(this)) >= amount, "NOT_ENOUGH_TOKEN");
        IERC20(token).approve(to, amount);
        uint256 actualSubAmount = doTransferOut(token, to, amount);
        emit Withdraw(to, token, actualSubAmount);
        return actualSubAmount;
    }

    function burn(address token_, address sender_, uint256 amount_) internal returns (uint) {
        require(token_ != address(0), "TOKEN_CANT_BE_ZERO");
        uint balanceBefore = IERC20(token_).balanceOf(sender_);
        IERC20(token_).transferFrom(sender_, address(1), amount_);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }

        require(success, "TOKEN_TRANSFER_IN_FAILED");
        uint balanceAfter = IERC20(token_).balanceOf(sender_);
        require(balanceAfter <= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceBefore - balanceAfter;  // underflow already checked abov
    }

}