// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

interface IWealth {
  function burnFrom(address account, uint256 amount) external;
}

interface IWealthyTowersApartmentsStaking {
  function stake(uint256[] calldata _tokenIds) external;
}

contract WealthyTowersApartments is ERC721A, ERC721AQueryable, Ownable {
  enum ApartmentTypes {
    None,
    Standard,
    Studio,
    Penthouse
  }

  bool public paused = true;

  uint16 studioCount = 1500;
  uint16 standardCount = 5500;
  uint16 penthouseCount = 777;

  uint16 constant MAX_SUPPLY = 7777;
  uint256 constant APARTMENT_COST = 12000 ether;

  string tokenBaseURI =
    "https://storage.googleapis.com/wasc-apartments/metadata/";

  mapping(address => bool) public projectProxy;
  mapping(uint256 => ApartmentTypes) internal apartmentType;

  IWealth private immutable wealthContract;
  IWealthyTowersApartmentsStaking private apartmentsStakingContract;

  constructor(address _wealthContract)
    ERC721A("Wealthy Towers Apartments", "WTAP")
  {
    wealthContract = IWealth(_wealthContract);
  }

  function mint(uint256 _quantity) external payable {
    require(!paused, "Minting paused");

    wealthContract.burnFrom(msg.sender, APARTMENT_COST * _quantity);

    _internalMint(_quantity);
  }

  function mintAndStake(uint256 _quantity) external payable {
    require(!paused, "Minting paused");

    uint256 _totalSupply = _currentIndex;
    uint256[] memory _mintedTokens = new uint256[](_quantity);

    wealthContract.burnFrom(msg.sender, APARTMENT_COST * _quantity);

    _internalMint(_quantity);

    for (uint256 i = 0; i < _quantity; ++i) {
      _mintedTokens[i] = _totalSupply + i;
    }

    apartmentsStakingContract.stake(_mintedTokens);
  }

  function _internalMint(uint256 _quantity) internal {
    uint256 _totalSupply = _currentIndex;
    uint256 _supplyCount = _totalSupply + _quantity;

    require(_supplyCount <= MAX_SUPPLY, "Exceeds supply");

    unchecked {
      for (uint256 i = _totalSupply; i < _supplyCount; ++i) {
        uint256 _rand = random(i);

        if (_rand <= penthouseCount) {
          penthouseCount--;
          apartmentType[i] = ApartmentTypes.Penthouse;
        } else if (_rand <= studioCount) {
          studioCount--;
          apartmentType[i] = ApartmentTypes.Studio;
        } else if (_rand <= standardCount) {
          standardCount--;
          apartmentType[i] = ApartmentTypes.Standard;
        }
      }
    }

    _mint(msg.sender, _quantity);
  }

  function random(uint256 _salt) internal view returns (uint256) {
    uint256 _totalSupply = getLargestSupply();

    return
      (uint256(
        keccak256(
          abi.encodePacked(msg.sender, block.difficulty, block.timestamp, _salt)
        )
      ) % _totalSupply) + 1;
  }

  function getLargestSupply() internal view returns (uint16) {
    if (standardCount >= studioCount && standardCount >= penthouseCount) {
      return standardCount;
    } else if (studioCount >= standardCount && studioCount >= penthouseCount) {
      return studioCount;
    } else {
      return penthouseCount;
    }
  }

  function getApartmentType(uint256 _tokenId)
    public
    view
    returns (ApartmentTypes)
  {
    return apartmentType[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool)
  {
    if (projectProxy[_operator]) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  function collectReserves() external onlyOwner {
    require(totalSupply() == 0, "Reserves already taken");

    _internalMint(50);
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function flipProxyState(address _proxyAddress) public onlyOwner {
    projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
  }

  function setBaseURI(string calldata _newBaseUri) public onlyOwner {
    tokenBaseURI = _newBaseUri;
  }

  function setApartmentsStakingContract(address _apartmentStakingContract)
    external
    onlyOwner
  {
    apartmentsStakingContract = IWealthyTowersApartmentsStaking(
      _apartmentStakingContract
    );
  }

  function _baseURI() internal view override(ERC721A) returns (string memory) {
    return tokenBaseURI;
  }
}