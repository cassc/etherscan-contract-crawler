// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract YatSignatures {
    address private _authorizedSigner;
    address private _owner;
    mapping (address => uint256) private _nonce;

    modifier onlyContractOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    constructor (address authorizedSigner) {
        _owner = msg.sender;
        _authorizedSigner = authorizedSigner;
    }

    function getNonce(address clientAddress) public view returns (uint256) {
        require(clientAddress != address(0), "Null address cannot sign");
        return _nonce[clientAddress];
    }

    function getSigner() public view returns (address) {
        return _authorizedSigner;
    }

    function setAuthorizedSigner(address newSigner) external onlyContractOwner {
        require(newSigner != address(0), "Cannot set signer to null address");
        _authorizedSigner = newSigner;
    }

    function _signaturePrefix() internal pure virtual returns (string memory) {
        return "yat";
    }

    /**
    * Calculate the signature challenge as a combination of
    *  - the prefix
    *  - the nonce for the destination address
    *  - an arbitrary string message
    *  - the destination account
    *  - the expiry time
    *
    * This can be overridden if the challenge needs to be customised, but it's not recommended
    */
    function _calculateChallenge(string memory message, address account, uint256 expiry) internal virtual returns (bytes32) {
        string memory prefix = _signaturePrefix();
        uint256 nonce = getNonce(account);
        // Immediately invalidate the signature for further use by incrementing the nonce.
        _nonce[account] += 1;
        bytes32 hash = keccak256(abi.encodePacked(prefix, nonce, message, account, expiry));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /*
    * You can override this function to customise how to validate the message content. For example, the address
    * might have to match the "to" field in a mint, etc.
    * By default, we check that the expiry time is ahead of the current block timestamp
    */
    function validateMessageContent(string memory message, address account, uint256 expiry) internal virtual {
        require(block.timestamp < expiry, "Signature has expired");
        require(bytes(message).length > 0, "Message cannot be empty");
        require(account != address(0), "Address cannot be zero");
    }

    function _verifySignature(string memory message, address account, uint256 expiry, bytes memory signature) internal returns (bool) {
        validateMessageContent(message, account, expiry);
        bytes32 challenge = _calculateChallenge(message, account, expiry);
        return _recoverSigner(challenge, signature) == _authorizedSigner;
    }

    function _splitSignature(bytes memory _signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_signature.length == 65, "Signature is not 65 bytes");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function _recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        address signer = ecrecover(ethSignedMessageHash, v, r, s);
        require(signer != address(0), "ECDSA: Invalid signature");
        return signer;
    }
}