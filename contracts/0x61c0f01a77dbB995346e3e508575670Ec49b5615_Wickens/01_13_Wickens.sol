// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Wickens is ERC721Enumerable, Ownable {  
    using Address for address;
    using Strings for uint256;
    
    // Starting and stopping sale and presale
    bool public saleActive = false;
    bool public presaleActive = false;

    // Reserved for the team, customs, giveaways, collabs and so on.
    uint256 public reserved = 100;

    // Price of each token
    uint256 public price = 0.05 ether;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 6666;

    uint256 public constant MAX_PER_ADDRESS_PRESALE = 3;
    uint256 public constant MAX_PER_ADDRESS_PUBLIC = 10;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    // whitelist for presale
    mapping(address => bool) public whitelisted;

    string public baseExtension = ".json";
    bool public revealed = false;
    string public notRevealedUri;

    // Team addresses for withdrawals   
    address public Shannon = 0xbBB59bce1FDB930be2cfEE29F9a467269d5B8761;
    address public Ryan = 0x77b06916B10A32e89810D3CD6A04744722B49915;
    address public Steve = 0x27853Ea1152048Fa174E2E64a724AdbB70D92452;
    address public Treasury = 0x80bd15B854384B9E8b920f56A3aE2687c1368a65;

    constructor () ERC721 ("Wickens", "WCK") {
        setBaseURI("ipfs://QmXotxqQNjfcbdpWauv4hwHKMNTW96PFWVfN4gaDh8NmFV/");
        setNotRevealedURI("ipfs://QmQZsBZsq16Qi8uuY7BYAGrVu9MeSAe6nKfKcTR336Rgx5/hidden.json");
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // mint function
    function mint(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        if (presaleActive) {
            require(whitelisted[msg.sender] == true, "Not presale member");
            require( _amount > 0 && _amount <= MAX_PER_ADDRESS_PRESALE,    "Can only mint between 1 and 3 tokens at once" );
            require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
            require(balanceOf(msg.sender) + _amount <= MAX_PER_ADDRESS_PRESALE, "Can only mint up to 3 tokens per wallet");
            require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
            for(uint256 i; i < _amount; i++){
                _safeMint( msg.sender, supply + i + 1 ); // Token id starts from 1
            }
        } else {
            if (saleActive) {
                require( _amount > 0 && _amount <= MAX_PER_ADDRESS_PUBLIC,    "Can only mint between 1 and 10 tokens at once" );
                require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
                require(balanceOf(msg.sender) + _amount <= MAX_PER_ADDRESS_PUBLIC, "Can only mint up to 10 tokens per wallet");
                require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
                for(uint256 i; i < _amount; i++){
                    _safeMint( msg.sender, supply + i + 1); // Token id starts from 1
                }
            } else {
                require( presaleActive,                  "Presale isn't active" );
                require( saleActive,                     "Sale isn't active" );
            }
        }
    }

    // Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(uint256 _amount) public  {
        require( msg.sender == Treasury, "Don't have permission to mint" );
        // Limited to a publicly set amount
        require( _amount <= reserved, "Can't reserve more than set amount" );
        reserved -= _amount;
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i + 1); // Token id starts from 1
        }
    }
    

    // Start and stop presale
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Start and stop sale
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)public view  virtual override returns (string memory)
    {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");        
        if(revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // add user's address to whitelist for presale
    function addWhitelistUser(address[] memory _user) public onlyOwner {
        for(uint256 idx = 0; idx < _user.length; idx++) {
            require(whitelisted[_user[idx]] == false, "already set");
            whitelisted[_user[idx]] = true;
        }
    }

    // remove user's address to whitelist for presale
    function removeWhitelistUser(address[] memory _user) public onlyOwner {
        for(uint256 idx = 0; idx < _user.length; idx++) {
            require(whitelisted[_user[idx]] == true, "not exist");
            whitelisted[_user[idx]] = false;
        }
    }

    
    // withdraw all amount from contract
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "There is no balance to withdraw");
        uint256 percent = balance / 100;
        _widthdraw(Shannon, percent * 100/3);
        _widthdraw(Ryan, percent * 100/3);
        _widthdraw(Steve, percent * 100/3);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    } 
}