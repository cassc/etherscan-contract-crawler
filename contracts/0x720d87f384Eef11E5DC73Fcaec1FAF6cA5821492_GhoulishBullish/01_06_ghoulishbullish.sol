// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GhoulishBullish is ERC721A, Ownable {
    
    uint256 public maxSupply = 4444;
    uint256 public mintPrice = 0.002 ether;
    uint256 public maxMintPerTx = 10;
    uint256 public maxFreeMintPerWallet = 1;

    bool public mintStarted = false;

    using Strings for uint256;
    string public baseURI;
    mapping(address => uint256) private _mintedPerWallet;
    mapping(address => bool) private isFreeClaimed_;

    constructor(string memory initBaseURI) ERC721A("GhoulishBullish", "GB") {
        baseURI = initBaseURI;
    }

    function mintPublic(uint256 count) external payable {
        require(mintStarted, "Minting is not live yet.");

        uint256 cost = (msg.value == 0 && !isFreeClaimed_[msg.sender]) ? 0 : mintPrice;

        require(_mintedPerWallet[msg.sender] + count <= maxMintPerTx, "Max per wallet reached.");
        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count <= maxSupply, "Sold out!");
        
        require(count <= maxMintPerTx, "Max per txn reached.");

        if (cost == 0) {
            isFreeClaimed_[msg.sender] = true;
        } else {
            _mintedPerWallet[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function mintGoolish(address _to, uint256 count) external payable {
        require(mintStarted, "Minting is not live yet.");
        uint256 cost = (msg.value == 0 && !isFreeClaimed_[msg.sender]) ? 0 : mintPrice;
        require(_mintedPerWallet[msg.sender] + count <= maxMintPerTx, "Max per wallet reached.");
        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count <= maxSupply, "Sold out!");
        require(count <= maxMintPerTx, "Max per txn reached.");

         if (cost == 0) {
            isFreeClaimed_[msg.sender] = true;
        } else {
            _mintedPerWallet[msg.sender] += count;
        }
        
        _safeMint(_to, count);

    }

    function mintedPerWallet(address _address) external view returns(uint256) {
        return _mintedPerWallet[_address];
    }

    function isFreeClaimed(address _address) external view returns(bool) {
        return isFreeClaimed_[_address];
    }


    function airdrop(address to, uint256 qty) external onlyOwner {
        _safeMint(to, qty);
    }
    
    function airdropBatch(address[] calldata listedAirdrop ,uint256 qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function saleStateToggle() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function allowlistMint(uint256 _number) external onlyOwner {
        _safeMint(_msgSender(), _number);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

 
}