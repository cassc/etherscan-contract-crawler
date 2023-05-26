// "SPDX-License-Identifier: MIT"

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IStakingPool {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function burn(address _owner, uint256 _amount) external;
}

interface INftStakingPool {
  function getTokenStamina(uint256 _tokenId, address _nftContractAddress) external view returns (uint256 stamina);
  function mergeTokens(uint256 _newTokenId, uint256[] memory _tokenIds, address _nftContractAddress) external;
}

interface IRainiCustomNFT {
  function onTransfered(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
  function onMerged(uint256 _newTokenId, uint256[] memory _tokenId, address _nftContractAddress, uint256[] memory data) external;
  function onMinted(address _to, uint256 _tokenId, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) external;
  function uri(uint256 id) external view returns (string memory);
}

contract RainiNFT1155v2 is ERC1155, AccessControl {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  address public nftStakingPoolAddress;

  struct CardLevel {
    uint64 conversionRate; // number of base tokens required to create
    uint32 numberMinted;
    uint128 tokenId; // ID of token if grouped, 0 if not
    uint32 maxStamina; // The initial and maxiumum stamina for a token
  }

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

  // userId => cardId => count
  mapping(address => mapping(uint256 => uint256)) public numberMintedByAddress; // Number of a card minted by an address

  mapping(address => bool) public rainbowPools;
  mapping(address => bool) public unicornPools;

  uint256 public maxTokenId;
  uint256 public maxCardId;

  address private contractOwner;

  mapping(uint256 => Card) public cards;
  mapping(uint256 => string) public cardPathUri;
  mapping(uint256 => CardLevel[]) public cardLevels;
  mapping(uint256 => uint256) public mergeFees;
  uint256 public mintingFeeBasisPoints;

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

  function setFees(uint256 _mintingFeeBasisPoints, uint256[] memory _mergeFees) 
    external onlyOwner {
      mintingFeeBasisPoints =_mintingFeeBasisPoints;
      for (uint256 i = 1; i < _mergeFees.length; i++) {
        mergeFees[i] = _mergeFees[i];
      }
  }

  function setNftStakingPoolAddress(address _nftStakingPoolAddress)
    external onlyOwner {
      nftStakingPoolAddress = (_nftStakingPoolAddress);
  }

  function getTokenStamina(uint256 _tokenId)
    external view returns (uint256) {
      if (nftStakingPoolAddress == address(0)) {
        TokenVars memory _tokenVars =  tokenVars[_tokenId];
        require(_tokenVars.cardId != 0, "No token for given ID");
        return cardLevels[_tokenVars.cardId][_tokenVars.level].maxStamina;
      } else {
        INftStakingPool nftStakingPool = INftStakingPool(nftStakingPoolAddress);
        return nftStakingPool.getTokenStamina(_tokenId, address(this));
      }
  }

  function getTotalBalance(address _address) 
    external view returns (uint256[][] memory amounts) {
      uint256[][] memory _amounts = new uint256[][](maxTokenId);
      uint256 count;
      for (uint256 i = 1; i <= maxTokenId; i++) {
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

  function initCards(uint256[] memory _costInUnicorns, uint256[] memory _costInRainbows, uint256[] memory _maxMintsPerAddress,  uint16[] memory _maxSupply, uint256[] memory _allocation, string[] memory _pathUri, address[] memory _subContract, uint32[] memory _mintTimeStart, uint16[][] memory _conversionRates, bool[][] memory _isGrouped, uint256[][] memory _maxStamina)
    external onlyOwner() {

      uint256 _maxCardId = maxCardId;
      uint256 _maxTokenId = maxTokenId;

      for (uint256 i; i < _costInUnicorns.length; i++) {
        require(_conversionRates[i].length == _isGrouped[i].length);

        _maxCardId++;
        cards[_maxCardId] = Card({
            costInUnicorns: uint64(_costInUnicorns[i]),
            costInRainbows: uint64(_costInRainbows[i]),
            maxMintsPerAddress: uint16(_maxMintsPerAddress[i]),
            maxSupply: uint32(_maxSupply[i]),
            allocation: uint32(_allocation[i]),
            mintTimeStart: uint32(_mintTimeStart[i]),
            locked: false,
            subContract: _subContract[i]
          });

        cardPathUri[_maxCardId] = _pathUri[i];
        
        for (uint256 j = 0; j < _conversionRates[i].length; j++) {
          uint256 _tokenId = 0;

          if (_isGrouped[i][j]) {
            _maxTokenId++;
            _tokenId = _maxTokenId;
            tokenVars[_maxTokenId] = TokenVars({
              cardId: uint128(_maxCardId),
              level: uint32(j),
              number: 0,
              mintedContractChar: contractChar
            });
          }

          cardLevels[_maxCardId].push(CardLevel({
            conversionRate: uint64(_conversionRates[i][j]),
            numberMinted: 0,
            tokenId: uint128(_tokenId),
            maxStamina: uint32(_maxStamina[i][j])
          }));
        }
        
      }

      maxTokenId = _maxTokenId;
      maxCardId = _maxCardId;
  }
  
  function _mintToken(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) private {
    Card memory card = cards[_cardId];
    CardLevel memory cardLevel = cardLevels[_cardId][_cardLevel];


    require(_cardLevel > 0 || cardLevel.numberMinted + _amount <= card.maxSupply, "total supply reached.");
    require(_cardLevel == 0 || cardLevel.numberMinted * cardLevel.conversionRate + _amount <= card.maxSupply, "total supply reached.");

    uint256 _tokenId;

    if (cardLevel.tokenId != 0) {
      _tokenId = cardLevel.tokenId;
      _mint(_to, _tokenId, _amount, "");
    } else {
      for (uint256 i = 0; i < _amount; i++) {
        uint256 num;
        if (_number == 0) {
          cardLevel.numberMinted += 1;
          num = cardLevel.numberMinted;
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
      }
    }

    if (card.subContract != address(0)) {
      IRainiCustomNFT subContract = IRainiCustomNFT(card.subContract);
      subContract.onMinted(_to, _tokenId, _cardId, _cardLevel, _amount, _mintedContractChar, _number, _data);
    }

    cardLevels[_cardId][_cardLevel].numberMinted += uint32(_amount);
  }

  function mint(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) 
    external onlyMinter {
      _mintToken(_to, _cardId, _cardLevel, _amount, _mintedContractChar, _number, _data);
  }

  function burn(address _owner, uint256 _tokenId, uint256 _amount, bool _isBridged) 
    external onlyBurner {
      if (_isBridged) {
        TokenVars memory _tokenVars =  tokenVars[_tokenId];
        cardLevels[_tokenVars.cardId][_tokenVars.level].numberMinted -= uint32(_amount);
      }
      _burn(_owner, _tokenId, _amount);
  }

  function lockCard(uint256 _cardId) external onlyOwner {
    cards[_cardId].locked = true;
  }

  function updateCardPathUri(uint256 _cardId, string memory _pathUri) external onlyOwner {
    require(!cards[_cardId].locked, 'card locked');
    cardPathUri[_cardId] = _pathUri;
  }

  function updateCardSubContract(uint256 _cardId, address _contractAddress) external onlyOwner {
    require(!cards[_cardId].locked, 'card locked');
    cards[_cardId].subContract = _contractAddress;
  }

  function addToNumberMintedByAddress(address _address, uint256 _cardId, uint256 _amount) external onlyMinter {
    numberMintedByAddress[_address][_cardId] += _amount;
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
      return string(abi.encodePacked(baseUri, cardPathUri[_tokenVars.cardId], "/", _tokenVars.mintedContractChar, "l", uint2str(_tokenVars.level), "n", uint2str(_tokenVars.number), ".json"));
    } else {
      IRainiCustomNFT subContract = IRainiCustomNFT(cards[_tokenVars.cardId].subContract);
      return subContract.uri(id);
    }
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  function contractURI() public view returns (string memory) {
      return contractURIString;
  }

  function owner() public view virtual returns (address) {
    return contractOwner;
  }

  // Allow the owner to withdraw Ether payed into the contract
  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "not enough balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "transfer failed");
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