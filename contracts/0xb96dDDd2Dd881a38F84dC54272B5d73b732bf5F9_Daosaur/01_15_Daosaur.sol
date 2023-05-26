// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @custom:security-contact [email protected]
contract Daosaur is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    bool public isPublicMintEnabled = false;
    bool public isWhitelistMintEnabled = false;
    bool public isRevealed = false;
    string public unrevealedUri =
        "ipfs://QmegjuBW29miRNTjaQNQR7xMgtnGwgHYy1LnhvmGyphoVx/";
    string private _baseURIextended;
    uint256 public maxSupply = 3333;
    bytes32 public whitelistRoot;
    bytes32 public freeMintRoot;
    uint256 public maxPerWallet = 5;
    uint256 public maxPerWalletWhitelist = 3;
    uint256 public maxPerWalletFreeMint = 1;
    uint256 public whitelistMintPrice = 8 ether / 100; // 0.08 ether
    uint256 public mintPrice = 1 ether / 10; // 0.1 ether

    constructor() ERC721("Daosaur", "DAOSAUR") {}

    function setWhitelistRoot(bytes32 whitelistSignature) external onlyOwner {
        whitelistRoot = whitelistSignature;
    }

    function setFreeMintRoot(bytes32 freeMintSignature) external onlyOwner {
        freeMintRoot = freeMintSignature;
    }

    function setIsWhitelistMintEnabled(bool enabled) external onlyOwner {
        isWhitelistMintEnabled = enabled;
    }

    function setIsPublicMintEnabled(bool enabled) external onlyOwner {
        isWhitelistMintEnabled = false;
        isPublicMintEnabled = enabled;
    }

    function setIsRevealed(bool enabled) external onlyOwner {
        isRevealed = enabled;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _baseURIextended = uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(bytes32[] calldata proof, uint256 quantity)
        public
        payable
    {
        if (isWhitelistMintEnabled) {
            bool isFreeMintWallet = MerkleProof.verify(
                proof,
                freeMintRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
            if (isFreeMintWallet) {
                require(
                    balanceOf(msg.sender) + quantity <= maxPerWalletFreeMint,
                    "You cannot mint more than 1 Daosaurs via freemint"
                );
            } else {
                require(
                    MerkleProof.verify(
                        proof,
                        whitelistRoot,
                        keccak256(abi.encodePacked(msg.sender))
                    ),
                    "Public mint not available yet, only whitelisted wallets can mint at the moment."
                );
                require(
                    msg.value >= (quantity * whitelistMintPrice),
                    "Not enough ETH sent"
                );
                require(
                    balanceOf(msg.sender) + quantity <= maxPerWalletWhitelist,
                    "You cannot mint more than 3 Daosaurs during the Whitelisted sell"
                );
            }
        } else {
            require(isPublicMintEnabled, "Public mint not available yet.");
            require(msg.value >= (quantity * mintPrice), "Not enough ETH sent");
            require(
                balanceOf(msg.sender) + quantity <= maxPerWallet,
                "You cannot mint more than 5 Daosaurs during the public sell"
            );
        }
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Sold out.");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function partner(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(_tokenIdCounter.current() <= maxSupply, "Sold out.");
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            safeTransferFrom(msg.sender, addresses[i], tokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!isRevealed) {
            return unrevealedUri;
        }

        string memory baseURI = _baseURIextended;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}