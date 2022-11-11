//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Gobbies is Ownable, ERC721A {
    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public publicPrice = 0.01 ether;

    uint256 public constant PUBLIC_MINT_LIMIT_TXN = 5;
    uint256 public constant PUBLIC_MINT_LIMIT = 5;

    bool public saleIsActive = false;

    string public revealedURI = "ipfs://-/";

    string public unrevealedURI = "https://gobbies.net/unrevealed/";

    bool public revealed = false;

    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("Gobbies", "gobs") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function priceCheck(uint256 price) private {
        if (msg.value < price) {
            revert("Not enough ETH");
        }
    }

    function mint(uint256 quantity) external payable mintCompliance(quantity) {
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");
        require(saleIsActive == true, "Sale not active");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];

        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "maxmint limit");

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
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
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
        if (revealed == false) {
            return
                string(
                    abi.encodePacked(
                        unrevealedURI,
                        "x.json"
                    )
                );
        }
        return
            string(
                abi.encodePacked(
                    revealedURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return revealedURI;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setRevealedURI(string memory _contractURI) public onlyOwner {
        revealedURI = _contractURI;
    }

    function setUnrevealedURI(string memory _urcontractURI) public onlyOwner {
        unrevealedURI = _urcontractURI;
    }

    function setSaleState(bool _state) public onlyOwner {
        saleIsActive = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    modifier mintCompliance(uint256 quantity) {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough mints left"
        );
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}