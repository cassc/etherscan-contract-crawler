//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/// @title SignedAllowance with claimedBitMap
/// @author Simon Fremaux (@dievardump) / Adam Fuller (@azf20)
/// Original: https://github.com/dievardump/signed-minting/blob/main/contracts/SignedAllowance.sol
contract SignedAllowance {
    using ECDSA for bytes32;

    // event to track claims
    event Claimed(uint256 index, address account);

    // This is a packed array of booleans to track claims
    mapping(uint256 => uint256) public claimedBitMap;

    /// @notice Helper to check if an index has been claimed
    /// @param index the index
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// @notice Internal function to set an index as claimed
    /// @param index the index
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    // address used to sign the allowances
    address private _allowancesSigner;

    /// @notice Helper to know allowancesSigner address
    /// @return the allowance signer address
    function allowancesSigner() public view virtual returns (address) {
        return _allowancesSigner;
    }

    /// @notice Helper that creates the message that signer needs to sign to allow a mint
    ///         this is usually also used when creating the allowances, to ensure "message"
    ///         is the same
    /// @param account the account to allow
    /// @param index the index
    /// @return the message to sign
    function createMessage(address account, uint256 index)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(account, index, address(this)));
    }

    /// @notice Helper that creates a list of messages that signer needs to sign to allow mintings
    /// @param accounts the accounts to allow
    /// @param indexes the corresponding indexes
    /// @return messages the messages to sign
    function createMessages(address[] memory accounts, uint256[] memory indexes)
        external
        view
        returns (bytes32[] memory messages)
    {
        require(accounts.length == indexes.length, '!LENGTH_MISMATCH!');
        messages = new bytes32[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            messages[i] = createMessage(accounts[i], indexes[i]);
        }
    }

    /// @notice This function verifies that the current request is valid
    /// @dev It ensures that _allowancesSigner signed a message containing (account, index, address(this))
    ///      and that this message was not already used
    /// @param account the account the allowance is associated to
    /// @param index the index associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @return the message to mark as used
    function validateSignature(
        address account,
        uint256 index,
        bytes memory signature
    ) public view returns (bytes32) {
        return
            _validateSignature(account, index, signature, allowancesSigner());
    }

    /// @dev It ensures that signer signed a message containing (account, index, address(this))
    ///      and that this message was not already used
    /// @param account the account the allowance is associated to
    /// @param index the index associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @param signer the signer
    /// @return the message to mark as used
    function _validateSignature(
        address account,
        uint256 index,
        bytes memory signature,
        address signer
    ) internal view returns (bytes32) {
        bytes32 message = createMessage(account, index)
            .toEthSignedMessageHash();

        // verifies that the sha3(account, index, address(this)) has been signed by signer
        require(message.recover(signature) == signer, '!INVALID_SIGNATURE!');

        // verifies that the allowances was not already used
        require(isClaimed(index) == false, '!ALREADY_USED!');

        return message;
    }

    /// @notice internal function that verifies an allowance and marks it as used
    ///         this function throws if signature is wrong or this index for this user has already been used
    /// @param index the index
    /// @param signature the signature by the allowance wallet
    function _useAllowance(
        uint256 index,
        bytes memory signature
    ) internal {
        validateSignature(msg.sender, index, signature);
        _setClaimed(index);
    }

    /// @notice Allows to change the allowance signer. This can be used to revoke any signed allowance not already used
    /// @param newSigner the new signer address
    function _setAllowancesSigner(address newSigner) internal {
        _allowancesSigner = newSigner;
    }
}