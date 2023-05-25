//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/*

__          ________ _      _____ ____  __  __ ______   _        
\ \        / /  ____| |    / ____/ __ \|  \/  |  ____| | |       
 \ \  /\  / /| |__  | |   | |   | |  | | \  / | |__    | |_ ___  
  \ \/  \/ / |  __| | |   | |   | |  | | |\/| |  __|   | __/ _ \ 
   \  /\  /  | |____| |___| |___| |__| | |  | | |____  | || (_) |
    \/  \/   |______|______\_____\____/|_|  |_|______|  \__\___/ 

  _____ _____  ______ _____ ____  _               _   _ _____  
 / ____|  __ \|  ____/ ____/ __ \| |        /\   | \ | |  __ \ 
| |    | |__) | |__ | |   | |  | | |       /  \  |  \| | |  | |
| |    |  _  /|  __|| |   | |  | | |      / /\ \ | . ` | |  | |
| |____| | \ \| |___| |___| |__| | |____ / ____ \| |\  | |__| |
 \_____|_|  \_\______\_____\____/|______/_/    \_\_| \_|_____/ 

🐊
*/                                                                                                                                
                                                                                                                                  

interface IMetadata {
  function tokenURI(uint256 tokenId, uint256 dna) external view returns (string memory);
}

interface IERC20 {
  function balanceOf(address) external returns(uint);
  function transferFrom(address, address, uint) external;
}

contract Crecodiles is 
    Context,
    AccessControlEnumerable,
    ERC721,
    ERC721Enumerable,
    ERC721Pausable
 {
    using Strings for uint256;
    using Address for address payable;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint public constant MAX_NFT_SUPPLY = 8888;

    uint256 public startIndex;
    bool public isStartingIndexSet;
    bool public isFrozenDNA;
    bool public isFrozenMetadata;
    address payable public beneficiary;

    string public baseTokenURI;
    mapping(uint256 => uint8) public dna; // 0 if not exists, 1 if exists
    uint public tokenTracker;

    mapping(uint256 => uint256) private tokenIdToDNA;
  
    IMetadata public metadata;

    address self = address(this);

    struct Creco {
        uint256 tokenId;
        uint256 dna;
    }
    
    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI, 
        address payable _beneficiary
    ) ERC721(name, symbol) {
        baseTokenURI = _baseTokenURI;
        beneficiary = _beneficiary;

        // set admin permissions
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setMetadataContract(address _contractAddress) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721Access: must have Admin role");
      require(!isFrozenMetadata, "Metadata is final for this collection");
      metadata = IMetadata(_contractAddress);
    }

    function setBeneficiary(address payable _beneficiary) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721Access: must have Admin role");
      beneficiary = _beneficiary;
    }

    function setBaseTokenURI(string memory _uri) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721Access: must have Admin role");
      baseTokenURI = _uri;
    }

    function mintTo(address _to) external returns(uint256) {
      require(hasRole(MINTER_ROLE, _msgSender()), "ERC721Access: must have minter role");
      tokenTracker++;
      require(tokenTracker <= MAX_NFT_SUPPLY, "max supply reached");
      _mint(_to, tokenTracker);
      return tokenTracker;
    }
        
    function setDNA(uint256[] memory tokenIds, uint256[] memory crocDNA) public {
      require(hasRole(MINTER_ROLE, _msgSender()), "ERC721Access: must have minter role");
      require(!isFrozenDNA, "DNA is final for this collection");
      require(tokenIds.length == crocDNA.length, "DNA data missing");
      for (uint i = 0; i < tokenIds.length; i++) {
        uint currentDNA = crocDNA[i];
        uint currentTokenId = tokenIds[i];
        require(_exists(currentTokenId), "DNA for nonexistent token");
        require(dna[currentDNA] == 0, "DNA already exists"); // make sure DNA is unique
        tokenIdToDNA[currentTokenId] = currentDNA;
        dna[currentDNA] = 1;
      }
    }

    function getDnaUnsafe(uint256 position) public view returns(uint256) {
      return tokenIdToDNA[position];
    }

    function getDNA(uint256 tokenId) public view returns(uint256) {
      uint256 dnaIndex = tokenId;
      if (isStartingIndexSet) {
        dnaIndex = (tokenId + startIndex) % MAX_NFT_SUPPLY;
        if (dnaIndex == 0) { // tokenId 0 does not exist 
          dnaIndex = MAX_NFT_SUPPLY;
        }
      }
      return tokenIdToDNA[dnaIndex];
    }

    // returns all the crecodiles a user holds
    function tokensOfOwner(address owner) public view returns (Creco[] memory) {  
      uint balance = balanceOf(owner);
      Creco[] memory crecosOwned = new Creco[](balance);
      for (uint256 i=0; i < balance; i++){
          uint tokenId = tokenOfOwnerByIndex(owner, i);
          crecosOwned[i].tokenId = tokenId;
          crecosOwned[i].dna =  getDNA(tokenId);
      }
      return crecosOwned;
    }

    function freezeDNA() public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721Access: must have Admin role");
      require(tokenTracker == MAX_NFT_SUPPLY, "Collection not finalized");
      isFrozenDNA = true;
    }

    function freezeMetadata() public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721Access: must have Admin role");
      isFrozenMetadata = true;
    }

    function finalizeStartIndexTest() public view returns(uint) {
      uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), blockhash(block.number - 1))));
      uint256 _startIndex = rand % MAX_NFT_SUPPLY;
      return _startIndex;
    }

    // can only be called once 
    function finalizeStartIndex() public {
      require(!isStartingIndexSet, "startIndex has already been set");
      require((tokenTracker == MAX_NFT_SUPPLY), "Not all tokens minted");
      isStartingIndexSet = true;
      uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), blockhash(block.number - 1))));
      startIndex = rand % MAX_NFT_SUPPLY;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      uint256 tokenDNA = getDNA(tokenId);
      if(address(metadata) != address(0x0)) {
        return metadata.tokenURI(tokenId, tokenDNA);
      }
      return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), "/", tokenDNA.toString() )) : "";
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721Access: must have pauser role");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721Access: must have pauser role");
        _unpause();
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
        override(
          AccessControlEnumerable, 
          ERC721, 
          ERC721Enumerable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    } 

    // withdraw helpers in case the contract receives funds by accident
    function withdrawERC20(address tokenAddress) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721Access: must have Admin role");
      IERC20 token = IERC20(tokenAddress);
      token.transferFrom(self, beneficiary, token.balanceOf(self)); // send tokens to safe
    }
}