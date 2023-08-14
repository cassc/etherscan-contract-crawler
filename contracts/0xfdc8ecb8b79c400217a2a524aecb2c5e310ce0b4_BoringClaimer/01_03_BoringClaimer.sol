import "lib/solady/src/auth/Ownable.sol";
import {SignatureCheckerLib} from "lib/solady/src/utils/SignatureCheckerLib.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface BoringSecurity {
  function safeTransferFrom(address, address, uint256, uint256, bytes memory) external;

  function balanceOf(address, uint256) external view returns (uint256);
}

error InvalidSignature();
error InvalidToken();
error AlreadyClaimed();
error Not101Holder();

contract BoringClaimer is Ownable {
    address private constant BORING_SECURITY_VAULT = 0x52C45Bab6d0827F44a973899666D9Cd18Fd90bCF;
    BoringSecurity private immutable boringSecurity;

    address private _signer;
    mapping(uint256 => bytes32) roots;
    mapping(address => mapping(uint256 => bool)) public claimed;

    constructor(address signer_) {
        boringSecurity = BoringSecurity(0x0164fB48891b891e748244B8Ae931F2318b0c25B);
        _initializeOwner(tx.origin);
        _signer = signer_;
    }

    function claim(uint256 tokenId, bytes calldata signature) external {
        if (tokenId != 101 && tokenId != 102) revert InvalidToken();
        if (claimed[msg.sender][tokenId]) revert AlreadyClaimed();
        if (tokenId == 102 && boringSecurity.balanceOf(msg.sender, 101) == 0) revert Not101Holder();

        bytes32 hashedMessage = keccak256(abi.encodePacked(msg.sender, tokenId));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashedMessage = keccak256(abi.encodePacked(prefix, hashedMessage));

        if (!SignatureCheckerLib.isValidSignatureNowCalldata(_signer, prefixedHashedMessage, signature)) revert InvalidSignature();

        claimed[msg.sender][tokenId] = true;

        boringSecurity.safeTransferFrom(BORING_SECURITY_VAULT, msg.sender, tokenId, 1, "");
    }

    function setSigner(address _newSigner) external onlyOwner {
        _signer = _newSigner;
    }
}