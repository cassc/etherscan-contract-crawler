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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import '@mimic-fi/v3-tasks/contracts/Task.sol';
import './interfaces/IOffChainSignedWithdrawer.sol';

/**
 * @title Off-chain signed withdrawer
 * @dev Task that offers a withdraw functionality authorized by a trusted external account
 */
contract OffChainSignedWithdrawer is Task, IOffChainSignedWithdrawer {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('OFF_CHAIN_SIGNED_WITHDRAWER');

    // Address signing the withdraw information
    address public override signer;

    // URL containing the file with all the signed withdrawals
    string public override signedWithdrawalsUrl;

    // Whether a specific withdrawal was executed or not
    mapping (bytes32 => bool) public override wasExecuted;

    /**
     * @dev Initializes the off-chain signed withdrawer
     * @param taskConfig Task config
     * @param initialSigner Address of the new signer to be set
     * @param initialSignedWithdrawalsUrl URL containing the file with all the signed withdrawals
     */
    function initialize(TaskConfig memory taskConfig, address initialSigner, string memory initialSignedWithdrawalsUrl)
        external
        initializer
    {
        __OffChainSignedWithdrawer_init(taskConfig, initialSigner, initialSignedWithdrawalsUrl);
    }

    /**
     * @dev Initializes the off-chain signed withdrawer. It does call upper contracts initializers.
     * @param taskConfig Task config
     * @param initialSigner Address of the new signer to be set
     * @param initialSignedWithdrawalsUrl URL containing the file with all the signed withdrawals
     */
    function __OffChainSignedWithdrawer_init(
        TaskConfig memory taskConfig,
        address initialSigner,
        string memory initialSignedWithdrawalsUrl
    ) internal onlyInitializing {
        __Task_init(taskConfig);
        __OffChainSignedWithdrawer_init_unchained(taskConfig, initialSigner, initialSignedWithdrawalsUrl);
    }

    /**
     * @dev Initializes the off-chain signed withdrawer. It does not call upper contracts initializers.
     * @param initialSigner Address of the new signer to be set
     * @param initialSignedWithdrawalsUrl URL containing the file with all the signed withdrawals
     */
    function __OffChainSignedWithdrawer_init_unchained(
        TaskConfig memory,
        address initialSigner,
        string memory initialSignedWithdrawalsUrl
    ) internal onlyInitializing {
        _setSigner(initialSigner);
        _setSignedWithdrawalsUrl(initialSignedWithdrawalsUrl);
    }

    /**
     * @dev Tells the ID for a withdrawal
     */
    function getWithdrawalId(address token, uint256 amount, address recipient) public view override returns (bytes32) {
        return keccak256(abi.encodePacked(block.chainid, address(this), token, amount, recipient));
    }

    /**
     * @dev Sets the signer address. Sender must be authorized.
     * @param newSigner Address of the new signer to be set
     */
    function setSigner(address newSigner) external override authP(authParams(newSigner)) {
        _setSigner(newSigner);
    }

    /**
     * @dev Sets the signed withdrawals URL. Sender must be authorized.
     * @param newSignedWithdrawalsUrl URL containing the file with all the signed withdrawals
     */
    function setSignedWithdrawalsUrl(string memory newSignedWithdrawalsUrl) external override auth {
        _setSignedWithdrawalsUrl(newSignedWithdrawalsUrl);
    }

    /**
     * @dev Executes the Withdrawer
     */
    function call(address token, uint256 amount, address recipient, bytes memory signature)
        external
        override
        authP(authParams(token, amount))
    {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeOffChainSignedWithdrawer(token, amount, recipient, signature);
        ISmartVault(smartVault).withdraw(token, recipient, amount);
        _afterOffChainSignedWithdrawer(token, amount, recipient, signature);
    }

    /**
     * @dev Before off-chain signed withdrawer hook
     */
    function _beforeOffChainSignedWithdrawer(address token, uint256 amount, address recipient, bytes memory signature)
        internal
        virtual
    {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
        if (recipient == address(0)) revert TaskRecipientZero();

        bytes32 withdrawalId = getWithdrawalId(token, amount, recipient);
        if (wasExecuted[withdrawalId]) revert TaskWithdrawalAlreadyExecuted(token, amount, recipient);

        address recoveredSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(withdrawalId), signature);
        if (signer != recoveredSigner) revert TaskInvalidOffChainSignedWithdrawer(recoveredSigner, signer);
    }

    /**
     * @dev After off-chain signed withdrawer hook
     */
    function _afterOffChainSignedWithdrawer(
        address token,
        uint256 amount,
        address recipient,
        bytes memory /* signature */
    ) internal virtual {
        wasExecuted[getWithdrawalId(token, amount, recipient)] = true;
        _afterTask(token, amount);
    }

    /**
     * @dev Sets the signer address
     * @param newSigner Address of the new signer to be set
     */
    function _setSigner(address newSigner) internal {
        if (newSigner == address(0)) revert TaskSignerZero();
        signer = newSigner;
        emit SignerSet(newSigner);
    }

    /**
     * @dev Sets the signed withdrawals URL
     * @param newSignedWithdrawalsUrl URL containing the file with all the signed withdrawals
     */
    function _setSignedWithdrawalsUrl(string memory newSignedWithdrawalsUrl) internal {
        if (bytes(newSignedWithdrawalsUrl).length == 0) revert TaskSignedWithdrawalsUrlEmpty();
        signedWithdrawalsUrl = newSignedWithdrawalsUrl;
        emit SignedWithdrawalsUrlSet(newSignedWithdrawalsUrl);
    }

    /**
     * @dev Sets the balance connectors. Next balance connector must be unset.
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal virtual override {
        if (next != bytes32(0)) revert TaskNextConnectorNotZero(next);
        super._setBalanceConnectors(previous, next);
    }
}