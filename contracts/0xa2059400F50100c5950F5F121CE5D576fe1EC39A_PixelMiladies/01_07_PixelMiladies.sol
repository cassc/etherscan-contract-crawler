//SPDX-License-Identifier: MIT

//Gas optimized version of Doyler contract
// converted <= var  to  < var + 1 
pragma solidity ^0.8.4;

import "../erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PixelMiladies is Ownable, ERC721A {
    uint256 public constant MAX_SUPPLY = 6969;

    uint256 public publicPrice = 0.002 ether;

    uint256 public constant PUBLIC_MINT_LIMIT_TXN = 10;
	uint256 public constant PUBLIC_MINT_LIMIT = 300;

    string public baseURI = 'ipfs://QmYgiKKs3Y5XQBdtngjiHH6BZyiGzeicMrrMuMDf1KFdv5/';

    bool public freeSale = true;
    bool public publicSale = false;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("Pixel Miladies", "pxmld") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function freeMint(uint256 quantity)
        external
        payable
        mintCompliance(quantity)
    {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");
        require(quantity < 6, "Only 5 free");

        uint256 newSupply = totalSupply() + quantity;

        require(newSupply < 3435, "Not enough free supply");

        require(!userMintedFree[msg.sender], "max free limit");

        userMintedFree[msg.sender] = true;

        if (newSupply == 3434) {
            freeSale = false;
            publicSale = true;
        }

        _safeMint(msg.sender, quantity);
    }

    function priceCheck(uint256 price) private {
        if (msg.value < price) {
            revert("Not enough ETH");
        }
    }

    function publicMint(uint256 quantity)
        external
        payable
        mintCompliance(quantity)
    {
        require(publicSale, "Public sale inactive");
        require(quantity < PUBLIC_MINT_LIMIT_TXN + 1, "Quantity too high");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];

        require(currMints + quantity < PUBLIC_MINT_LIMIT + 1, "maxmint limit");

        priceCheck(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < MAX_SUPPLY + 1
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
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

        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        baseURI = _contractURI;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }

    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    address private constant walletA = 0x4253Ef2F48A704796ECb77F863CFDCFECe20714b;
    address private constant walletB = 0x639526B935670021fFBF2d967F33c9A1Bb0be89A;

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

		Address.sendValue(payable(walletA), (balance * 50) / 100);
		Address.sendValue(payable(walletB), (balance * 50) / 100);
    }

    modifier mintCompliance(uint256 quantity) {
        require(
            totalSupply() + quantity < MAX_SUPPLY + 1,
            "Not enough mints left"
        );
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}