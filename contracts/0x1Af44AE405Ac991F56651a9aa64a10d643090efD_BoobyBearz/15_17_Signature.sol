pragma solidity ^0.8.4;

import "./ECDSA.sol";

error ZeroAddress();

contract Signature {
    /* SIGNATURE */
    using ECDSA for bytes32;
    address public signerAddress;

    constructor(address _signerAddress) {
        signerAddress = _signerAddress;
    }

    function verifySignature(
        bytes memory signature,
        uint256 mintType
    ) internal view returns (bool) {
        return
            signerAddress ==
            keccak256(abi.encodePacked(msg.sender, mintType, address(this)))
                .toEthSignedMessageHash()
                .recover(signature);
    }

    function setSignerAddress(address _signerAddress) public virtual {
        if (_signerAddress == address(0)) revert ZeroAddress();
        signerAddress = _signerAddress;
    }
}