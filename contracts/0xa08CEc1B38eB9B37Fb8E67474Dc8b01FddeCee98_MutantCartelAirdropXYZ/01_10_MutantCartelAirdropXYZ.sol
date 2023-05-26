// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity ^0.8.7;

import "ERC721xyz.sol";

contract MutantCartelAirdropXYZ is ERC721xyz{
    
    string private _name;
    string private _symbol;

    uint256 public royaltyPercentage; 

    address public owner;
    bool public burnable;

    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR");
        _;
    }

    constructor(uint256 royalty) payable ERC721xyz(_name, _symbol){
        _name = "Mutant Cartel";
        _symbol = "MCXYZ";
        royaltyPercentage = royalty;
        owner = msg.sender;
    }

    // Collection Name
    function name() override public view returns (string memory) {
        return _name;
    }

    // Collection ticker
    function symbol() override public view returns (string memory) {
        return _symbol;
    }

    // Burn token
    function burn(uint256 tokenId) public returns(uint256)
    {
        require(burnable, "This contract does not allow burning");
        require(msg.sender == ownerOf(tokenId), "Burner is not the owner of token");
        _burn(tokenId);
        return tokenId;
    }

    // Open/close burning
    function changeBurnableState() public onlyOwner returns(bool)
    {
        burnable = !burnable;
        return burnable;
    }

    // Airdrop a token
    function airdrop(address[] memory address_, uint256 tokenCount, uint256 tokenType) onlyOwner public returns(uint256) 
    {
        require(tokenType == 1 || tokenType == 2, "Please input valid Token Type");
        require(address_.length > 0, "Need to airdrop to someone!");
        require(address_.length <= 20, "Exceeds address count");
        uint256 mintCount;

        for(uint256 i = 0; i < address_.length; ) {
            _mint(address_[i], tokenCount);
            mintCount = viewMinted();
            _uriMappings[mintCount] = tokenType;
            unchecked{
                ++i;    
            }
        }
        

        return mintCount;
    }

    function changeTokenURI(uint256 tokenType, string memory newURI) onlyOwner public
    {
        _uri[tokenType] = newURI;
    }
    
    // transfer ownership of the smart contract
    function transferOwnership(address newOwner) onlyOwner public returns(address)
    {
        require(newOwner != address(0), "Cannot set zero address as owner!");
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
        return(owner);
    }

    // renounce ownership of the smart contract
    function renounceOwnership() onlyOwner public returns(address)
    {
        owner = address(0);
        emit OwnershipTransferred(msg.sender, address(0));
        return(owner);
    }
    
    function changeRoyalty(uint256 newRoyaltyPercentage) onlyOwner public returns(uint256)
    {
        royaltyPercentage = newRoyaltyPercentage;
        return(newRoyaltyPercentage);
    }

    // Returns the royalty amount for a specific value
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address receiver, uint256 royaltyAmount)
    {
        return (owner, (value * royaltyPercentage) / 100);
    }

    // only owner - withdraw contract balance to wallet. 6% primary sale fee to Fair.xyz
    function withdraw()
        public
        payable
        onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }


}