// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RabbitNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for string;
    // Storage Game Variables
    address t1 = 0xCD9375D40FF8cF1F34796b364870207a0FD88dEc; // Nanel.eth
    address t2 = 0xC020A0e0AccaA31dc432FFAa4726fAc2bcf3186D; // Marranico.eth
    address t3 = 0xDF074233A1078ddad6dD2BB4a988842B7d1Fa2ea;
    //NFT Variables
    uint256 public RabbitPrice = 30000000000000000; // 0.03 ETH
    uint public constant maxRabbitPurchase = 20;
    uint256 public MAX_Rabbits = 100;
    bool public saleIsActive = false;  
    string _baseTokenURI =
        "https://super-nft-collections.s3.eu-west-1.amazonaws.com/ChinaRabbit/json/";
    bool public forceIsActive = false;

    mapping(address => uint256[]) private owners;

    constructor() ERC721("Tu Rabbit", "TR") {
         for (uint i = 0; i < 17; i++) {
            uint mintIndex = totalSupply();
            owners[msg.sender].push(mintIndex);
            if (totalSupply() < MAX_Rabbits) {
                _safeMint(t3, mintIndex);
            }
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipForce() public onlyOwner {
        forceIsActive = !forceIsActive;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        RabbitPrice = _newPrice;
    }

    function getPrice() public view returns (uint) {
        return RabbitPrice;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 funds = address(this).balance.div(2);
        require(payable(t1).send(funds));
        require(payable(t2).send(funds));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function mintRabbits(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Rabbits");
        require(
            numberOfTokens <= maxRabbitPurchase,
            "Maximum mints per transaction exceeded"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_Rabbits,
            "Purchase would exceed max supply of Rabbits"
        );
        require(
            RabbitPrice.mul(numberOfTokens) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            owners[msg.sender].push(mintIndex);
            if (totalSupply() < MAX_Rabbits) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        uint256[] memory fromTokens = owners[from];

        if (from != address(0)) { // Avoiding minting
            unchecked {
                for (uint256 i = 0; i < fromTokens.length; i++) {
                    if (fromTokens[i] == tokenId) {
                        uint256 element = fromTokens[fromTokens.length - 1];
                        fromTokens[fromTokens.length - 1] = fromTokens[i];
                        fromTokens[i] = element;
                        delete fromTokens[fromTokens.length - 1];
                    }
                }

                owners[to].push(tokenId);
            }
        }
    }

    function getMyNFTS() public view returns (uint256[] memory) {
        return owners[msg.sender];
    }

    function getNFTSFor(address addr) public view returns (uint256[] memory) {
        return owners[addr];
    }

    function jediForce() public {
        require(saleIsActive, "Sale must be active to mint Rabbits");
        require(
            forceIsActive,
            "Only authorized wallets can use this jedi function"
        );
        require(
            totalSupply().add(1) <= MAX_Rabbits,
            "Purchase would exceed max supply of Rabbits"
        );
        uint mintIndex = totalSupply();
        if (totalSupply() < MAX_Rabbits) {
            _safeMint(msg.sender, mintIndex);
        }
    }
}