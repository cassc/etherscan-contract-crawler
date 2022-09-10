// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

/*********************************  
                 %%#%                                    %(#%                  
               %%(((%#((%(                            @%(((#(((%%%              
            %##((((((%%((((%%              @@@@@@@@@@@@@@@@%(((((%#%%           
         %%%%(((((((((%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(((((((((%%%%        
      %%%%%((((((((((((%@@@@@ FORTUNE COOKY NFT @@@@@@@@@%(((((((((((((%%#%     
    %%%(((((((((((((((((%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(((((((((((((((((((((& 
 (((((########((((((((((##@@@@@@#                  #(((%((((((((##############((
 ((((((((((((#####(((((((%%(%                      %#(%((((((####(((((((((((#   
           ((((((########(%%                         %(((((((((((((  
*********************************/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ICookyDescriptor.sol";
import "./libraries/Base64.sol";


/// @title Fortune Cooky ERC721
contract FortuneCooky is ERC721URIStorage, Ownable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Total Supply of NFTs
    uint256 public constant MAX_TOKENS = 1111;

    // The day the contract is launched, 7 days are calculated from this date
    uint256 private launchDate;

    // Wallet address where ETH is sent during withdraw function
    address private transferWallet;

    // Calculated the total paid for the first 200 NFTs and this is used to make final price from average
    uint256 public TOTAL_PAID;

    // Contract that compiles SVG Image 
    ICookyDescriptor iCookyContract;

    // Token Seed - a number between 100 and 999 that is used for background image and random fortune generation
    mapping(uint256 => uint) public tSeeds;

    // Emits New Fortune tokenId
    event NewFortuneCooky(uint256 indexed id);

    constructor(
        address _transferWallet, 
        address _buildCooky
    ) ERC721("FortuneCookyNFT", "COOKY") {
        setTransferWallet(_transferWallet);
        launchDate = block.timestamp;
        iCookyContract = ICookyDescriptor(_buildCooky);
    }

    /**
     * @notice Total Number of Minted Fortune Cooky NFTs
     * @return Number of NFTs
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

     /**
     * @notice Sets Transfer Wallet - OnlyOwner
     */
    function setTransferWallet(address _transferWallet) public onlyOwner {
        transferWallet = _transferWallet;
    }

    /**
     * @notice Contract Seed that changes ever 7 days. This is calculated by subtracting current time from launch time then dividing the difference by 7 days. We add 1 to ensure number is not 0.
     * @return Contract Seed Number
     */
    function getContractSeed() public view returns (uint256) {
        uint256 difference = block.timestamp - launchDate;
        return (difference/604800) + 1;
    }

    /**
     * @notice Calculates the data of next fortune generation
     * @return Timestamp of next Fortune Generation
     */
    function getNextGenDate() public view returns (uint256) {
        uint256 time_add = 604800 * getContractSeed();
        return launchDate + time_add;
    }

    /**
     * @notice Gets Token Seed from mapping
     * @return Token Seed for a specific tokenId
     */
    function getTokenSeed(uint256 tokenId) public view returns(uint256) {
        return tSeeds[tokenId];
    }

    /**
     * @notice Assigns Token Seed to a tokenId
     */
    function generateSeed(address _to, uint256 tokenId) internal {

        uint256 seed = uint256(keccak256(abi.encodePacked('NANUPANDA_LABS', _to, block.difficulty, blockhash(block.number - 1), block.timestamp, Strings.toString(tokenId))));
        uint scaled = seed % 899;
        tSeeds[tokenId] = scaled + 100; 

    }

    /**
     * @notice Get average of first 200 NFTs sold which becomes price from rest of Collection
     * @return Price of NFT
     */
    function getPrice() public view returns (uint256) {
        return TOTAL_PAID/200;
    }

    /**
     * @notice Shows current rolling average of price of NFT
     * @return rolling average price of NFT
     */
    function getCurrentPriceAvg() external view returns (uint256) {
        return TOTAL_PAID/_tokenIdCounter.current();
    }

    /**
     * @notice Payable Mint Function 
     */    
    function mint(address _to) external payable  {
        require(_tokenIdCounter.current() + 1 <= MAX_TOKENS, "Max limit");
        if (_tokenIdCounter.current() < 201) {
           TOTAL_PAID += msg.value;
        } else {
            require(msg.value >= getPrice(), "Insufficient funds");
        }

        _mintOneItem(_to);

    }

    /**
     * @notice Free Mint function for Only Owner
     */  
    function ownerMintTransfer(address _to, uint256 _count) public  onlyOwner {
        require(_count > 0, "Mint count should be greater than zero");
        require(_tokenIdCounter.current() + _count <= MAX_TOKENS, "Max limit");
 
        for (uint256 i = 0; i < _count; i++) {
            _mintOneItem(_to);
        }
    }

    /**
     * @notice Mints one NFT and is interally called from owner mint or mint
     */  
    function _mintOneItem(address _to) private {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        generateSeed(_to, tokenId);
        _mint(_to, tokenId);
        emit NewFortuneCooky(tokenId);
    }

    /**
     * @notice pulls in all components to calculate SVG image including token seed (tseed), contract seed (cseed), and next generation timestamp 
     * @return Returns Based Encoded json data
     */  
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Cooky: URI query for nonexistent token');
        return iCookyContract._buildFortuneCooky(tokenId, getTokenSeed(tokenId), getContractSeed(), getNextGenDate());
    }

    /**
     * @notice seperate function that pulls current fortune text for specific tokenId
     * @return Returns array of two strings that create the OFrtune Text
     */  
    function getFortuneLines(uint256 tokenId) public view returns (string[2] memory) {
        require(_exists(tokenId), 'Cooky: Fortune query for nonexistent token');
        return iCookyContract._getFortune(tokenId, getTokenSeed(tokenId), getContractSeed());
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(transferWallet, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Transfer failed.");
    }



}