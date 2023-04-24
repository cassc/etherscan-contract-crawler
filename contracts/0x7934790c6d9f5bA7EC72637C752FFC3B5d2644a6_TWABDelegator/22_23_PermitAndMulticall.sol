// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../Constants.sol";

/**
 * @notice Allows a user to permit token spend and then call multiple functions
 *         on a contract.
 */
contract PermitAndMulticall is Initializable, Constants {
    /**
     * @notice Secp256k1 signature values.
     * @param deadline Timestamp at which the signature expires
     * @param v `v` portion of the signature
     * @param r `r` portion of the signature
     * @param s `s` portion of the signature
     */
    struct Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @notice Allows a user to call multiple functions on the same contract.
     *         Useful for EOA who want to batch transactions.
     * @dev Obtained from @openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol
     * @param _data An array of encoded function calls. The calls must be
     *              abi-encoded calls to this contract.
     * @return The results from each function call
     */
    function _multicall(
        bytes[] calldata _data
    ) internal virtual returns (bytes[] memory) {
        bytes[] memory results = new bytes[](_data.length);

        for (uint256 i; i < _data.length; ++i) {
            results[i] = _functionDelegateCall(address(this), _data[i]);
        }

        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     * @dev Obtained from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol"
     * _Available since v3.4._
     */
    function _functionDelegateCall(
        address target,
        bytes memory data
    ) private returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);

        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @notice Allow a user to approve an ERC20 token and run various calls in
     *         one transaction.
     * @param _permitToken Address of the ERC20 token
     * @param _amount Amount of tickets to approve
     * @param _permitSignature Permit signature
     * @param _data Datas to call with `functionDelegateCall`
     */
    function _permitAndMulticall(
        IERC20PermitUpgradeable _permitToken,
        uint256 _amount,
        Signature calldata _permitSignature,
        bytes[] calldata _data
    ) internal {
        _permitToken.permit(
            msg.sender,
            address(this),
            _amount,
            _permitSignature.deadline,
            _permitSignature.v,
            _permitSignature.r,
            _permitSignature.s
        );

        _multicall(_data);
    }

    uint256[45] private __gap;
}