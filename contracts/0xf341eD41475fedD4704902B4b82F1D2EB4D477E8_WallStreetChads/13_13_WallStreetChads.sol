// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract WallStreetChads is ERC721Enumerable, Ownable {

    using Strings for uint256;

    uint256 public maxPerTransactionGeneralSale = 20;
    uint256 public maxPerUserPreSale = 1;
    uint256 public maxTokensGeneralSale = 10000; 
    uint256 public maxTokensPreSale = 500; 
    uint256 public reservedChads = 100; 
    uint256 public chadPrice = 0.08 ether;

    string public baseTokenURI;
    string public loadingURI;

    bool public generalSaleIsActive = false; 
    bool public preSaleIsActive = false;

    // Events
    event ValueReceived(address user, uint amount);

    constructor (string memory _name, string memory _symbol, string memory _loadingURI) ERC721(_name, _symbol) {
        setLoadingURI(_loadingURI);
        _safeMint(msg.sender, 0);
        _safeMint(msg.sender, 1);
        _safeMint(msg.sender, 2);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function pauseGeneralSale() public onlyOwner {
        generalSaleIsActive = false;
    }

    function unpauseGeneralSale() public onlyOwner {
        generalSaleIsActive = true;
    }

    function pausePreSale() public onlyOwner {
        preSaleIsActive = false;
    }

    function unpausePreSale() public onlyOwner {
        preSaleIsActive = true;
    }


    // Minting & Transfer Related Functions
    function mintWallStreetChadsGeneralSale(uint256 _amountToMint) public payable {

        uint256 supply = totalSupply();

        require(generalSaleIsActive, 'Wall Street Chads: Sale must be active to mint a Chad, patient you must be.');
        require(_amountToMint <= maxPerTransactionGeneralSale, 'Wall Street Chads: Can only mint 20 Chads at a time, you degenerate.');
        require((chadPrice * _amountToMint) <= msg.value, 'Wall Street Chads: Ether value sent is not correct, go raise some funds and come back to us.');
        require((supply + _amountToMint) <= (maxTokensGeneralSale - reservedChads), 'Wall Street Chads: Exceeds Wall Street Chads supply for sale.');

        for (uint256 i=0; i < _amountToMint; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex); 
        }

    }

    function mintWallStreetChadsPreSale() public payable {

        uint256 supply = totalSupply();
        uint256 numberOfWallStreetChadsCurrentlyOwned = balanceOf(msg.sender);

        // Potentially remove this if statement
        require(preSaleIsActive, 'Wall Street Chads: Pre-sale must be active to mint a Chad, patient you must be.');
        require(!generalSaleIsActive, 'Wall Street Chads: General sale must be inactive throughout the pre-sale.');
        require(numberOfWallStreetChadsCurrentlyOwned < maxPerUserPreSale, 'Wall Street Chads: You can only mint one WSC per address during the pre-sale.');
        require(chadPrice <= msg.value, 'Wall Street Chads: Ether value sent is not correct, go raise some funds and come back to us.');
        require((supply + 1) <= maxTokensPreSale, 'Wall Street Chads: Exceeds Wall Street Chads supply for pre-sale.');

        uint256 newTokenId = supply;

        _safeMint(msg.sender, newTokenId);

    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {

        require(_amount <= reservedChads, 'Wall Street Chads: Request exceeds reserved supply of our legends.');

        for (uint256 i=0; i < _amount; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(_to, mintIndex);
        }

        // Subtract the number
        reservedChads -= _amount;

    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {

        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory arrayOfTokenId = new uint256[](tokenCount);

        for (uint256 i=0; i < tokenCount; i++) {
            arrayOfTokenId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return arrayOfTokenId;

    }

    function numbersOfWallStreetChadsOwnedBy(address _owner) public view returns (uint256) {
        uint256 numberOfTokensOwned = balanceOf(_owner);
        return numberOfTokensOwned;
    }

    /*
    *
    * Price related functions
    * 
    */ 

    function getPrice() public view returns (uint256) {
        return chadPrice;
    }

    // @dev - In case ETH fluctuates heavily
    function setPrice(uint256 _newPrice) public onlyOwner {
        chadPrice = _newPrice;
    }

    /*
     *
     * URI related functions
     * 
     */

    function baseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseTokenURI = _baseURI;
    }

    function removeBaseURI() public onlyOwner {
        baseTokenURI = '';
    }

    function setLoadingURI(string memory _loadingURI) public onlyOwner {
        loadingURI = _loadingURI;
    }


    function tokenURI(uint256 _tokenId) public view override returns (string memory) {

        require(_exists(_tokenId), 'Wall Street Chads: Query made for nonexistent token.');

        string memory tokenURISuffix = '.json';
        string memory tokenIdentifier = string(abi.encodePacked(Strings.toString(_tokenId), tokenURISuffix));
        string memory base = baseURI();

        // If no base URI, then we actually have not revealed our ambitious Wall Street Chads to the world.
        if (bytes(base).length == 0) {
            return loadingURI;
        }

        // If both are set, concatenate the baseURI and tokenIdentifier (via abi.encodePakcked).
        if (bytes(tokenIdentifier).length > 0) {
            return string(abi.encodePacked(base, tokenIdentifier));
        }

        // If there is a baseURI but no tokenIdentifier, concatenate the tokenId to the baseURI
        return string(abi.encodePacked(base, Strings.toString(_tokenId)));

    }

    receive() external payable { 
        emit ValueReceived(msg.sender, msg.value);
    } 

    fallback() external payable { }

}