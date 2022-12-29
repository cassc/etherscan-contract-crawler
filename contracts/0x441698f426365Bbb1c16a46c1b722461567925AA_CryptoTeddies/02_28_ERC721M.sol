// SPDX-License-Identifier: AGPL-3.0-only
// @author creco.xyz 🐊 2022 
    
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


interface IMetadata {
  function tokenURI(uint256 tokenId, uint256 dna) external view returns (string memory);
}

interface IERC20 {
  function balanceOf(address) external returns(uint);
  function transferFrom(address, address, uint) external;
}

abstract contract ERC721M is 
    Ownable,
    AccessControlEnumerable,
    ERC721Burnable,
    ERC721Enumerable,
    ERC721Pausable,
    ERC721Royalty,
    DefaultOperatorFilterer
 {
    using Strings for uint256;
    using Address for address payable;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bool public isFrozenDNA;
    bool public isFrozenMetadata;
    bool useOperatorFilter = true;  // toggle OpenSea's filter

    string public baseTokenURI;
    mapping(uint256 => uint8) public dna; // 0 if not exists, 1 if exists
    mapping(uint256 => uint256) private tokenIdToDNA;
  
    IMetadata public metadata;

    struct NFT {
        uint256 tokenId;
        uint256 dna;
    }
    
    // permission modifiers
    modifier onlyAdmin {
         require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721Access: must have Admin role");
         _;
    } 

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721Access: must have Minter role");
        _;
    } 

    modifier onlyPauser {
         require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721Access: must have Pauser role");
        _;
    }

    modifier onlyAllowedOperator(address from) virtual override {
      // Allow spending tokens from addresses with balance
      // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
      // from an EOA.
      if (from != msg.sender && useOperatorFilter) {
        _checkFilterOperator(msg.sender);
      }
      _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual override {
      if(useOperatorFilter) {
        _checkFilterOperator(operator);
      }
      _;
    }

   constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI
    ) ERC721(name, symbol) {
        baseTokenURI = _baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // set admin permissions
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) onlyAdmin public {
      _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) onlyAdmin public {
      _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setOperatorFilter(bool isActive) onlyAdmin public {
      useOperatorFilter = isActive;
    }

    function setMetadataContract(address _contractAddress) onlyAdmin public {
      metadata = IMetadata(_contractAddress);
    }

    function setBaseTokenURI(string memory _uri) onlyAdmin public {
      baseTokenURI = _uri;
    }
        
    function setDNA(uint256[] memory _tokenIds, uint256[] memory _dnaArr) onlyMinter public {
      require(!isFrozenDNA, "ERC721M - DNA is final for this collection");
      require(_tokenIds.length == _dnaArr.length, "ERC721M - DNA data missing");
      for (uint i = 0; i < _tokenIds.length; i++) {
        uint currentDNA = _dnaArr[i];
        uint currentTokenId = _tokenIds[i];
        require(dna[currentDNA] == 0, "ERC721M - DNA must be unique"); // make sure DNA is unique
        
        // free old DNA in case of DNA update
        uint oldDNA = tokenIdToDNA[currentTokenId];
        if(oldDNA != 0) {
          dna[oldDNA] = 0;
        }
        tokenIdToDNA[currentTokenId] = currentDNA;
        dna[currentDNA] = 1; // flag DNA 
      }
    }

    function getDNA(uint256 tokenId) public view returns(uint256) {
      return tokenIdToDNA[tokenId];
    }

    function tokensOfOwner(address owner) public view returns (NFT[] memory) {  
      uint balance = balanceOf(owner);
      NFT[] memory tokensOwned = new NFT[](balance);
      for (uint256 i=0; i < balance; i++){
          uint tokenId = tokenOfOwnerByIndex(owner, i);
          tokensOwned[i].tokenId = tokenId;
          tokensOwned[i].dna =  getDNA(tokenId);
      }
      return tokensOwned;
    }

    function freezeDNA() onlyAdmin public {
      isFrozenDNA = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721M - URI query for nonexistent token");
      uint256 tokenDNA = getDNA(tokenId);
      if(address(metadata) != address(0x0)) {
        return metadata.tokenURI(tokenId, tokenDNA);
      }
      return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString() )) : "";
    }

    function pause() onlyPauser public virtual {
        _pause();
    }

    function unpause() onlyPauser public virtual {
        _unpause();
    }

    function _burn(uint256 tokenId) internal virtual override(
      ERC721,
      ERC721Royalty
    ) {
      super._burn(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
      super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (
          AccessControlEnumerable, 
          ERC721, 
          ERC721Enumerable,
          ERC721Royalty
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    } 
}