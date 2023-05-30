// "SPDX-License-Identifier: MIT"

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IStakingPool {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function burn(address _owner, uint256 _amount) external;
}

interface IRainiCustomNFT {
  function onTransfered(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
  function onMerged(uint256 _newTokenId, uint256[] memory _tokenId, address _nftContractAddress, uint256[] memory data) external;
  function onMinted(address _to, uint256 _tokenId, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) external;
  function uri(uint256 id) external view returns (string memory);
}

contract RainiCards is ERC1155, AccessControl {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  address public nftStakingPoolAddress;

  struct Card {
    uint64 costInUnicorns;
    uint64 costInRainbows;
    uint16 maxMintsPerAddress;
    uint32 maxSupply; // number of base tokens mintable
    uint32 allocation; // number of base tokens mintable with points on this contract
    uint32 mintTimeStart; // the timestamp from which the card can be minted
    bool locked;
    address subContract;
  }

  struct TokenVars {
    uint128 cardId;
    uint32 level;
    uint32 number; // to assign a numbering to NFTs
    bytes1 mintedContractChar;
  }

  string public baseUri;
  bytes1 public contractChar;
  string public contractURIString;

  mapping(address => bool) public rainbowPools;
  mapping(address => bool) public unicornPools;

  uint256 public maxTokenId = 1000000;

  address private contractOwner;

  mapping(uint256 => Card) public cards;
  
  mapping(uint256 => uint256) public numLevel1Minted;

  mapping(uint256 => TokenVars) public tokenVars;


  constructor(string memory _uri, bytes1 _contractChar, string memory _contractURIString, address _contractOwner) 
    ERC1155(_uri) {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(BURNER_ROLE, _msgSender());
    baseUri = _uri;
    contractOwner = _contractOwner;
    contractChar = _contractChar;
    contractURIString = _contractURIString;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "caller is not a minter");
    _;
  }

  modifier onlyBurner() {
    require(hasRole(BURNER_ROLE, _msgSender()), "caller is not a burner");
    _;
  }

  function setcontractURI(string memory _contractURIString)
    external onlyOwner {
      contractURIString = _contractURIString;
  }

  function setNftStakingPoolAddress(address _nftStakingPoolAddress)
    external onlyOwner {
      nftStakingPoolAddress = (_nftStakingPoolAddress);
  }

  function setBaseURI(string memory _baseURIString)
    external onlyOwner {
      baseUri = _baseURIString;
  }

  function getTotalBalance(address _address, uint256 _cardCount) 
    external view returns (uint256[][] memory amounts) {
      uint256[][] memory _amounts = new uint256[][](maxTokenId - 1000000 + _cardCount);
      uint256 count;
      for (uint256 i = 1; i <= maxTokenId; i++) {
        if (tokenVars[i].cardId == 0 && i < 1000001) {
          i = 1000001;
        }
        uint256 balance = balanceOf(_address, i);
        if (balance != 0) {
          _amounts[count] = new uint256[](2);
          _amounts[count][0] = i;
          _amounts[count][1] = balance;
          count++;
        }
      }

      uint256[][] memory _amounts2 = new uint256[][](count);
      for (uint256 i = 0; i < count; i++) {
        _amounts2[i] = new uint256[](2);
        _amounts2[i][0] = _amounts[i][0];
        _amounts2[i][1] = _amounts[i][1];
      }

      return _amounts2;
  }


  struct MergeData {
    uint256 cost;
    uint256 totalPointsBurned;
    uint256 currentTokenToMint;
    bool willCallPool;
    bool willCallSubContract;
  }

  function initCards(uint256[] memory _cardId, uint16[] memory _maxSupply, address[] memory _subContract)
    external onlyOwner() {

      for (uint256 i; i < _cardId.length; i++) {

        cards[_cardId[i]] = Card({
            costInUnicorns: 0,
            costInRainbows: 0,
            maxMintsPerAddress: 0,
            maxSupply: uint32(_maxSupply[i]),
            allocation: uint32(_maxSupply[i]),
            mintTimeStart: 0,
            locked: false,
            subContract: _subContract[i]
          });
        
        uint256 _tokenId = 0;

        _tokenId = _cardId[i];
        tokenVars[_tokenId] = TokenVars({
          cardId: uint128(_cardId[i]),
          level: 0,
          number: 0,
          mintedContractChar: contractChar
        });
      }
  }
  
  function _mintToken(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) private {
    Card memory card = cards[_cardId];
    uint256 _level1Minted = numLevel1Minted[_cardId];
    
    uint256 _tokenId;

    if (_cardLevel == 0) {
      _mint(_to, _cardId, _amount, "");
    } else {
      for (uint256 i = 0; i < _amount; i++) {
        uint256 num;
        if (_number == 0) {
          _level1Minted += 1;
          num = _level1Minted;
        } else {
          num = _number;
        }

        uint256 _maxTokenId = maxTokenId;
        _maxTokenId++;
        _tokenId = _maxTokenId;
        _mint(_to, _tokenId, 1, "");
        tokenVars[_maxTokenId] = TokenVars({
          cardId: uint128(_cardId),
          level: uint32(_cardLevel),
          number: uint32(num),
          mintedContractChar: _mintedContractChar
        });

        maxTokenId = _maxTokenId;
        numLevel1Minted[_cardId] += uint32(_amount);
      }
    }

    if (card.subContract != address(0)) {
      IRainiCustomNFT subContract = IRainiCustomNFT(card.subContract);
      subContract.onMinted(_to, _tokenId, _cardId, _cardLevel, _amount, _mintedContractChar, _number, _data);
    }
  }

  function mint(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) 
    external onlyMinter {
      _mintToken(_to, _cardId, _cardLevel, _amount, _mintedContractChar, _number, _data);
  }

  function burn(address _owner, uint256 _tokenId, uint256 _amount) 
    external onlyBurner {
      _burn(_owner, _tokenId, _amount);
  }

  function updateCardSubContract(uint256 _cardId, address _contractAddress) external onlyOwner {
    cards[_cardId].subContract = _contractAddress;
  }

  function supportsInterface(bytes4 interfaceId) 
    public virtual override(ERC1155, AccessControl) view returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
  }

  function uri(uint256 id) public view virtual override returns (string memory) {
    TokenVars memory _tokenVars =  tokenVars[id];
    require(_tokenVars.cardId != 0, "No token for given ID");

    if (cards[_tokenVars.cardId].subContract == address(0)) {
      return string(abi.encodePacked(baseUri, "?cid=", Strings.toString(_tokenVars.cardId), "&chain=", _tokenVars.mintedContractChar, "&t=", Strings.toString(id), "&l=", Strings.toString(_tokenVars.level), "&n=", Strings.toString(_tokenVars.number) ));
    } else {
      IRainiCustomNFT subContract = IRainiCustomNFT(cards[_tokenVars.cardId].subContract);
      return subContract.uri(id);
    }
  }

  function contractURI() public view returns (string memory) {
      return contractURIString;
  }

  function owner() public view virtual returns (address) {
    return contractOwner;
  }

  function _beforeTokenTransfer(address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data)
    internal virtual override
  {
    for (uint256 i = 0; i < ids.length; i++) {
      TokenVars memory _tokenVars = tokenVars[ids[i]];
      if (cards[_tokenVars.cardId].subContract != address(0)) {
        IRainiCustomNFT subContract = IRainiCustomNFT(cards[_tokenVars.cardId].subContract);
        subContract.onTransfered(from, to, ids[i], amounts[i], data);
      }
    }
  }

}