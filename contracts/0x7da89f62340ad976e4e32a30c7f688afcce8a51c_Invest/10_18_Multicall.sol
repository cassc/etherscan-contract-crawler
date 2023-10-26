// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Handles multicall function
 * @author Pino development team
 */
contract Multicall {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private _status;

    /**
     * @notice Thrown when the nonETHReuse modifier is called twice in the multicall
     */
    error EtherReuseGuardCall();

    /**
     * @dev Prevents a caller from calling multiple functions that work with ETH in a transaction
     */
    modifier nonETHReuse() {
        _nonReuseBefore();
        _;
    }

    /**
     * @notice Sets status to NOT_ENTERED
     */
    constructor() payable {
        _status = NOT_ENTERED;
    }

    /**
     * @notice Multiple calls on proxy functions
     * @param _calldata An array of calldata that is called one by one
     * @dev The other param is for the referral program of the Pino server
     */
    function multicall(bytes[] calldata _calldata, uint256) external payable {
        // Unlock ether locker just in case if it was locked before
        unlockETHReuse();

        // Loop through each calldata and execute them
        for (uint256 i = 0; i < _calldata.length;) {
            (bool success, bytes memory result) = address(this).delegatecall(_calldata[i]);

            // Check if the call was successful or not
            if (!success) {
                // Next 7 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();

                assembly {
                    result := add(result, 0x04)
                }

                revert(abi.decode(result, (string)));
            }

            // Increment variable i more efficiently
            unchecked {
                ++i;
            }
        }

        /*
         * To ensure proper execution, unlock reusability for future use.
         * In some cases, the caller might invoke a function with the 'nonETHReuse'
         * modifier directly, bypassing the 'unlockETHReuse' step at the beginning of the
         * multicall. This would render the function unusable if not unlocked here.
         */
        unlockETHReuse();
    }

    /**
     * @notice Unlocks the reentrancy
     * @dev Should be used before and after all the calls
     */
    function unlockETHReuse() internal {
        _status = NOT_ENTERED;
    }

    function _nonReuseBefore() private {
        // On the first call to nonETHReuse, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert EtherReuseGuardCall();
        }

        // Any calls to nonETHReuse after this point will fail
        _status = ENTERED;
    }
}