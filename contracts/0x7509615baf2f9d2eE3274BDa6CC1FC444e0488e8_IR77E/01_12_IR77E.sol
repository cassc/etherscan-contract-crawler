// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*

                  ___           ___                     ___                                   ___     
    ___          /__/\         /  /\      ___          /__/\        ___           ___        /  /\    
   /  /\         \  \:\       /  /:/_    /  /\         \  \:\      /  /\         /  /\      /  /:/_   
  /  /:/          \  \:\     /  /:/ /\  /  /:/          \  \:\    /  /:/        /  /:/     /  /:/ /\  
 /__/::\      _____\__\:\   /  /:/ /:/ /__/::\      _____\__\:\  /__/::\       /  /:/     /  /:/ /:/_ 
 \__\/\:\__  /__/::::::::\ /__/:/ /:/  \__\/\:\__  /__/::::::::\ \__\/\:\__   /  /::\    /__/:/ /:/ /\
    \  \:\/\ \  \:\~~\~~\/ \  \:\/:/      \  \:\/\ \  \:\~~\~~\/    \  \:\/\ /__/:/\:\   \  \:\/:/ /:/
     \__\::/  \  \:\  ~~~   \  \::/        \__\::/  \  \:\  ~~~      \__\::/ \__\/  \:\   \  \::/ /:/ 
     /__/:/    \  \:\        \  \:\        /__/:/    \  \:\          /__/:/       \  \:\   \  \:\/:/  
     \__\/      \  \:\        \  \:\       \__\/      \  \:\         \__\/         \__\/    \  \::/   
                 \__\/         \__\/                   \__\/                                 \__\/    
      ___           ___           ___                         ___                                     
     /  /\         /  /\         /  /\                       /__/\                                    
    /  /::\       /  /:/_       /  /::\                     |  |::\                                   
   /  /:/\:\     /  /:/ /\     /  /:/\:\    ___     ___     |  |:|:\                                  
  /  /:/~/:/    /  /:/ /:/_   /  /:/~/::\  /__/\   /  /\  __|__|:|\:\                                 
 /__/:/ /:/___ /__/:/ /:/ /\ /__/:/ /:/\:\ \  \:\ /  /:/ /__/::::| \:\                                
 \  \:\/:::::/ \  \:\/:/ /:/ \  \:\/:/__\/  \  \:\  /:/  \  \:\~~\__\/                                
  \  \::/~~~~   \  \::/ /:/   \  \::/        \  \:\/:/    \  \:\                                      
   \  \:\        \  \:\/:/     \  \:\         \  \::/      \  \:\                                     
    \  \:\        \  \::/       \  \:\         \__\/        \  \:\                                    
     \__\/         \__\/         \__\/                       \__\/                                    

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IR77E is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_MINT_PER_TX = 4;
    uint256 public constant MAX_MINT_PER_WALLET = 12;

    uint256 public price = 0.07 ether;
    uint256 public amountTokensReserved = 0;
    string public baseURI;
    bool public saleActive = false;
    uint256 public totalSupplyRemaining = MAX_SUPPLY;

    mapping(address => uint256) private transactionsPerWallet;

    constructor() ERC721("Infinite Realm 77-E", "IR77E") {
        _tokenIds.increment();
    }

    modifier isMintable() {
        require(saleActive, "Infinite Realm 77-E: NFT cannot be minted yet.");
        _;
    }

    modifier isNotExceedMaxMintPerTx(uint256 amount) {
        require(
            amount <= MAX_MINT_PER_TX,
            "Infinite Realm 77-E: Mint amount exceeds max limit per tx."
        );
        _;
    }

    modifier isNotExceedMaxMintPerWallet(uint256 amount) {
        require(
            transactionsPerWallet[msg.sender] + amount <= MAX_MINT_PER_WALLET,
            "Infinite Realm 77-E: Mint amount exceeds max limit per wallet."
        );
        _;
    }

    modifier isNotExceedAvailableSupply(uint256 amount) {
        require(
            amount <= totalSupplyRemaining - amountTokensReserved,
            "Infinite Realm 77-E: There are no more remaining NFT's to mint."
        );
        _;
    }

    modifier isNotExceedReservedSupply(uint256 amount) {
        require(
            amount <= amountTokensReserved,
            "Infinite Realm 77-E: There are no more remaining reserved NFT's to mint."
        );
        _;
    }

    modifier isPaymentSufficient(uint256 amount) {
        require(
            msg.value == amount * price,
            "Infinite Realm 77-E: There was not enough/extra ETH transferred to mint an NFT."
        );
        _;
    }

    function mint(uint256 amount)
        public
        payable
        isMintable
        isNotExceedAvailableSupply(amount)
        isNotExceedMaxMintPerTx(amount)
        isNotExceedMaxMintPerWallet(amount)
        isPaymentSufficient(amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = _tokenIds.current();
            _safeMint(msg.sender, id);
            _tokenIds.increment();
            transactionsPerWallet[msg.sender] += 1;
            totalSupplyRemaining--;
        }
    }

    function mintReserved(uint256 amount)
        external
        onlyOwner
        isNotExceedReservedSupply(amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = _tokenIds.current();
            _safeMint(msg.sender, id);
            _tokenIds.increment();
            totalSupplyRemaining--;
            amountTokensReserved--;
        }
    }

    function giftReserved(address[] calldata addresses)
        external
        onlyOwner
        isNotExceedReservedSupply(addresses.length)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 id = _tokenIds.current();
            _safeMint(addresses[i], id);
            _tokenIds.increment();
            totalSupplyRemaining--;
            amountTokensReserved--;
        }
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price * (1 wei);
    }

    function flipSaleActiveState() public onlyOwner {
        saleActive = !saleActive;
    }

    function setAmountTokensReserved(uint256 _amountTokensReserved)
        public
        onlyOwner
        isNotExceedAvailableSupply(_amountTokensReserved)
    {
        amountTokensReserved = _amountTokensReserved;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}