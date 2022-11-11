// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract AkaChanByAnata is ERC721, Pausable, Ownable {
    // ERC-2981: NFT Royalty Standard
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint256 public immutable maxSupply;
    uint256 public immutable pausableCutoffTime;

    bool public tokenBaseURILocked;
    bool public mintingLocked;
    string public tokenBaseURI;
    uint256 public totalSupply;
    address public royaltyReceipientAddress;
    uint256 public royaltyPercentageBasisPoints;

    error TokenBaseURILocked();
    error PausableCutoffTimePassed();
    error InputLengthMismatch();
    error MaxSupplyExceeded();
    error InvalidTokenId(uint256 tokenId);
    error NotSupported();
    error MintingLocked();

    constructor(
        uint256 pausableCutoffTime_,
        uint256 maxSupply_,
        string memory tokenBaseURI_,
        address royaltyReceipientAddress_,
        uint256 royaltyPercentageBasisPoints_
    ) ERC721("Aka-Chan by Anata", "AKACHAN") {
        pausableCutoffTime = pausableCutoffTime_;
        maxSupply = maxSupply_;
        tokenBaseURI = tokenBaseURI_;
        royaltyReceipientAddress = royaltyReceipientAddress_;
        royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
    }

    function pause() external onlyOwner {
        if (block.timestamp > pausableCutoffTime) {
            revert PausableCutoffTimePassed();
        }
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function lockTokenBaseURI() external onlyOwner {
        if (tokenBaseURILocked) {
            revert TokenBaseURILocked();
        }
        tokenBaseURILocked = true;
    }

    function lockMinting() external onlyOwner {
        if (mintingLocked) {
            revert MintingLocked();
        }
        mintingLocked = true;
    }

    function setTokenBaseURI(string calldata tokenBaseURI_) external onlyOwner {
        if (tokenBaseURILocked) {
            revert TokenBaseURILocked();
        }
        tokenBaseURI = tokenBaseURI_;
    }

    function setRoyaltyPercentageBasisPoints(
        uint256 royaltyPercentageBasisPoints_
    ) external onlyOwner {
        royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
    }

    function setRoyaltyReceipientAddress(
        address payable royaltyReceipientAddress_
    ) external onlyOwner {
        royaltyReceipientAddress = royaltyReceipientAddress_;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function batchMint(
        address[] calldata recipients_,
        uint256[] calldata tokenIds_
    ) external onlyOwner {
        if (mintingLocked) {
            revert MintingLocked();
        }

        if (recipients_.length != tokenIds_.length) {
            revert InputLengthMismatch();
        }

        if (totalSupply + recipients_.length > maxSupply) {
            revert MaxSupplyExceeded();
        }

        uint256 tmpTotalSupply = totalSupply;

        for (uint256 i = 0; i < recipients_.length; i++) {
            // Tokens are 1-indexed.
            // Since tokens can be minted out of order, check upper and lower bounds.
            if (tokenIds_[i] < 1 || tokenIds_[i] > maxSupply) {
                revert InvalidTokenId(tokenIds_[i]);
            }
            _safeMint(recipients_[i], tokenIds_[i]);
            tmpTotalSupply += 1;
        }

        totalSupply = tmpTotalSupply;
    }

    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 royalty = (salePrice_ * royaltyPercentageBasisPoints) / 10000;
        return (royaltyReceipientAddress, royalty);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // reverts if receiving any eth directly
    receive() external payable {
        revert NotSupported();
    }

    // fallback function
    fallback() external {
        revert NotSupported();
    }
}