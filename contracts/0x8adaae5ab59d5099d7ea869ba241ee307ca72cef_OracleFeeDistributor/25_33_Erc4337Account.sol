// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../erc4337/IAccount.sol";
import "../erc4337/IEntryPointStakeManager.sol";
import "../erc4337/UserOperation.sol";
import "../access/IOwnableWithOperator.sol";

/// @notice passed address should be a valid ERC-4337 entryPoint
/// @param _passedAddress passed address
error Erc4337Account__NotEntryPoint(address _passedAddress);

/// @notice data length should be at least 4 byte to be a function signature
error Erc4337Account__DataTooShort();

/// @notice only withdraw function is allowed to be called via ERC-4337 UserOperation
error Erc4337Account__OnlyWithdrawIsAllowed();

/// @notice only client, owner, and operator are allowed to withdraw from EntryPoint
error Erc4337Account__NotAllowedToWithdrawFromEntryPoint();

/// @title gasless withdraw for FeeDistributors via ERC-4337
abstract contract Erc4337Account is IAccount, IOwnableWithOperator {
    using ECDSA for bytes32;

    /// @notice withdraw without arguments
    bytes4 private constant defaultWithdrawSelector = bytes4(keccak256("withdraw()"));

    /// @notice Singleton ERC-4337 entryPoint 0.6.0 used by this account
    address payable constant entryPoint = payable(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    /// @inheritdoc IAccount
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override returns (uint256 validationData) {
        if (msg.sender != entryPoint) {
            revert Erc4337Account__NotEntryPoint(msg.sender);
        }

        validationData = _validateSignature(userOp, userOpHash);

        bytes4 selector = _getFunctionSelector(userOp.callData);
        if (selector != withdrawSelector()) {
            revert Erc4337Account__OnlyWithdrawIsAllowed();
        }

        _payPrefund(missingAccountFunds);
    }

    /// @notice Withdraw this contract's balance from EntryPoint back to this contract
    function withdrawFromEntryPoint() external {
        if (!(
            msg.sender == owner() || msg.sender == operator() || msg.sender == client()
        )) {
            revert Erc4337Account__NotAllowedToWithdrawFromEntryPoint();
        }

        uint256 balance = IEntryPointStakeManager(entryPoint).balanceOf(address(this));
        IEntryPointStakeManager(entryPoint).withdrawTo(payable(address(this)), balance);
    }

    /// @notice Validates the signature of a user operation.
    /// @param _userOp the operation that is about to be executed.
    /// @param _userOpHash hash of the user's request data. can be used as the basis for signature.
    /// @return validationData 0 for valid signature, 1 to mark signature failure
    function _validateSignature(
        UserOperation calldata _userOp,
        bytes32 _userOpHash
    ) private view returns (uint256 validationData)
    {
        bytes32 hash = _userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(_userOp.signature);

        if (
            signer == operator() || signer == client()
        ) {
            validationData = 0;
        } else {
            validationData = 1;
        }
    }

    /// @notice Returns function selector (first 4 bytes of data)
    /// @param _data calldata (encoded signature + arguments)
    /// @return functionSelector function selector
    function _getFunctionSelector(bytes calldata _data) private pure returns (bytes4 functionSelector) {
        if (_data.length < 4) {
            revert Erc4337Account__DataTooShort();
        }
        return bytes4(_data[:4]);
    }

    /// @notice sends to the entrypoint (msg.sender) the missing funds for this transaction.
    /// @param _missingAccountFunds the minimum value this method should send the entrypoint.
    /// this value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
    function _payPrefund(uint256 _missingAccountFunds) private {
        if (_missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{ value: _missingAccountFunds, gas: type(uint256).max }("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }

    /// @notice Returns the client address
    /// @return address client address
    function client() public view virtual returns (address);

    /// @inheritdoc IOwnable
    function owner() public view virtual returns (address);

    /// @inheritdoc IOwnableWithOperator
    function operator() public view virtual returns (address);

    /// @notice withdraw function selector
    /// @dev since withdraw function in derived contracts can have arguments, its
    /// signature can vary and can be overridden in derived contracts
    /// @return bytes4 withdraw function selector
    function withdrawSelector() public pure virtual returns (bytes4) {
        return defaultWithdrawSelector;
    }
}