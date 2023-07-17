/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success);
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     */
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.call(data);
        return verifyCallResult(success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata
    ) private pure returns (bytes memory) {
        if (success) return returndata;
        else revert();
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param encodedParams prepare staticcall; encoded function selector and parameters
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise.
     * Note that this function returns the actual result of the query: it does not
     * `revert`, It is up to the caller to decide what to do in these cases.
     */
    function _staticcallUnchecked(
        bytes memory encodedParams,
        address account
    ) private view returns (bool) {
        /**
         * perform static call
         * `staticcall(g, a, in, insize, out, outsize)` identical to `call(g, a, 0, in, insize, out, outsize)` but do not allow state modifications.
         * call contract at address a with input mem[in…(in+insize)) providing g gas and v wei and output area mem[out…(out+outsize)) returning 0 on error (eg. out of gas) and 1 on success
         * - https://docs.soliditylang.org/en/latest/yul.html#yul-call-return-area
         * encoded params example: `bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);`
         *
         */
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(
                30000, // gas
                account, // address
                add(encodedParams, 0x20), // encoded encodedParams input and offset indicating at which bytes index the string starts. Here 0x20 (in hex) = 32 (in decimals). add(encodedParams, 32) it moves the pointer to the raw encodedParams skipping the size field.
                mload(encodedParams), // input size. mload(encodedParams) read 32 bytes pointed by encodedParams (it returns the length of encodedParams)
                0x00, // output
                0x20 // output size
            )
            // Setting output and output size to 0 is due to historical reason. In early EVM versions you had to know the output size in advance, it was a limiting factor for some kind of operations (proxy contracts) so in the Bizantium fork new opcodes were introduced ReturnDataSize and ReturnDataCopy. This allow the caller to determine the output size after the call (ReturnDataSize) and allowing copying to memory (ReturnDataCopy).
            returnSize := returndatasize() // how much memory do we need to allocate for the response
            returnValue := mload(0x00)
        }
        return success && returnSize >= 0x20 && returnValue > 0;
    }
}