// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BARCBoxSet is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 62200;
    bool public isActive = false;
    uint256 public mintPrice = 6.22 ether;
    string public _baseTokenURI;
    uint256 public nftsPerBox = 622;
    uint256 public royalty = 0;

    constructor(string memory baseURI) ERC721A("BARC BOX SET", "BARCBS") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen() {
        require(totalSupply() < MAX_SUPPLY, "Sale has ended.");
        _;
    }

    modifier onlyAuthorized() {
        require(owner() == msg.sender);
        _;
    }

    function setPrice(uint256 _price) public onlyAuthorized {
        mintPrice = _price;
    }

    function setNftsPerBox(uint256 _count) public onlyAuthorized {
        nftsPerBox = _count;
    }

    function toggleSale() public onlyAuthorized {
        isActive = !isActive;
    }

    function setBaseURI(string memory baseURI) public onlyAuthorized {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getCurrentPrice() public view returns (uint256) {
        return mintPrice;
    }

    function getNftsPerBox() public view returns (uint256) {
        return nftsPerBox;
    }

    function setRoyalty(uint256 _royalty) public onlyAuthorized {
        royalty = _royalty;
    }

    function getRoyalty() public view returns (uint256) {
        return royalty;
    }

    function batchAirdrop(
        uint256 _count,
        address[] calldata addresses
    ) external onlyAuthorized {
        uint256 supply = totalSupply();

        require(supply < MAX_SUPPLY, "Total supply spent.");
        require(
            supply + _count * nftsPerBox <= MAX_SUPPLY,
            "Total supply exceeded."
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add a null address");
            _safeMint(addresses[i], _count * nftsPerBox);
        }
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token Id Non-existent");
        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(
                        _baseURI(),
                        Strings.toString(_tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _count) public payable saleIsOpen {
        uint256 mintIndex = totalSupply();

        if (msg.sender != owner()) {
            require(isActive, "Sale is not active currently.");
            require(
                mintIndex + _count * nftsPerBox <= MAX_SUPPLY,
                "Total supply exceeded."
            );
            require(
                msg.value >= mintPrice * _count,
                "Insufficient ETH amount sent."
            );

            payable(owner()).transfer(mintPrice * _count);
        }

        _safeMint(msg.sender, _count * nftsPerBox);
    }
}