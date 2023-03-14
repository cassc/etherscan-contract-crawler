// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Artmo is ERC721URIStorage, Ownable {
    using ECDSA for bytes32;

    uint96 public currentTokenId;

    address public approvedSigner;

    mapping(bytes32 key => bool used) private _usedKeys;

    event Mint(address user, uint256 tokenId, bytes32 key);

    error InvalidCaller();
    error InvalidSigner();
    error KeyUsed();

    constructor(address _approvedSigner) ERC721("Artmo", "ARTMO") {
        approvedSigner = _approvedSigner;
    }

    function mint(string calldata uri, bytes32 key, bytes calldata signature) external {
        // Revert if the caller is a contract
        if (msg.sender != tx.origin) revert InvalidCaller();

        // Revert if the key has been used already
        if (_usedKeys[key]) revert KeyUsed();

        // Hash the key, URI, caller's address and the contract's address
        bytes32 hash = keccak256(abi.encodePacked(uri, key, msg.sender, address(this)));

        // Recover the signer's address from the signature
        address recoveredSigner = hash.toEthSignedMessageHash().recover(signature);

        // Revert if the recovered address does not match the approved signer
        if (recoveredSigner != approvedSigner) revert InvalidSigner();

        // Mark the key as used
        _usedKeys[key] = true;

        uint256 tokenId;
        unchecked {
            // Increment the current token ID by 1
            tokenId = ++currentTokenId;
        }

        // Mint the token to the caller
        _mint(msg.sender, tokenId);

        // Set the URI for the minted token
        _setTokenURI(tokenId, uri);

        emit Mint(msg.sender, tokenId, key);
    }

    function setApprovedSigner(address _approvedSigner) external onlyOwner {
        approvedSigner = _approvedSigner;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }
}