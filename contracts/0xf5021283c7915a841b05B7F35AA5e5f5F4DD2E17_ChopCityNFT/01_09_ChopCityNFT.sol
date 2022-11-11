// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./FlippableOperatorFilterer721.sol";
import "hardhat/console.sol";

contract ChopCityNFT is ERC721A, FlippableOperatorFilterer721, Ownable {
    uint128 public MAX_SUPPLY = 3030;
    uint128 public MAX_PER_TX = 10;
    uint256 public MINT_PRICE = 0.01 ether;
    uint256 public blockDataForReveal;
    uint256 public tokenIdShift;

    string public PROVENANCE_HASH;
    string public REVEALED_URI;
    string public UNREVEALED_URI;
    string public OLD_URI;
    bool revealed;
    bool isMintActive;

    constructor(string memory _uri, string memory _provenanceHash)
        ERC721A("The Battle Of Chop City", "TBOCC")
    {
        UNREVEALED_URI = _uri;
        PROVENANCE_HASH = _provenanceHash;
    }

    function mintWojak(uint8 quantity) public payable {
        require(isMintActive, "Mint isn't active");
        require(tx.origin == msg.sender, "Caller is contract");
        require(quantity <= MAX_PER_TX, "Exceeding max mint per tx");
        require(msg.value == quantity * MINT_PRICE, "ETH amount is incorrect");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(msg.sender, quantity);
    }

    function reveal(string memory _revealURI) public onlyOwner {
        require(!revealed, "Revealed already");
        REVEALED_URI = _revealURI;

        blockDataForReveal =
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
            200;
        tokenIdShift = (uint256(
            blockhash(block.number - blockDataForReveal - 1)
        ) % totalSupply());
        revealed = true;
    }

    function flipMintStatus() public onlyOwner {
        isMintActive = !isMintActive;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed) {
            uint256 shiftedTokenId = (_tokenId + tokenIdShift) % totalSupply();
            return
                string(
                    abi.encodePacked(REVEALED_URI, _toString(shiftedTokenId))
                );
        } else {
            return
                string(abi.encodePacked(UNREVEALED_URI, _toString(_tokenId)));
        }
    }

    // will be used in order to set artwork for the losing tokens, and for future reset as well
    function setBaseURI(string memory _uri) public onlyOwner {
        require(revealed, "Can't modify the URI before reveal");
        OLD_URI = REVEALED_URI;
        REVEALED_URI = _uri;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function mintStatus() public view returns (bool) {
        return isMintActive;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function flipOtherMarketplacesBlockingState() public onlyOwner {
        flipBlockingState();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyIfOtherMarketplacesAllowed(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyIfOtherMarketplacesAllowed(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyIfOtherMarketplacesAllowed(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}