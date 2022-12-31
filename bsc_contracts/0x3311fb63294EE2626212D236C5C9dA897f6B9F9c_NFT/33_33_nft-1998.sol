// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract NFT is UUPSUpgradeable, ERC721PresetMinterPauserAutoIdUpgradeable {
  using StringsUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev value is equal to keccak256("NFTCollection_v1")
  bytes32 public constant VERSION = 0xc9a7076c8ec22a28cd00112775315d13dbe8d429256fef8fa1cbbdcc8105d2f0;

  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  string public baseExtension;
  string public baseTokenURI;

  address public owner;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmount;

  IERC20Upgradeable public busdContract;

  mapping(address => bool) public whitelisted;

  function init(
    string calldata name_,
    string calldata symbol_,
    string calldata baseTokenURI_,
    IERC20Upgradeable busdContract_
  ) external initializer {
    address sender = _msgSender();

    owner = sender;
    cost = 300 ether;
    maxSupply = 1988;
    maxMintAmount = 350;
    baseExtension = ".json";
    busdContract = busdContract_;
    baseTokenURI = baseTokenURI_;

    __ERC721PresetMinterPauserAutoId_init(name_, symbol_, baseTokenURI_);

    _grantRole(OPERATOR_ROLE, sender);
    
    // _mint(sender, 1);
    for (uint256 i = 1; i <= 350; ) {
      unchecked {
        _safeMint(sender, i);
        ++i;
      }
    }
  }

  event MintItem(uint256 indexed itemId, uint256 indexed tokenId, address owner);

  // public
  function mint(address _to, uint256 _mintAmount) external whenNotPaused {
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    address sender = _msgSender();

    if (!hasRole(MINTER_ROLE, sender)) {
      if (whitelisted[sender] != true) {
          busdContract.safeTransferFrom(sender, owner, cost * _mintAmount);
        }
    }

    for (uint256 i = 1; i <= _mintAmount; ) {
      unchecked {
        _safeMint(_to, supply + i);
        ++i;
      }
    }
  }

  function walletOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = baseTokenURI;
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  //only owner
  function setCost(uint256 _newCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxMintAmount = _newmaxMintAmount;
  }

  function setPaymentToken(IERC20Upgradeable _newBusdContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
    busdContract = _newBusdContract;
  }

  function setBaseURI(string memory _newBaseURI) external onlyRole(OPERATOR_ROLE) {
    baseTokenURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyRole(OPERATOR_ROLE) {
    baseExtension = _newBaseExtension;
  }

  function whitelistUser(address _user) external onlyRole(PAUSER_ROLE) {
    whitelisted[_user] = true;
  }

  function removeWhitelistUser(address _user) external onlyRole(PAUSER_ROLE) {
    whitelisted[_user] = false;
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    (bool ok, ) = owner.call{ value: address(this).balance }("");
    require(ok, "NFT: TRANSFER_FAILED");
  }

  function _authorizeUpgrade(address implement_) internal virtual override onlyRole(UPGRADER_ROLE) {}

  uint256[44] private __gap;
}