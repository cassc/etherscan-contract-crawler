// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../AMTManager/IAMTManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AMTManager is AccessControl {
    using ECDSA for bytes32;
    bytes32 public constant ADMIN = "ADMIN";

    address private signer;
    IAMTManager public amtManager;
    uint256 public nonce = 0;

    event ConvertedAMT(address indexed to, uint256 value, uint256 nonce);

    modifier isValidSignature (address _to, uint256 _value, bytes calldata _signature) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                _to,
                _value,
                nonce
            )
        ).toEthSignedMessageHash().recover(_signature);
        require(recoveredAddress == signer, "Invalid Signature");
        _;
    }

    constructor() {
        _grantRole(ADMIN, msg.sender);
    }
    function convertWithSignature(address _to, uint256 _value, bytes calldata _signature) external
        isValidSignature(_to, _value, _signature)
    {
        amtManager.add(_to, _value);
        emit ConvertedAMT(_to, _value, nonce);
        nonce++;
    }
    function setSigner(address _value) external onlyRole(ADMIN) {
        signer = _value;
    }
    function setAmtManager(address value) external onlyRole(ADMIN) {
        amtManager = IAMTManager(value);
    }

}