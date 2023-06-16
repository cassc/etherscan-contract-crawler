// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TipsyTiger is ERC721Enumerable, Ownable {

    using Strings for uint256; 

    string public PROVENANCE = "";
    string _baseTokenURI;
    string public baseExtension = '.json';
    uint256 public reserved = 100;
    uint256 public publicSalePrice = 0.05 ether;
    uint256 public presalePrice = 0.04 ether;
    uint256 public presaleSupply = 1000;
    uint256 public createTime = block.timestamp;
    uint256 public maxSupply = 8000;

    mapping(address => uint256) public presaleMintedAmount;

    bool public publicSaleOpen = false;
    bool public presaleOpen = false;

    constructor(string memory baseURI) ERC721("TipsyTiger Club", "TIPSY")  {
        setBaseURI(baseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // public
    function mintTiger(uint256 num) public payable {
        require( publicSaleOpen, "Public sale is not open" );
        require( num < 21, "You can only mint a maximum of 20 Tigers" );
        uint256 supply = totalSupply();
        require( supply + num <= maxSupply - 100, "Sold out!" );
        require( msg.value >= publicSalePrice * num, "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function mintPresale(uint256 _mintNum) public payable {
        require(presaleOpen, 'Presale not open');
        require(_mintNum < 6, 'Exceeded presale limit');
        require(_mintNum < 6 - presaleMintedAmount[msg.sender], 'Exceeded limit of 5 per address');
        uint256 supply = totalSupply();
        require(supply + _mintNum <= presaleSupply, 'Sold out!');
        require(msg.value >= presalePrice * _mintNum, 'Ether sent is not correct');

        for (uint256 i; i < _mintNum; i++) {
            _safeMint(msg.sender, supply + i);
        }

        presaleMintedAmount[msg.sender] = presaleMintedAmount[msg.sender] + _mintNum;
    }


    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string (
            abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        ) : '';
    }
    
    // only owner
    function setPublicPrice(uint256 _newPublic) public onlyOwner() {
        publicSalePrice = _newPublic;
    }

    function setPresalePrice(uint256 _newPresale) public onlyOwner() {
        presalePrice = _newPresale;
    }

    function setPresaleSupply(uint256 _newSupply) public onlyOwner() {
        presaleSupply = _newSupply;
    }

    // reserve some tigers aside
    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= reserved, "Exceeds reserved Tiger supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        reserved -= _amount;
    }

    // set provenance once it's calculated
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        PROVENANCE = _provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setBaseExtension(string memory _newExtension) public onlyOwner() {
        baseExtension = _newExtension;
    }

    // burn token
    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }

    function togglePublicSale() public onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function togglePresale() public onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function sendBalance() public onlyOwner {
        require(block.timestamp >= createTime + 60 hours, "< 60 hours after deployment");
        uint256 balance = address(this).balance;
        uint256 supply = totalSupply();

        if (supply > 7999) {
            payable(0x6d4108368f838A035134e9F7f6a45FEA5d16b544).transfer(balance * 30 / 1000);
            payable(msg.sender).transfer(balance * 970 / 1000);
        } else {
            payable(0x6d4108368f838A035134e9F7f6a45FEA5d16b544).transfer(balance * 20 / 1000);
            payable(msg.sender).transfer(balance * 980 / 1000);
        }   
    }

}