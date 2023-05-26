// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";

//   _____ _            _              _     ____                              
//  |_   _| |__   ___  | |    __ _ ___| |_  / ___| _   _ _ __  _ __   ___ _ __ 
//    | | | '_ \ / _ \ | |   / _` / __| __| \___ \| | | | '_ \| '_ \ / _ \ '__|
//    | | | | | |  __/ | |__| (_| \__ \ |_   ___) | |_| | |_) | |_) |  __/ |   
//    |_| |_| |_|\___| |_____\__,_|___/\__| |____/ \__,_| .__/| .__/ \___|_|   
//                                                      |_|   |_|              

contract TheLastSupper is ERC721Enumerable, Ownable
{
    // Constants
    uint256 public constant kTokenPrice = 0.07 ether;   //  Token price.
    uint256 public constant kMaxSupply = 8888;          //  Total number of available tokens.
    uint public constant kMaxMintsPerTransaction = 10;  //  Maximum number of tokens that can be minted in a single transaction.
    uint public constant kMaxPreSaleMintsPerWallet = 2; //  Maximum number of tokens allowed to be minted during pre-sale by a single wallet.

    uint256 public tokensReserve = 100; // Reserve 100 tokens for the team - giveaways and payment to service providers and marketers

    enum SaleState { NONE, PRESALE, SALE }
    SaleState private saleState = SaleState.NONE; // The state of the sale

    // Metadata
    string public baseURI;          // Base URI for metadata
    string public provenanceHash;   // Fills in before minting to ensure that medatata was not modified.
    
    // Presale
    mapping(address => uint) private presaleAccessList;     // Addresses that can participate in the presale
    mapping(address => uint) private presaleTokensClaimed;  // Balance of presale tokens by address
    
    constructor() ERC721("TheLastSupper", "TLS")
    {
    }

    function _baseURI() internal view override returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner
    {
        baseURI = newBaseURI;
    }

    function setProvenanceHash(string memory hash) external onlyOwner
    {
        provenanceHash = hash;
    }
    
    function reserveTokens(address _to, uint256 _amount) public onlyOwner
    {
        require(saleState == SaleState.NONE, "Sale or pre-sale must not be active to reserve tokens.");
        require(0 < _amount && _amount < tokensReserve + 1, "Wrong amount.");
        require(totalSupply() + _amount <= kMaxSupply, "Requested amount exceedes max supply of tokens.");
        uint supply = totalSupply();
        for (uint i = 0; i < _amount; i++)
        {
            _safeMint(_to, supply + i);
        }
        tokensReserve -= _amount;
    }

    function _mintTokens(uint numberOfTokens) private
    {
        for (uint i = 0; i < numberOfTokens; i++)
        {
            _safeMint(msg.sender, totalSupply());
        }
    }
    
    function mint(uint numberOfTokens) public payable
    {
        require(saleState == SaleState.SALE || saleState == SaleState.PRESALE, "Sale must be active to mint tokens.");
        require(numberOfTokens > 0, "Number of tokens should be greater than zero.");
        require(totalSupply() + numberOfTokens <= kMaxSupply, "Minting would exceed total number of available tokens.");
        require(msg.value >= kTokenPrice * numberOfTokens, "Ether value sent is not correct.");
        
        if (SaleState.PRESALE == saleState)
        {
            require(numberOfTokens <= presaleTokensForAddress(msg.sender), "Exceeded the mint limit for this wallet.");
            _mintTokens(numberOfTokens);

            presaleTokensClaimed[msg.sender] += numberOfTokens;
        }
        else
        {
            require(numberOfTokens <= kMaxMintsPerTransaction, "Exceeded the mint limit for one transaction.");
            _mintTokens(numberOfTokens);
        }
    }

    function withdraw() public payable onlyOwner
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "There's nothing to withdraw.");
        payable(msg.sender).transfer(balance);
    }

    function getSaleState() public view returns (SaleState)
    {
        return saleState;
    }
    
    function startPresale() public onlyOwner
    {
        saleState = SaleState.PRESALE;
    }

    function startSale() public onlyOwner
    {
        saleState = SaleState.SALE;
    }

    function stopSale() public onlyOwner
    {
        saleState = SaleState.NONE;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory )
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0)
        {
            return new uint256[](0); // Return an empty array
        }
        else
        {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++)
            {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // PRESALE

    // Manage addresses eligible for presale minting.
    // Even if we remove and re-add specific address multiple times, it will not change value in 'presaleTokensClaimed'
    // thus that specific address can mint only kMaxPreSaleMintsPerWallet tokens max.
    function setPresaleAddresses(uint numberOfTokens, address[] calldata addresses) external onlyOwner
    {
        require(numberOfTokens <= kMaxPreSaleMintsPerWallet, "One presale address can only mint a limited amount of tokens.");
        for (uint256 i = 0; i < addresses.length; i++)
        {
            if (addresses[i] != address(0)) // Safety check
            {
                presaleAccessList[addresses[i]] = numberOfTokens;
            }
        }
    }

    // Returns the number of available presale tokens for a specific address.
    function presaleTokensForAddress(address _address) public view returns (uint)
    {
        return (presaleTokensClaimed[_address] < presaleAccessList[_address]) ? (presaleAccessList[_address] - presaleTokensClaimed[_address]) : 0;
    }
}