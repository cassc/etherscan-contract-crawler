//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
/**

  _    _       _       _____      _     _______        _ _     
 | |  | |     | |     |  __ \    | |   |__   __|      | | |    
 | |  | | __ _| |_   _| |__) |__ | |_ __ _| |_ __ ___ | | |____
 | |  | |/ _` | | | | |  ___/ _ \| __/ _` | | '__/ _ \| | |_  /
 | |__| | (_| | | |_| | |  | (_) | || (_| | | | | (_) | | |/ / 
  \____/ \__, |_|\__, |_|   \___/ \__\__,_|_|_|  \___/|_|_/___|
          __/ |   __/ |                                        
         |___/   |___/                                         



*/
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Potatos is ERC721URIStorage, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;
    
    Counters.Counter private _tokenIds;

    bytes32 private _whitelistMerkleRoot;
    bool private _whitelistMint;

    uint256 private _maxSupply;
    uint256 private _tokensAvailable;
    bool private _isPaused;
    string private _customUriPrefix;
    string private _customUriExtension;
    address payable _ownerWallet1;
    address payable _ownerWallet2;

    mapping (uint256 => uint256) private _tierLimitsPerTx;
    mapping (uint256 => uint256) private _tierLimitsPerWallet;
    mapping (uint256 => uint256) private _tierPricing;
    
    mapping (uint256 => bool) private _redeemedPotatosStorage;
    uint256[] private _redeemedPotatos;


    //Fires on a new mint
    event NewMint(uint256 nftId, address nftOwner);
    event GoLive(bool weAreLive);


    constructor(uint256 initSupply, address payable ownerWallet, address payable ownerWallet2) ERC721("UglyPotaTrollz", "POTATROLLZ") {
        //Set the initial collection supply
        _maxSupply = initSupply;
        _tokensAvailable = _maxSupply;
        _whitelistMint = true; //By default, whitelist mints first
        

        //Set initial contract state and owner payable address
        _isPaused = true;
        _ownerWallet1 = ownerWallet;
        _ownerWallet2 = ownerWallet2;
        
        //Set token metadata location
        _customUriPrefix = "";
        _customUriExtension = "";

        //Set tiers configuration

        //Pricing
        _tierPricing[1] = 0;
        _tierPricing[2] = 5000000000000000;
        
        //Limits per transaction
        _tierLimitsPerTx[1] = 3;
        _tierLimitsPerTx[2] = 3;

        //Limits per wallet
        _tierLimitsPerWallet[1] = 3;
        _tierLimitsPerWallet[2] = 3;

    }
    function getMaxSupply()
    public
    view
    returns(uint256) 
    {
        return _maxSupply;
    }

    function getMintPrice(uint256 quantity)
    public
    view
    returns (uint256)
    {
        return _getPrice(quantity);
    }
    /**
        Tiered pricing and limits.
        These methods determine the tier and based on it the price and the limits of how many tokens one can mint
        at this stage of the mint cycle.

     */

     function _getTier(uint256 quantity)
     private
     view
     returns (uint256)
     {
         uint256 newTokenCount = _tokenIds.current() + quantity;

         //Tier 1: First 1000 tokens
         if (newTokenCount <= 1000) {
             return 1;
         }

         //Tier 2: Tokens 1001-2000
         if (newTokenCount > 1000) {
             return 2;
         }


     }
    
    function _getTierLimitPerTx(uint256 quantity)
    private
    view
    returns (uint256)
    {
        uint256 tier = _getTier(quantity);
        return _tierLimitsPerTx[tier];
    }

    function _getTierLimitPerWallet(uint256 quantity)
    private
    view
    returns (uint256)
    {
        uint256 tier = _getTier(quantity);
        return _tierLimitsPerWallet[tier];
    }

    function _getPrice(uint256 quantity) 
    private
    view
    returns (uint256)
    {
        uint256 tier = _getTier(quantity);
        uint256 price = _tierPricing[tier];

        return price * quantity;
    }

    //Return the array of UglyPotaTrollz that have been redemeed for IRL potatos
    function getRedeemedPotatos()
    external
    view
    returns(uint256[] memory) {
        return _redeemedPotatos;
    }

    function isPotatoRedeemed(uint256 potatoId)
    public
    view
    returns(bool){
        return _redeemedPotatosStorage[potatoId];
    }

    function redeemPotato(uint256 potatoId)
    public
    {
        require(ownerOf(potatoId) == msg.sender, "You can only redeem your own UglyPotaTrollz.");
        require(_redeemedPotatosStorage[potatoId] != true, "This potato is alreadt redeemed.");
        _redeemedPotatos.push(potatoId);
        _redeemedPotatosStorage[potatoId] = true;
    }

    /**
        Minting methods
     */
    function whitelistMint(address to, uint256 quantity, bytes32[] memory proof)
    public
    payable
    {
        require(!_isPaused,"Mint is currently paused.");
        require(msg.sender == to, "Sender must be the minter.");
        require(_whitelistMint, "Whitelist mint window has ended. Use public mint instead.");
        require(msg.value >= _getPrice(quantity), "Not enough ETH sent.");
        require(_tokensAvailable >= quantity,"Not enough tokens left, please reduce your quantity.");
        require(quantity <= _getTierLimitPerTx(quantity), "Desired quantity is over the limit of tokens per transaction.");
        require((balanceOf(to)+quantity) <= _getTierLimitPerWallet(quantity),"Desired quantity is over Max Mints Per Wallet limit.");
        require(MerkleProof.verify(proof,_whitelistMerkleRoot,keccak256(abi.encodePacked(to))),"Wallet not whitelisted.");


        if(msg.value > 0) {
            pay(msg.value);
        }
        for (uint256 i = 0; i<quantity; i++) {
            _masterMint(to);
        }
    }

    function publicMint(address to, uint256 quantity)
    public
    payable
    {
        require(!_isPaused,"Mint is currently paused.");
        require(msg.sender == to, "Sender must be the minter.");
        require(!_whitelistMint, "Whitelist mint is still ongoing. Please wait for WL mint to finish.");
        require(msg.value >= _getPrice(quantity), "Not enough ETH sent.");
        require(_tokensAvailable >= quantity,"Not enough tokens left, please reduce your quantity.");
        require(quantity <= _getTierLimitPerTx(quantity), "Desired quantity is over the limit of tokens per transaction.");
        require((balanceOf(to)+quantity) <= _getTierLimitPerWallet(quantity),"Desired quantity is over Max Mints Per Wallet limit.");


        if(msg.value > 0) {
            pay(msg.value);
        }
        for (uint256 i = 0; i<quantity; i++) {
            _masterMint(to);
        }
    }

    function _masterMint(address to)
    private
    {
        require(!_isPaused,"Mint is currently paused.");
        require(_tokensAvailable > 0, "All tokens have been minted already");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to,newItemId);
        _tokensAvailable = _tokensAvailable - 1;
        emit NewMint(newItemId,to);
    }

    /**
        Internal methods
     */
    function _baseURI() 
    internal 
    view 
    virtual 
    override (ERC721) 
    returns (string memory) 
    {
        return _customUriPrefix;
    }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721,ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _customUriExtension)) : "";
    }

    function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
    ) internal virtual override (ERC721,ERC721Enumerable)  {
        require(!_isPaused, "Contract is paused.");
        super._beforeTokenTransfer(from, to, tokenId);
        

    }

    function _burn(uint256 tokenId) 
	internal 
	virtual 
	override (ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);

    }

    function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    virtual 
    override(ERC721, ERC721Enumerable) returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    /**
        Admin utility functions. These methods are used to reconfigure the contract after it has been deployed.
    */

    function setWhitelist(bytes32 newWhitelist)
    public
    onlyOwner {
        _whitelistMerkleRoot = newWhitelist;
    }

    function toggleWhitelistMintStatus()
    public
    onlyOwner {
        _whitelistMint = !_whitelistMint;
    }

    //Returns current status of the whitelsit mint. True if WL mint is on
    function getWhitelistMintStatus()
    public
    view
    returns(bool)
    {
        return _whitelistMint;
    }

    // Returns true if contract is paused
    function getIsContractPaused()
    public
    view
    returns(bool)
    {
        return _isPaused;
    }

    function _setUriPrefix(string memory newBaseUri)
    public
    onlyOwner
    {
        _customUriPrefix = newBaseUri;
    }

    function _setUriExtension(string memory newUriExtension)
    public
    onlyOwner
    {
        _customUriExtension = newUriExtension;
    }

    function toggleContract ()
    public
    onlyOwner 
    {
        _isPaused = !_isPaused;
    }

    function adminMint (address to, uint256 quantity)
    public
    onlyOwner {
        for (uint256 i = 0; i<quantity; i++) {
             _masterMint(to);
        }
    }

    function setMaxSupply (uint256 newMaxSupply) 
    public 
    onlyOwner 
    {
        require(_tokenIds.current() <= newMaxSupply, "Can not set max supply to less than current supply.");
        _maxSupply = newMaxSupply;
        _tokensAvailable = _maxSupply - _tokenIds.current();
    }

    function goLive()
    public
    onlyOwner
    {
        toggleContract();
        emit GoLive(true);
    }
    /**
        Payment processing
    */
    function pay(uint256 amount)
    public 
    payable 
    {
        uint256 finalAmount = 0;
        finalAmount = amount / 2;
        (bool owners, ) = _ownerWallet1.call{value: finalAmount}("");
        require(owners,"Faild to make a payment.");
        (bool owners2, ) = _ownerWallet2.call{value: finalAmount}("");
        require(owners,"Faild to make a payment.");


    }
}