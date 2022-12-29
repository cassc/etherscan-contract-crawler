// SPDX-License-Identifier: AGPL-3.0-only
// @author creco.xyz 🐊 2022 
    
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
 
interface IMetadata {
  function tokenURI(uint256 tokenId, uint256 dna) external view returns (string memory);
}

interface IERC20 {
  function balanceOf(address) external returns(uint);
  function transferFrom(address, address, uint) external;
}

abstract contract ERC1155M is 
    AccessControlEnumerable,
    ERC1155Pausable,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer
 {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bool public isFrozenDNA;
    bool useOperatorFilter = true;  // toggle OpenSea's filter

    string public baseTokenURI;
    mapping(uint256 => uint256) public dnaToTokenId;
    mapping(uint256 => uint256) private tokenIdToDNA;
  
    IMetadata public metadata;

    // permission modifiers
    modifier onlyAdmin {
         require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC1155Access: must have Admin role");
         _;
    } 

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155Access: must have Minter role");
        _;
    } 

    modifier onlyPauser {
         require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155Access: must have Pauser role");
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
        string memory _uri
    ) ERC1155(_uri) {
        baseTokenURI = _uri;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // set admin permissions
    }

    function setMetadataContract(address _contractAddress) onlyAdmin public {
      metadata = IMetadata(_contractAddress);
    }

    function setBaseTokenURI(string memory _uri) onlyAdmin public {
      baseTokenURI = _uri;
    }

    function setOperatorFilter(bool isActive) onlyAdmin public {
      useOperatorFilter = isActive;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) onlyAdmin public {
      _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) onlyAdmin public {
      _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
        
    function setDNA(uint256[] memory _tokenIds, uint256[] memory _dnaArr) onlyMinter public {
      require(!isFrozenDNA, "ERC1155M - DNA is final for this collection");
      require(_tokenIds.length == _dnaArr.length, "ERC1155M - DNA data missing");
      for (uint i = 0; i < _tokenIds.length; i++) {
        uint currentDNA = _dnaArr[i];
        uint currentTokenId = _tokenIds[i];
        require(dnaToTokenId[currentDNA] == 0, "ERC1155M - DNA must be unique"); // make sure DNA is unique
       
        // free oldDNA in case of DNA update
        uint oldDNA = tokenIdToDNA[currentTokenId];
        if(oldDNA != 0) {
          dnaToTokenId[oldDNA] = 0;
        }

        dnaToTokenId[currentDNA] = currentTokenId;
        tokenIdToDNA[currentTokenId] = currentDNA;
      }
    }

    function getDNA(uint256 tokenId) public view returns(uint256) {
      return tokenIdToDNA[tokenId];
    }

    function freezeDNA() onlyAdmin public {
      isFrozenDNA = true;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
      require(exists(tokenId), "ERC1155M - URI query for nonexistent token");
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

    // NOTE we don't override _burn and _burnBatch to unset royalties for burned tokens

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply, ERC1155Pausable) {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
          AccessControlEnumerable, 
          ERC1155,
          ERC2981
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    } 
}