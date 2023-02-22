// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;

import "./solmate/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*
   ▄██████▄     ▄████████  ▄█    ▄▄▄▄███▄▄▄▄   
  ███    ███   ███    ███ ███  ▄██▀▀▀███▀▀▀██▄ 
  ███    █▀    ███    ███ ███▌ ███   ███   ███ 
 ▄███         ▄███▄▄▄▄██▀ ███▌ ███   ███   ███ 
▀▀███ ████▄  ▀▀███▀▀▀▀▀   ███▌ ███   ███   ███ 
  ███    ███ ▀███████████ ███  ███   ███   ███ 
  ███    ███   ███    ███ ███  ███   ███   ███ 
  ████████▀    ███    ███ █▀    ▀█   ███   █▀  
               ███    ███                      
                                
*/
contract Grim is ERC721, Ownable, Pausable
{
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 300;
    uint256 public constant MAX_SUPPLY_PER_TYPE = 100;
    uint256 public constant MAX_PER_WALLET = 1;

    IGrimMetadata public metadataAddress;
    address signatureVerifier;
    uint256 public totalSupply;
    mapping(address => uint256) public addressToNumMinted;
    
    uint256 public elementalMintCount;
    uint256 public decayMintCount;
    uint256 public sacrificeMintCount;

    uint256 constant DECAY_OFFSET = 100;
    uint256 constant SACRIFICE_OFFSET = 200;

    enum MintType {
        ELEMENTAL,
        DECAY,
        SACRIFICIAL
    }

    constructor() 
    {   
        __ERC721_init("Grim", "GRIM");
        _pause();
    }

    modifier hasValidSignature(bytes memory _signature, bytes memory message) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        if(messageHash.recover(_signature) != signatureVerifier) revert UnrecognizableHash();
       
        _;
    }

    function mint(bytes memory _signature, address _mintTo, MintType _type) 
        public
        whenNotPaused 
        payable
        hasValidSignature(_signature, abi.encodePacked(_mintTo))
    {
        if(addressToNumMinted[_mintTo] + 1 > MAX_PER_WALLET) revert MaxTokensPerWalletAlreadyMinted();
        if(totalSupply + 1 > MAX_SUPPLY ) revert ExceedsMaxSupply();

        _mint(_mintTo, _type, 1); 
        
        addressToNumMinted[_mintTo]++;
        totalSupply++;
    }

    function _mint(address _to, MintType _type, uint256 num) internal {
        if(_type == MintType.ELEMENTAL) {
            if(elementalMintCount + num > MAX_SUPPLY_PER_TYPE ) revert ExceedsMaxMintTypeSupply();
            
            for(uint256 i; i < num; i++) {
                _mint(_to, elementalMintCount);
                elementalMintCount++;
            }
        
        } else if (_type == MintType.DECAY) {
            if(decayMintCount + num > MAX_SUPPLY_PER_TYPE ) revert ExceedsMaxMintTypeSupply();
            
            for(uint256 i; i < num; i++) {
                _mint(_to, decayMintCount + DECAY_OFFSET);
                decayMintCount++;
            }
    
        } else if (_type == MintType.SACRIFICIAL) {
            if(sacrificeMintCount + num > MAX_SUPPLY_PER_TYPE ) revert ExceedsMaxMintTypeSupply();
            
            for(uint256 i; i < num; i++) {
                _mint(_to, sacrificeMintCount + SACRIFICE_OFFSET);
                sacrificeMintCount++;
            }
    
        } else {
            revert InvalidMintType();
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return metadataAddress.getMetadata(_tokenId);
    }

    /*** Owner functions ***/
    function ownerMintToAddress(address _mintTo,  MintType _mintType, uint256 _numTokens)
        external
        onlyOwner
    {
        if(totalSupply + _numTokens > MAX_SUPPLY ) revert ExceedsMaxSupply();
        
        _mint(_mintTo, _mintType, _numTokens);
    }

    function setMetadataAddress(address _address) external onlyOwner
    {
        metadataAddress = IGrimMetadata(_address);
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}

interface IGrimMetadata{ 
    function getMetadata(uint256 _tokenId) external view returns (string memory);
}

error ExceedsMaxMintTypeSupply();
error InvalidMintType();
error ExceedsMaxSupply();
error UnrecognizableHash();
error MaxTokensPerWalletAlreadyMinted();