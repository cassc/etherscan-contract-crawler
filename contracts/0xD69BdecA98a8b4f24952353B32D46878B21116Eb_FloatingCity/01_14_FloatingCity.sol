// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Errors.sol";

/*
   ▄████████  ▄█        ▄██████▄     ▄████████     ███      ▄█  ███▄▄▄▄      ▄██████▄        ▄████████  ▄█      ███     ▄██   ▄   
  ███    ███ ███       ███    ███   ███    ███ ▀█████████▄ ███  ███▀▀▀██▄   ███    ███      ███    ███ ███  ▀█████████▄ ███   ██▄ 
  ███    █▀  ███       ███    ███   ███    ███    ▀███▀▀██ ███▌ ███   ███   ███    █▀       ███    █▀  ███▌    ▀███▀▀██ ███▄▄▄███ 
 ▄███▄▄▄     ███       ███    ███   ███    ███     ███   ▀ ███▌ ███   ███  ▄███             ███        ███▌     ███   ▀ ▀▀▀▀▀▀███ 
▀▀███▀▀▀     ███       ███    ███ ▀███████████     ███     ███▌ ███   ███ ▀▀███ ████▄       ███        ███▌     ███     ▄██   ███ 
  ███        ███       ███    ███   ███    ███     ███     ███  ███   ███   ███    ███      ███    █▄  ███      ███     ███   ███ 
  ███        ███▌    ▄ ███    ███   ███    ███     ███     ███  ███   ███   ███    ███      ███    ███ ███      ███     ███   ███ 
  ███        █████▄▄██  ▀██████▀    ███    █▀     ▄████▀   █▀    ▀█   █▀    ████████▀       ████████▀  █▀      ▄████▀    ▀█████▀  
             ▀                                                                                                                    
*/
contract FloatingCity is 
    ERC721("FloatingCity", "FLOATINGCITY"), Ownable, Pausable
{
    using ECDSA for bytes32;
    using Strings for uint256;
    uint256 [] public unAllocatedTokens;
    
    // token index starts from 1  
    // and token zero will not be minted
    uint256 public constant DENIZEN_MAX_SUPPLY = 100;
    uint256 public constant MAX_SUPPLY = 200;
    uint256 public constant NOT_REMAPPED = 1001;

    bytes32 public provenanceHash;
    address public fcGateKeyAddress;
    address public fcMetadataAddress;
    uint256 public totalSupply;
    mapping(uint256 => address) public allowList;
    mapping(uint256 => uint256) public remappedTokenToIndexMapping;
    
    constructor() 
    {   
        // initialize unallocatedTokens and remapped token map
        for(uint i = 1; i <= DENIZEN_MAX_SUPPLY; i++){
            unAllocatedTokens.push(i);
            remappedTokenToIndexMapping[i] = NOT_REMAPPED;
        }

        _pause();
    }

    modifier underDenizenMaxSupply(uint256 _count) {
        if(totalSupply + _count > DENIZEN_MAX_SUPPLY ) revert ExceedsDenizenMaxSupply();
        _;
    }
    
    function mint(uint256 _FCTokenId, uint256 _FCGateKeyTokenId)
        external
        payable
        whenNotPaused
        underDenizenMaxSupply(1)
    {
        if (tx.origin != msg.sender) revert CallerIsAnotherContract();
        if(IE721(fcGateKeyAddress).ownerOf(_FCGateKeyTokenId) != msg.sender) revert UserDoesNotHoldGateKey();
        if(allowList[_FCTokenId] != msg.sender) revert UserIsNotAllowListedForThisToken();

        IFCGateKey(fcGateKeyAddress).burn(_FCGateKeyTokenId);
        totalSupply++;
        _mint(msg.sender, _FCTokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert ("URIQueryForNonexistentToken");

        return IFloatingCityMetadata(fcMetadataAddress).getMetadata(tokenId);
    }

    function getUnAllocatedTokensLength() public view returns (uint256) {
        return unAllocatedTokens.length;
    }

    function getUnAllocatedTokens() public view returns (uint256[] memory) {
        return unAllocatedTokens;
    }

    function getRemappedTokenToIndexMapping() public view returns (uint256[DENIZEN_MAX_SUPPLY + 1] memory) {
        uint256[DENIZEN_MAX_SUPPLY + 1] memory remappedTokenToIndexMappingArray;

        for(uint256 i = 0; i <= DENIZEN_MAX_SUPPLY; i++) {
            remappedTokenToIndexMappingArray[i] = remappedTokenToIndexMapping[i];
        }

        return remappedTokenToIndexMappingArray;
    }
    
    function getAllowList() public view returns (address[MAX_SUPPLY + 1] memory) {
        address[MAX_SUPPLY + 1] memory allowListArray;
        for(uint256 i = 1; i <= MAX_SUPPLY; i++) {
            allowListArray[i] = allowList[i];
        }
        return allowListArray;
    }

    // this version produces output readable from etherscan
    function getAllowListStringArray() public view returns (string[DENIZEN_MAX_SUPPLY + 1] memory) {
        string[DENIZEN_MAX_SUPPLY + 1] memory allowListArray;

        for(uint256 i = 1; i <= DENIZEN_MAX_SUPPLY; i++) {
            allowListArray[i] = Strings.toHexString(uint160(allowList[i]), 20);
        }

        return allowListArray;
    }


    /*** Owner functions ***/

    function addToAllowList(address _address, uint256 _tokenId) public onlyOwner {
        if(_tokenId == 0 || _tokenId > 100) revert InvalidTokenId();
        if(allowList[_tokenId] != address(0)) revert AddressAlreadySet();
        if(unAllocatedTokens.length == 0) revert AllTokensAllocated();

        allowList[_tokenId] = _address;
        
        uint256 indexOfTokenId = _tokenId-1;

        if(unAllocatedTokens[unAllocatedTokens.length-1] != _tokenId) {
            if(remappedTokenToIndexMapping[_tokenId] == NOT_REMAPPED ) {
                // base case, default to using index on unallocatedTokens where index equals _tokenId
                remappedTokenToIndexMapping[unAllocatedTokens[unAllocatedTokens.length - 1]] = indexOfTokenId;
                unAllocatedTokens[indexOfTokenId] = unAllocatedTokens[unAllocatedTokens.length - 1];
            
            } else {
                // use index in remappedTokenToIndexMapping instead of index itself as it has shifted 
                // from a previous shuffle
                remappedTokenToIndexMapping[unAllocatedTokens[unAllocatedTokens.length - 1]] = remappedTokenToIndexMapping[_tokenId];
                unAllocatedTokens[remappedTokenToIndexMapping[_tokenId]] = unAllocatedTokens[unAllocatedTokens.length - 1];
            }
        }
        unAllocatedTokens.pop(); 
    }

    // override who is on allowlist
    function setAllowListEntry(address _address, uint256 _tokenId) public onlyOwner {
        allowList[_tokenId] = _address;
    }

    function ownerMintToAddress(address _recipient, uint256 _tokenId)
        external
        onlyOwner
    {
        if(totalSupply + 1 > MAX_SUPPLY ) revert ExceedsMaxSupply();
        totalSupply++;
        _mint(_recipient, _tokenId);
    }

    function burnGateKey(uint256 _tokenId) external onlyOwner {
        IFCGateKey(fcGateKeyAddress).burn(_tokenId);
    }

    function setFCMetadataAddress(address _address) external onlyOwner
    {
        fcMetadataAddress = _address;
    }

    function setFCGateKeyAddress(address _address) external onlyOwner
    {
        fcGateKeyAddress = _address;
    }

    function setProvenanceHash(bytes32 _provenanceHash) external onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}

interface IE721  {
   function ownerOf(uint256 _FCGateKeyTokenId) external returns(address);
   function balanceOf(address _address) external returns(uint256);
}

interface IFCGateKey {
    function burn(uint256 _tokenId) external;
}

interface IFloatingCityMetadata{ 
    function getMetadata(uint256 _tokenId) external view returns (string memory);
}