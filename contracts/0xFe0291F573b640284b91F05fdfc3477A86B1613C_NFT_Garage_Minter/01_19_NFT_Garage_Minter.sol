// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

///   ___    __  _______  __________    _____
///  |   \  |  ||   ____||___    ___| /  _____\  
///  |    \ |  ||  |___      |  |    |  /  ____  __ _ _ __  __ _  __ _  ___ 
///  |  |\ \|  ||   ___|     |  |    | |  |__  |/ _` |  ,_|/ _` |/  ` \/ _ \
///  |  | \    ||  |         |  |    |  \___/  | (_| | |  | (_| | (_| |  __/ 
///  |__|  \___||__|         |__|     \ _____ / \__,_|_|   \__,_|\__, |\___|
///                                                              _  | |  
///                                                              \\_/ |
/// Visit http://nftgarage.wtf                                    \__/
/// Minting Contract
/// Developed by https://mayhemlabs.io 

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./common/EIP712Whitelisting.sol";
import "./common/OwnableDelegateProxy.sol";

//-----------------------------------------------------------------------------------------------------------------------
// Minting Contract
//-----------------------------------------------------------------------------------------------------------------------

contract NFT_Garage_Minter is ERC721ABurnable, IERC2981, ReentrancyGuard, EIP712Whitelisting, OwnableDelegateProxy {
    using Strings for uint256; 

    // Constants.
    uint256 public constant WHITELIST_COST = 0.05 ether;            // Whitelist cost. 
    uint16 public constant MAX_SUPPLY = 7500;                       // Total number of NFTs that can be minted ever. 
    uint16 public constant ROYALTY = 500;                           // 500 is divided by 10000 in the royalty info function to make 5%
    uint8 public constant MAX_PER_PUBLIC_TRANSACTION = 12;          // The total allow to be minted per transaction.

    // Configuration.
    mapping(address => uint16) private mintBalances;                // Store lifetime mints for an public address.
    address private immutable proxyRegistryAddress;                 // Opensea proxy to preapprove.
    address private devWallet;                                      // The address the developer portion is paid to.
    uint256 public publicCost = 0.05 ether;                         // Public cost.
    string private baseURI;                                         // Stores the baseURI for location of NFT Metadata 
    string private notRevealedUri;                                  // The URL to the placeholder art before reveal.
    bool public isWhitelist = true;                                 // Is the whitelisting active?
    bool public isPaused = true;                                    // Is the contract paused?
    bool public revealed = false;                                   // Is the artowrk revealed?


    // --------------------------
    //  Constructor
    // -------------------------- 

    /// @notice Contract constructor.
    /// @param _name The token name.
    /// @param _symbol The symbol the token will be known by.
    /// @param _initNotRevealedUri The URI of the not revealed version of the NFT metadata.
    /// @param _devWallet the contract developers.
    constructor(string memory _name, string memory _symbol, string memory _initNotRevealedUri, address _proxyRegistryAddress, address _devWallet) 
        ERC721A(_name, _symbol) 
        EIP712Whitelisting(_name)
    {
        notRevealedUri = _initNotRevealedUri;                   // Set the not revealed URI for the placeholder metadata. 
        proxyRegistryAddress = _proxyRegistryAddress;           // Set the opensea proxy address.
        devWallet = _devWallet;                                 // The wallet funds go to for the devs from the mint.
    }



    // --------------------------
    // Purchase and Minting
    // --------------------------

    /// @notice Returns the token url a token id.
    /// @param _mintAmount The amount the person minting has requested to mint.
    function ownerMint(uint16 _mintAmount) 
        external 
        onlyOwner 
        mintAmountGreaterThanZero(_mintAmount)
        doesntExceedMaxSupply(_mintAmount)
    {
        _mint(msg.sender, _mintAmount);
    }
    
    /// @notice Allows the owner to airdrop tokens to a specific address.
    /// @param _to The address of the person receiving the token/s.
    /// @param _mintAmount The number of tokens being minted and sent.
    function ownerAirdrop(address _to, uint16 _mintAmount) 
        external 
        onlyOwner 
        mintAmountGreaterThanZero(_mintAmount)
        doesntExceedMaxSupply(_mintAmount)
    {
        _mint(_to, _mintAmount);
    }

    /// @notice Purchase a token as whitelister.
    /// @param _max The max amount the person minting is allow to mint.
    /// @param _signature The signature proving that the user is on the whitelist and the values haven't been altered.
    /// @param _mintAmount The amount the person minting has requested to mint.
    function whiteListMint(uint256 _max, bytes calldata _signature, uint16 _mintAmount) 
        external 
        payable 
        nonReentrant
        isNotPaused
    {
        require(isWhitelist, "Is in public mode");
        require(!(_mintAmount + mintBalances[msg.sender] > _max), "You have exceeded your mint whitelist allocation");
        require(checkWhitelist(_max, _signature),  "Invalid whitelist signature");

        _doMint(_mintAmount, WHITELIST_COST);
    }

    /// @notice Purchase a token as the public.
    /// @param _mintAmount The amount the person minting has requested to mint.
    function publicMint(uint16 _mintAmount) 
        external 
        payable 
        nonReentrant
        isNotPaused
    {
        require(!isWhitelist, "Not in public mode");
        require(!(_mintAmount > MAX_PER_PUBLIC_TRANSACTION), "You can only mint 12 per transaction");

        _doMint(_mintAmount, publicCost);
    }

    /// @notice Calls the underlying mint function of the ERC721Enumerable class.
    /// @param _mintAmount The quantity to mint for the given user.
    function _doMint(uint16 _mintAmount, uint256 _price) 
        internal
        doesntExceedMaxSupply(_mintAmount)
        insuffcientEth(_mintAmount, _price)
     {
        _mint(msg.sender, _mintAmount);

        mintBalances[msg.sender] += _mintAmount; // Update the count of how many items a given address has minted over the lifetime of the contract.
    }



    // --------------------------
    // Metadata Url
    // --------------------------

    /// @notice generates the return URL from the base URL.
    function _baseURI()
        internal 
        view 
        virtual 
        override 
        returns (string memory) {

        return baseURI;
    }

    /// @notice Returns the token url a token id.
    /// @param _tokenId The id of the token to return the url for.
    /// @return the compiled Uri string to the nft metadata.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        // Check for the existence of the token.
        require(_exists(_tokenId), "ERC721AMetadata: URI query for nonexistent token");

        // Check if the token have been revealed. If not return url to a common image.
        if (revealed == false) { return notRevealedUri; }

        // Get the base url.
        string memory currentBaseURI = _baseURI();

        // Compile a url using the token details.
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json")) : "";
    }



    // --------------------------
    // Royalties
    // --------------------------


    /// @notice EIP2981 calculate how much royalties paid to the contract owner.
    /// @param _salePrice The sale price.
    /// @return receiver and a royaltyAmount.
    function royaltyInfo(uint256, uint256 _salePrice) 
        external 
        view 
        override(IERC2981) 
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * 500) / 10000); // eg. (100*500) / 10000 = 5
    }



    // --------------------------
    // Modifiers
    // --------------------------

    /// @notice Check they are minting at least one.
    /// @param mintAmount the amount they are trying to mint.
    modifier mintAmountGreaterThanZero(uint256 mintAmount) {
        require(mintAmount > 0,  "Must mint at least one");
        _;
    }

    /// @notice Make sure the contract isn't paused.
    modifier isNotPaused() {
        require(!isPaused,  "Minting is paused");
        _;
    }

    /// @notice Make sure the amount being minted doesn't exceed total supply.
    /// @param mintAmount the amount they are trying to mint.
    modifier doesntExceedMaxSupply(uint256 mintAmount) {
        require(totalMinted() + mintAmount <= MAX_SUPPLY, "Max NFT limit exceeded");
         _;
    }

    /// @notice Check they provided enough eth to mint.
    /// @param mintAmount the amount they are trying to mint.
    /// @param price price per token.
    modifier insuffcientEth(uint16 mintAmount, uint256 price) {
        require(msg.value >= (price * mintAmount), "Insuffcient Eth in transaction, check price");
         _;
    }



    // --------------------------
    // Misc
    // --------------------------

    /// @notice Indicates if we support the IERC2981 interface (https://eips.ethereum.org/EIPS/eip-2981).
    /// @param _interfaceId the interface to check the contract supports.
    /// @return true or fales if the requested interface is supported.
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (_interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId));
    }

    /// @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    /// @param _owner the token owner.
    /// @param _operator the operator to check approval for.
    /// @return true if approved false otherwise.
    function isApprovedForAll(address _owner, address _operator) 
        public 
        view 
        override(ERC721A) 
        returns (bool)
    {
        // Whitelist OpenSea proxy contract to save gas by not needing approval when trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) { return true; }

        // Otherwise default to base implmentation.
        return super.isApprovedForAll(_owner, _operator);
    }

    function totalMinted() public view virtual returns (uint256) {
        return _totalMinted();
    }
    

    // --------------------------
    // Controls
    // --------------------------

    /// @notice Set the base URI for the NFT Metadata
    /// @param _newBaseURI The new base URI for the Metadata
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice Set public mint price.
    /// @param _newMintPrice The [ublic mint price maximum.
    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        publicCost = _newMintPrice;
    }

    /// @notice Determines if the tokens should return proper images or place holders before reveal.
    /// @param _state The state to set: true is revealed, false is hidden.
    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    /// @notice Set if the mint is paused or not.
    /// @param _state The state to set, true is paused false is unpaused.
    function setPaused(bool _state) external onlyOwner {
        isPaused = _state;
    }

    /// @notice Set the whitelist mode.
    /// @param _state The state to set, true is in whitelist mode false is in public mode.
    function setIsWhiteList(bool _state) external onlyOwner {
        isWhitelist = _state;
    }

    /// @notice Allow withdrawals from the contract by the owner.
    function withdraw() public payable onlyOwner {
        // This will payout the devs 4% of the contract balance and the owner 96%.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool devs, ) = payable(address(devWallet)).call{value: (address(this).balance * 4) / 100}("");
        require(devs, "Error withdrawing to devWallet");

        (bool owner, ) = payable(address(owner())).call{value: address(this).balance}("");
        require(owner, "Error withdrawing to ownerWallet");
        // =============================================================================
    }
}