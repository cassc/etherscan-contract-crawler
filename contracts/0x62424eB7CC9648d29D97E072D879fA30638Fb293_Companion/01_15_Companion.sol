//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IWASNFT {
    function ownerOf(uint256 tokenId) external returns (address);
    function balanceOf(address satoshiOwnerAddress) external returns (uint256);
    function tokenOfOwnerByIndex(address satoshiOwnerAddress, uint256 tokenId) external returns (uint256);
}

contract Companion is ERC721URIStorage, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply;
    uint256 private _tokensAvailable;
    bool private _isPaused;
    string private _customUriPrefix;
    string private _customUriExtension;

    mapping (uint256 => bool) private _claimedSatoshisStorage;
    uint256[] private _claimedSatoshis;
    mapping (uint256 => uint256) private _companionSatoshiPairsStorage;

    //Fires on a new mint
    event CompanionClaim(address nftOwner);

    address private _wasNFTSmartContract;
    IWASNFT wasNFTContract = IWASNFT(_wasNFTSmartContract);

    constructor(uint256 initSupply, address wasScAddress) ERC721("WAS Companion", "WAS-Companion") {
        //Set the initial collection supply
        _maxSupply = initSupply;
        _tokensAvailable = _maxSupply;        

        //Set initial contract state
        _isPaused = true;

        //Set token metadata location
        _customUriPrefix = "";
        _customUriExtension = "";

        _wasNFTSmartContract = wasScAddress;
    }

    function getMaxSupply()
    public
    view
    returns(uint256) 
    {
        return _maxSupply;
    }

    function getTokensAvailable()
    public
    view
    returns(uint256) 
    {
        return _tokensAvailable;
    }

    //Return the array of We Are Satoshis that claimed their Companion
    function getAllSatoshiIdsThatClaimedACompanion()
    external
    view
    returns(uint256[] memory) {
        return _claimedSatoshis;
    }

    function didSatoshiClaimACompanion(uint256 satoshiId)
    public
    view
    returns(bool){
        return _claimedSatoshisStorage[satoshiId];
    }

    //For given Companion ID, this method returns satoshi ID it originated from
    function getCompanionOriginSatoshi(uint256 companionId)
    public
    view
    returns(uint256){
        return _companionSatoshiPairsStorage[companionId];
    }

    function claim(address to)
    public
    {
        require(msg.sender == to, "Sender must be the owner of the Satoshis.");
        uint256 ownerBalance = IWASNFT(_wasNFTSmartContract).balanceOf(to);
        require(ownerBalance > 0, "Nothing to claim :(");
        uint256 satoshiId;
        bool newMints = false;
        for (uint256 i = 0; i<ownerBalance; i++) {
            satoshiId = IWASNFT(_wasNFTSmartContract).tokenOfOwnerByIndex(to, i);
            if(!_claimedSatoshisStorage[satoshiId]) {
                _claimedSatoshisStorage[satoshiId] = true;
                _claimedSatoshis.push(satoshiId);
                _masterMint(to,satoshiId);
                newMints = true;
            }
        }
        //emmit only one event per claim tx instead an event for each Companion claimed
        if (newMints){
            emit CompanionClaim(to);
        }
    }

    //standard master mint method
    function _masterMint(address to, uint256 satoshiId)
    private
    {
        require(!_isPaused,"Mint is currently paused.");
        require(_tokensAvailable > 0, "All tokens have been minted already");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to,newItemId);
        _tokensAvailable = _tokensAvailable - 1;
        _companionSatoshiPairsStorage[newItemId] = satoshiId;
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
}