/*
╭━━━┳╮╱╱╱╱╭╮╱╱╱╱╱╱╱╱╭╮╱╱╱╱╱╱╱╱╭╮
┃╭━╮┃┃╱╱╱╭╯╰╮╱╱╱╱╱╱╭╯╰╮╱╱╱╱╱╱╱┃┃
┃┃╱┃┃╰━┳━┻╮╭╋━┳━━┳━┻╮╭╋┳━━┳━╮╱┃╰━┳╮╱╭╮
┃╰━╯┃╭╮┃━━┫┃┃╭┫╭╮┃╭━┫┃┣┫╭╮┃╭╮╮┃╭╮┃┃╱┃┃
┃╭━╮┃╰╯┣━━┃╰┫┃┃╭╮┃╰━┫╰┫┃╰╯┃┃┃┃┃╰╯┃╰━╯┃
╰╯╱╰┻━━┻━━┻━┻╯╰╯╰┻━━┻━┻┻━━┻╯╰╯╰━━┻━╮╭╯
╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╰━━╯
╭━━━┳╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭╮
┃╭━╮┃┃╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃┃
┃┃╱┃┃┃╭┳━━┳╮╱╭┳━━╮╱╱┃┣╮╭┳━╮
┃╰━╯┃╰╯┫╭╮┃┃╱┃┃╭╮┃╭╮┃┃┃┃┃╭╮╮
┃╭━╮┃╭╮┫╭╮┃╰━╯┃╰╯┃┃╰╯┃╰╯┃┃┃┃
╰╯╱╰┻╯╰┻╯╰┻━╮╭┻━━╯╰━━┻━━┻╯╰╯
╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╰━━╯
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract AbstractionByAkayoJun is ERC721A, Ownable {
    using Strings for uint256;
    string public baseURI = "ipfs://bafybeiebkhbwsdv3kdjh62hil4kf7c3hqwx432jjibld236dmikiewqecu/";
    uint256 public constant TOTAL_ABSTRACTS = 333;
    uint256 public constant MAX_ABSTRACT_MINT = 3;
    uint256 public ABSTRACT_PRICE = 0.009 ether;
    
    bool public isSaleActive = false;
    mapping(address => uint256) private mintedPerWallet;


    constructor() ERC721A("Abstraction by Akayo Jun", "Abstraction") {
        _safeMint(owner(), 1);
    }

    mapping(address => uint) public addressAbstracts;
    mapping(address => bool) public addressHaveFreeAbstract;


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 abstracts) public payable {
        require(isSaleActive, "Sale has not started yet");
        require(abstracts <= MAX_ABSTRACT_MINT, "Only 4 abstractions in one hand");
        require(addressAbstracts[_msgSender()] < MAX_ABSTRACT_MINT, "You aldredy get abstractions");
        require(totalSupply() + abstracts <= TOTAL_ABSTRACTS, "Abstractions ran out");
        if(!addressHaveFreeAbstract[_msgSender()]) {
            require(msg.value >= ( abstracts - 1 ) * ABSTRACT_PRICE, "Not enough ETH");
            addressAbstracts[_msgSender()] += abstracts;
            addressHaveFreeAbstract[_msgSender()] = true;
            _safeMint(msg.sender, abstracts);
        } else {
            require(msg.value >= abstracts * ABSTRACT_PRICE, "Not enough ETH");
            addressAbstracts[_msgSender()] += abstracts;
            _safeMint(msg.sender, abstracts);
        }
    }


    function ownerMint(uint256 _count) external onlyOwner {
        require(totalSupply() + _count <= TOTAL_ABSTRACTS, "Abstracts ran out");
        _safeMint(msg.sender, _count);
    }
      function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "NFT does not exist");
        string memory baseURI_ = _baseURI();
        return
            bytes(baseURI_).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI_,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        ABSTRACT_PRICE = _price;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}