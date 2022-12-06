// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SantaClubNFT is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    string private _baseTokenURI;
    string public baseExtension = ".json";
    uint256 public constant MAX_SUPPLY = 10000;

    // 50 NFTs are reserved for the community giveaway
    // The team does not receive any NFTs
    uint256 public constant NUM_OF_NFTS_FOR_GIVEAWAY = 50;
    uint256 public constant MINT_PRICE = 0.1 ether; // 0.1 BNB

    bool public isPublicSaleActive = false;

    event EnablePublicSale();

    receive() external payable {}

    constructor() ERC721("SantaClubNFT", "SANTA") {
        _transferOwnership(msg.sender);

        for (uint256 i = 1; i <= NUM_OF_NFTS_FOR_GIVEAWAY; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "SantaClubNFT: invalid token ID");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function mint(uint256 quantity) external payable nonReentrant {
        uint256 numOfMintedTokens = totalSupply();

        require(isPublicSaleActive, "SantaClubNFT: public sale not opened");
        require(
            msg.value >= (MINT_PRICE * quantity),
            "SantaClubNFT: not enough BNB"
        );
        require(
            quantity > 0,
            "SantaClubNFT: quantity should be greater than 0"
        );
        require(
            numOfMintedTokens + quantity <= MAX_SUPPLY,
            "SantaClubNFT: not enough tokens left"
        );

        for (uint256 i = 1; i <= quantity; i++) {
            _safeMint(msg.sender, numOfMintedTokens + i);
        }
    }

    function getOwnershipData(address holder)
        external
        view
        returns (uint256[] memory)
    {
        uint256 holderTokenCount = balanceOf(holder);
        uint256[] memory tokenIds = new uint256[](holderTokenCount);
        for (uint256 i; i < holderTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(holder, i);
        }
        return tokenIds;
    }

    function enablePublicSale() external onlyOwner {
        isPublicSaleActive = true;

        emit EnablePublicSale();
    }

    function setBaseExtension(string memory newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = newBaseExtension;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "SantaClubNFT: transfer failed");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}