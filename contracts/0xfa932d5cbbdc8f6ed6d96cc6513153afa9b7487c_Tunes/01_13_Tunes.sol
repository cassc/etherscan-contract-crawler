// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

contract Tunes is ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;

    mapping(address => uint256) private _mintedList;
    mapping(address => bool) private _reserveWhitelist;

    uint256[] private _rangeValues;
    string private _tokenBaseURI;
    address private _linkedContractAddress;
    string private _provenanceURI;
    
    uint256 public MAX_PER_ADDRESS;
    uint256 public MAX_PUBLIC;
    uint256 public MAX_RESERVED;
    uint256 public STARTING_RESERVED_ID;
    
    uint256 public totalReservedSupply = 0;
    uint256 public totalPublicSupply = 0;
    uint256 public temporaryPublicMax = 0;

    bool public frozen = false;
    
    function totalSupply() public view returns (uint) {
        return totalReservedSupply + totalPublicSupply;
    }

    constructor(uint256 maxPublic, uint256 maxReserved, uint256 startingReservedID, uint256 maxPerAddress, address[] memory whitelistAddresses) ERC721("Tunes", "TUNE") {
        MAX_PUBLIC = maxPublic;
        MAX_RESERVED = maxReserved;
        STARTING_RESERVED_ID = startingReservedID;
        MAX_PER_ADDRESS = maxPerAddress;

        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            require(whitelistAddresses[i] != address(0), "Can't add the null address");
            _reserveWhitelist[whitelistAddresses[i]] = true;
        }
    }
    
    function setTemporaryPublicMax(uint256 _temporaryPublicMax) public onlyOwner {
        require(_temporaryPublicMax <= MAX_PUBLIC, "You cannot set the temporary max above the absolute total.");
        
        temporaryPublicMax = _temporaryPublicMax;
    }

    function freezeBaseURI() public onlyOwner {
        frozen = true;
    }
    
    function provenanceURI() public view returns (string memory) {
        return _provenanceURI;
    }
    
    function setProvenanceURI(string memory newProvenanceURI) public onlyOwner {
        _provenanceURI = newProvenanceURI;
    }
    
    function linkedContractAddress() public view returns (address) {
        return _linkedContractAddress;
    }
    
    function setLinkedContractAddress(address newLinkedContractAddress) public onlyOwner {
        _linkedContractAddress = newLinkedContractAddress;
    }
    
    function _baseURI() internal override view returns (string memory) {
        return _tokenBaseURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!frozen, "Contract is frozen.");

        _tokenBaseURI = baseURI;
    }

    function mintPublic() public {
        require(_mintedList[msg.sender] < MAX_PER_ADDRESS, "You have reached your minting limit.");
        require(totalPublicSupply < MAX_PUBLIC, "There are no more NFTs for public minting.");
        require(totalPublicSupply < temporaryPublicMax, "There are no more NFTs for public minting at this time.");
        
        _mintedList[msg.sender] += 1;
        
        uint256 tokenId = totalPublicSupply + 1;
        
        // Skip the reserved block
        if (tokenId >= STARTING_RESERVED_ID) {
            tokenId += MAX_RESERVED;
        }
        
        totalPublicSupply += 1;
        _safeMint(msg.sender, tokenId);
    }
    
    function mintReserved(uint256[] calldata tokenIds) external {
        require(_reserveWhitelist[msg.sender], "You are not on the reserve white list.");
        require(totalReservedSupply + tokenIds.length <= MAX_RESERVED, "This would exceed the total number of reserved NFTs.");

        for(uint256 i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          require(tokenId >= STARTING_RESERVED_ID && tokenId < STARTING_RESERVED_ID + MAX_RESERVED, "Token ID is not in the reserve range.");

          totalReservedSupply += 1;
          _safeMint(msg.sender, tokenId);
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory baseURI = _baseURI();
        
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
        
        return "";
    }
}