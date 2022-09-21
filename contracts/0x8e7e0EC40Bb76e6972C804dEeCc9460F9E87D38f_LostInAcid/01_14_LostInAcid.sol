// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// .____                   __    .___            _____         .__    .___
// |    |    ____  _______/  |_  |   | ____     /  _  \   ____ |__| __| _/
// |    |   /  _ \/  ___/\   __\ |   |/    \   /  /_\  \_/ ___\|  |/ __ | 
// |    |__(  <_> )___ \  |  |   |   |   |  \ /    |    \  \___|  / /_/ | 
// |_______ \____/____  > |__|   |___|___|  / \____|__  /\___  >__\____ | 
//         \/         \/                  \/          \/     \/        \/ 

// Visit https://lucatheastronaut.com 
// Airdrop Contract
// Developed by https://mayhemlabs.io

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./common/OwnableDelegateProxy.sol";

//-----------------------------------------------------------------------------------------------------------------------
// Airdrop Contract
//-----------------------------------------------------------------------------------------------------------------------

contract LostInAcid is ERC721A, Ownable, OwnableDelegateProxy, IERC2981 {
    using Strings for uint256;

    // Constants.
    uint256 public constant ROYALTY = 500;

    // Configuration.
    uint256 public maxSupply = 100;
    bool public isPaused = true;
    string private baseURI; 

    // Proxy.
    address private immutable proxyRegistryAddress;             // Opensea Proxy 


    // --------------------------
    //  Constructor
    // -------------------------- 

    /// @notice Contract constructor.
    /// @param _name The token name.
    /// @param _symbol The symbol the token will be known by.
    constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) 
        ERC721A(_name, _symbol)
    {
        proxyRegistryAddress = _proxyRegistryAddress;           // Set the opensea proxy address.
    }


    // --------------------------
    // Airdropping
    // --------------------------

    /// @notice Allows the owner to airdrop tokens to a specific address.
    /// @param _to The address of the person receiving the token/s.
    /// @param _mintAmount The quantity to mint for the given user.
    function ownerAirdrop(address _to, uint256 _mintAmount) 
        external 
        onlyOwner 
        mintAmountGreaterThanZero(_mintAmount)
        doesntExceedTotalSupply(_mintAmount)
    {
        _mint(_to, _mintAmount);
    }

    /// @notice Allows the owner to airdrop tokens to a specific address.
    /// @param _to The address of the person receiving the token/s.
    /// @param _mintAmount The quantity to mint for the given user.
    function ownerAirdropA(address[] memory _to, uint256 _mintAmount) 
        external
        onlyOwner
        needAtleastOneAddress(_to)
        mintAmountGreaterThanZero(_mintAmount)
        doesntExceedTotalSupplyForAddresses(_mintAmount, _to)
    {
        for (uint i = 0; i < _to.length; i++) {
            _mint(_to[i], _mintAmount);
        }
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
        return (owner(), (_salePrice * ROYALTY) / 10000); // eg. (100*500) / 10000 = 5
    }


    // --------------------------
    // Modifiers
    // --------------------------

    /// @notice Check they are minting at least one.
    /// @param _mintAmount the amount they are trying to mint.
    modifier mintAmountGreaterThanZero(uint256 _mintAmount) {
        require(_mintAmount > 0,  "Must mint at least one");
        _;
    }

    /// @notice Make sure the contract isn't paused.
    modifier isNotPaused() {
        require(!isPaused,  "Minting is paused");
        _;
    }

    /// @notice Make sure the amount being minted doesn't exceed total supply.
    /// @param _mintAmount the amount they are trying to mint.
    modifier doesntExceedTotalSupply(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply NFT limit exceeded");
         _;
    }

    /// @notice Make sure the amount being minted doesn't exceed total supply.
    /// @param _mintAmount the amount they are trying to mint.
    modifier doesntExceedTotalSupplyForAddresses(uint256 _mintAmount, address[] memory _to) {
        require(totalSupply() + (_mintAmount * _to.length) <= maxSupply, "Max supply NFT limit exceeded");
         _;
    }

    /// @notice Make sure we have at least one address.
    /// @param _to the amount they are trying to mint.
    modifier needAtleastOneAddress(address[] memory _to) {
        require(_to.length > 0, "Please provide at least one address.");
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


    // --------------------------
    // Controls
    // --------------------------

    /// @notice Set the base URI for the NFT Metadata
    /// @param _newBaseURI The new base URI for the Metadata
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice set if the mint is paused or not.
    /// @param _state The state to set, true is paused false is unpaused.
    function setPaused(bool _state) external onlyOwner {
        isPaused = _state;
    }

    /// @notice Update total supply.
    /// @param _totalSupply The new total supply of tokens
    function updateTotalSupply(uint256 _totalSupply) external onlyOwner {
        require (_totalSupply > maxSupply, "Supply can only increase");
        maxSupply = _totalSupply;
    }

}