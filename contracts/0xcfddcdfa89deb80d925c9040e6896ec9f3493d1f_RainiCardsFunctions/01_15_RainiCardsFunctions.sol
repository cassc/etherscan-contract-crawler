// "SPDX-License-Identifier: MIT"

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IStakingPool {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function burn(address _owner, uint256 _amount) external;
}

interface IRainiCardPacks is IERC721 {

  struct PackType {
    uint32 packClassId;
    uint64 costInUnicorns;
    uint64 costInRainbows;
    uint64 costInEth;
    uint16 maxMintsPerAddress;
    uint32 tokenIdStart;
    uint32 supply;
    uint32 mintTimeStart;
  }

  function packTypes(uint256 _id) external view returns (PackType memory);
  function numberOfPackMinted(uint256 _packTypeId) external view returns (uint256);
  function numberMintedByAddress(address _address, uint256 _packTypeId) external view returns (uint256);

  function mint(address _to, uint256 _packTypeId, uint256 _amount) external;
  function burn(uint256 _tokenId) external;
  function addToNumberMintedByAddress(address _address, uint256 _packTypeId, uint256 amount) external;
}

interface IRainiNft1155 is IERC1155 {
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

  function maxTokenId() external view returns (uint256);
  function contractChar() external view returns (bytes1);

  function numberMintedByAddress(address _address, uint256 _cardID) external view returns (uint256);

  function burn(address _owner, uint256 _tokenId, uint256 _amount, bool _isBridged) external;

  function getPathUri(uint256 _cardId) view external returns (string memory);

  function cards(uint256 _cardId) external view returns (Card memory);
  function cardLevels(uint256 _cardId, uint256 _level) external view returns (CardLevel memory);
  function tokenVars(uint256 _tokenId) external view returns (TokenVars memory);

  function mint(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) external;
  function addToNumberMintedByAddress(address _address, uint256 _cardId, uint256 amount) external;
}

contract RainiCardsFunctions is AccessControl, ReentrancyGuard {
  
  using ECDSA for bytes32;

  address public nftStakingPoolAddress;

  uint256 public constant POINT_COST_DECIMALS = 1000000000000000000;

  uint256 public rainbowToEth;
  uint256 public unicornToEth;
  uint256 public minPointsPercentToMint;

  mapping(address => bool) public rainbowPools;
  mapping(address => bool) public unicornPools;

  uint256 public mintingFeeBasisPoints;

  address public verifier;

  IRainiNft1155 nftContract;
  IRainiCardPacks packsContact;

  constructor(address _nftContractAddress, address _packsContact, address _contractOwner, address _verifier) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
    nftContract = IRainiNft1155(_nftContractAddress);
    packsContact = IRainiCardPacks(_packsContact);
    verifier = _verifier;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    _;
  }

  function getPackBalances(address _address, uint256 _start, uint256 _end) 
    external view returns (uint256[][] memory amounts) {
      uint256[][] memory _amounts = new uint256[][](_end - _start);
      uint256 count;
      for (uint256 i = _start; i <= _end; i++) {
        try packsContact.ownerOf(i) returns (address a) {
          if (a == _address) {
            _amounts[count] = new uint256[](2);
            _amounts[count][0] = i;
            _amounts[count][1] = 1;
            count++;
          }
        } catch Error(string memory /*reason*/) {
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

  function setPacksContract(address _packsContact)
    external onlyOwner {
      packsContact = IRainiCardPacks(_packsContact);
  }

  function setNftContract(address _nftContractAddress)
    external onlyOwner {
      nftContract = IRainiNft1155(_nftContractAddress);
  }

  function addRainbowPool(address _rainbowPool) 
    external onlyOwner {
      rainbowPools[_rainbowPool] = true;
  }

  function removeRainbowPool(address _rainbowPool) 
    external onlyOwner {
      rainbowPools[_rainbowPool] = false;
  }

  function addUnicornPool(address _unicornPool) 
    external onlyOwner {
      unicornPools[_unicornPool] = true;
  }

  function removeUnicornPool(address _unicornPool) 
    external onlyOwner {
      unicornPools[_unicornPool] = false;
  }

  function setEtherValues(uint256 _unicornToEth, uint256 _rainbowToEth, uint256 _minPointsPercentToMint)
     external onlyOwner {
      unicornToEth = _unicornToEth;
      rainbowToEth = _rainbowToEth;
      minPointsPercentToMint = _minPointsPercentToMint;
   }

  function setFees(uint256 _mintingFeeBasisPoints) 
    external onlyOwner {
      mintingFeeBasisPoints =_mintingFeeBasisPoints;
  }

  function setNftStakingPoolAddress(address _nftStakingPoolAddress)
    external onlyOwner {
      nftStakingPoolAddress = (_nftStakingPoolAddress);
  }

  function setVerifierAddress(address _verifier) 
    external onlyOwner {
      verifier = _verifier;
  }
  
  function openPacks(uint256[][] memory _cardId, uint256[][] memory _amount, bytes[] memory sig, uint256[] memory _salt, uint256[] memory _packId)
    external nonReentrant {

    for (uint256 i = 0; i < _cardId.length; i++) {
      require (packsContact.ownerOf(_packId[i]) == address(_msgSender()), 'not the owner');
      bytes memory _hashingString = abi.encode(_salt[i], _packId[i]);
      for (uint256 j = 0; j < _cardId[i].length; j++) {
        _hashingString = abi.encode(_hashingString, _cardId[i][j], _amount[i][j]);
      }
      bytes32 _hash = keccak256(_hashingString);
      address signer = ECDSA.recover(_hash.toEthSignedMessageHash(), sig[i]);
      require (signer == verifier, "Invalid sig");
    }

    for (uint256 i = 0; i < _cardId.length; i++) {
      packsContact.burn(_packId[i]);
      for (uint256 j = 0; j < _cardId[i].length; j++) {
        nftContract.mint(_msgSender(), _cardId[i][j], 0, _amount[i][j], nftContract.contractChar(), 0, new uint256[](0));
      }
    }
  }

struct BuyPacksData {
    uint256 totalPriceRainbows;
    uint256 totalPriceUnicorns;
    uint256 minCostRainbows;
    uint256 minCostUnicorns;
    uint256 fee;
    uint256 amountEthToWithdraw;
    bool success;
  }
  
  
  function buyPacks(uint256[] memory _packType, uint256[] memory _amount, bool[] memory _useUnicorns, uint256[][] memory _data, address[] memory _rainbowPools, address[] memory _unicornPools)
    external payable nonReentrant {

    BuyPacksData memory _locals = BuyPacksData({
      totalPriceRainbows: 0,
      totalPriceUnicorns: 0,
      minCostRainbows: 0,
      minCostUnicorns: 0,
      fee: 0,
      amountEthToWithdraw: 0,
      success: false
    });

    bool[] memory addToMaxMints = new bool[](_packType.length);

    for (uint256 i = 0; i < _packType.length; i++) {
      IRainiCardPacks.PackType memory packType = packsContact.packTypes(_packType[i]);

      require(block.timestamp >= packType.mintTimeStart || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'too early');
      require(packType.maxMintsPerAddress == 0 || (packsContact.numberMintedByAddress(_msgSender(), _packType[i]) + _amount[i] <= packType.maxMintsPerAddress), "Max mints reached for address");
      addToMaxMints[i] = packType.maxMintsPerAddress > 0;

      uint256 numberMinted = packsContact.numberOfPackMinted(_packType[i]);
      if (numberMinted + _amount[i] > packType.supply) {
        _amount[i] = packType.supply - numberMinted;
      }

      if (packType.costInUnicorns > 0 || packType.costInRainbows > 0) {
        if (_useUnicorns[i]) {
          require(packType.costInUnicorns > 0, "unicorns not allowed");
          uint256 cost = packType.costInUnicorns * _amount[i] * POINT_COST_DECIMALS;
          _locals.totalPriceUnicorns += cost;
          if (packType.costInEth > 0) {
            _locals.minCostUnicorns += cost;
          }
        } else {
          require(packType.costInRainbows > 0, "rainbows not allowed");
          uint256 cost = packType.costInRainbows * _amount[i] * POINT_COST_DECIMALS;
          _locals.totalPriceRainbows += cost;
          if (packType.costInEth > 0) {
            _locals.minCostRainbows += cost;
          }
        }

        if (packType.costInEth == 0) {
          if (packType.costInRainbows > 0) {
            _locals.fee += (packType.costInRainbows * _amount[i] * POINT_COST_DECIMALS * mintingFeeBasisPoints) / (rainbowToEth * 10000);
          } else {
            _locals.fee += (packType.costInUnicorns * _amount[i] * POINT_COST_DECIMALS * mintingFeeBasisPoints) / (unicornToEth * 10000);
          }
        }
      }
      
      _locals.amountEthToWithdraw += packType.costInEth * _amount[i];
    }
    
    if (_locals.totalPriceUnicorns > 0 || _locals.totalPriceRainbows > 0 ) {
      for (uint256 n = 0; n < 2; n++) {
        bool loopTypeUnicorns = n > 0;

        uint256 totalBalance = 0;
        uint256 totalPrice = loopTypeUnicorns ? _locals.totalPriceUnicorns : _locals.totalPriceRainbows;
        uint256 remainingPrice = totalPrice;

        if (totalPrice > 0) {
          uint256 loopLength = loopTypeUnicorns ? _unicornPools.length : _rainbowPools.length;

          require(loopLength > 0, "invalid pools");

          for (uint256 i = 0; i < loopLength; i++) {
            IStakingPool pool;
            if (loopTypeUnicorns) {
              require((unicornPools[_unicornPools[i]]), "invalid unicorn pool");
              pool = IStakingPool(_unicornPools[i]);
            } else {
              require((rainbowPools[_rainbowPools[i]]), "invalid rainbow pool");
              pool = IStakingPool(_rainbowPools[i]);
            }
            uint256 _balance = pool.balanceOf(_msgSender());
            totalBalance += _balance;

            if (totalBalance >=  totalPrice) {
              pool.burn(_msgSender(), remainingPrice);
              remainingPrice = 0;
              break;
            } else {
              pool.burn(_msgSender(), _balance);
              remainingPrice -= _balance;
            }
          }

          if (remainingPrice > 0) {
            totalPrice -= loopTypeUnicorns ? _locals.minCostUnicorns : _locals.minCostRainbows;
            uint256 minPoints = (totalPrice * minPointsPercentToMint) / 100;
            require(totalPrice - remainingPrice >= minPoints, "not enough balance");
            uint256 pointsToEth = loopTypeUnicorns ? unicornToEth : rainbowToEth;
            require(msg.value * pointsToEth > remainingPrice, "not enough balance");
            _locals.amountEthToWithdraw += remainingPrice / pointsToEth;
          }
        }
      }
    }

    // Add minting fees
    _locals.amountEthToWithdraw += _locals.fee;

    require(_locals.amountEthToWithdraw <= msg.value);

    (_locals.success, ) = _msgSender().call{ value: msg.value - _locals.amountEthToWithdraw }(""); // refund excess Eth
    require(_locals.success, "transfer failed");

    bool _tokenMinted = false;
    for (uint256 i = 0; i < _packType.length; i++) {
      if (_amount[i] > 0) {
        if (addToMaxMints[i]) {
          packsContact.addToNumberMintedByAddress(_msgSender(), _packType[i], _amount[i]);
        }
        packsContact.mint(_msgSender(), _packType[i], _amount[i]);
        _tokenMinted = true;
      }
    }
    require(_tokenMinted, 'Allocation exhausted');
  }



  // Allow the owner to withdraw Ether payed into the contract
  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "not enough balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "transfer failed");
  }
}