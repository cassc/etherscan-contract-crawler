// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import '@mimic-fi/v3-tasks/contracts/interfaces/ITask.sol';

/**
 * @dev Off-chain signed withdrawer task interface
 */
interface IOffChainSignedWithdrawer is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The recipient is zero
     */
    error TaskRecipientZero();

    /**
     * @dev The signer is zero
     */
    error TaskSignerZero();

    /**
     * @dev The signed withdrawals URL is empty
     */
    error TaskSignedWithdrawalsUrlEmpty();

    /**
     * @dev The off-chain signed withdrawal was already executed
     */
    error TaskWithdrawalAlreadyExecuted(address token, uint256 amount, address recipient);

    /**
     * @dev The recovered signer is not the expected one
     */
    error TaskInvalidOffChainSignedWithdrawer(address actual, address expected);

    /**
     * @dev The next balance connector is not zero
     */
    error TaskNextConnectorNotZero(bytes32 id);

    /**
     * @dev Emitted every time the signer is set
     */
    event SignerSet(address indexed signer);

    /**
     * @dev Emitted every time the signed withdrawals URL is set
     */
    event SignedWithdrawalsUrlSet(string signedWithdrawalsUrl);

    /**
     * @dev Tells the address of the trusted signer
     */
    function signer() external view returns (address);

    /**
     * @dev Tells the URL containing the file with all the signed withdrawals
     */
    function signedWithdrawalsUrl() external view returns (string memory);

    /**
     * @dev Tells whether a withdrawal was executed
     */
    function wasExecuted(bytes32 id) external view returns (bool);

    /**
     * @dev Tells the ID for a withdrawal
     */
    function getWithdrawalId(address token, uint256 amount, address recipient) external view returns (bytes32);

    /**
     * @dev Sets the signer address
     * @param signer Address of the new signer to be set
     */
    function setSigner(address signer) external;

    /**
     * @dev Sets the signed withdrawals URL. Sender must be authorized.
     * @param newSignedWithdrawalsUrl URL containing the file with all the signed withdrawals
     */
    function setSignedWithdrawalsUrl(string memory newSignedWithdrawalsUrl) external;

    /**
     * @dev Executes the off-chain signed withdrawer task
     */
    function call(address token, uint256 amount, address recipient, bytes memory signature) external;
}