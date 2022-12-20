// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface OATMintable {
    function mintBatch(address recipient, uint256[] calldata ids) external;
}


contract SignatureOATMinter is Ownable {

    OATMintable private immutable OAT;
    mapping(address => bool) public isValidSigner;
    mapping(address => bool) public isValidSender;
    bool public validateOrigin = true; 


    constructor(address oat_) {
        OAT = OATMintable(oat_);
    }

    function mintBatch(address recipient, uint256[] calldata ids, bytes memory signature) public virtual {
        require(msg.sender == owner() || isValidSender[msg.sender], "Invalid sender");
        require(!validateOrigin || msg.sender == owner() || recipient == tx.origin, "Can only mint your your own token");

        bytes memory data = abi.encode(recipient, ids);
        bytes32 hash = ECDSA.toEthSignedMessageHash(data);

        address signer = ECDSA.recover(
            hash,
            signature
        );
        require(isValidSigner[signer], "Invalid signature");

        OAT.mintBatch(recipient, ids);
    }

    function setValidSigner(address account, bool isSigner_) external onlyOwner {
        isValidSigner[account] = isSigner_;
    }

    function setValidSender(address account, bool isSender_) external onlyOwner {
        isValidSender[account] = isSender_;
    }

    function setValidateOrigin(bool validateOrigin_) external onlyOwner {
        validateOrigin = validateOrigin_;
    }
}