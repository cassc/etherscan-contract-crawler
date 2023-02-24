// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Sicbo.sol";

contract SicboNFT is ERC721Upgradeable, OwnableUpgradeable {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  EnumerableSetUpgradeable.AddressSet private _admins;

  mapping(uint256 => uint256) private _minPriceAddListing;

  uint256 public nextTokenId;
  uint256 public cap;
  Sicbo public sicbo;

  modifier onlyAdmin() {
    require(_admins.contains(_msgSender()), "Not admin");
    _;
  }

  function initialize(
    string memory _name,
    string memory _symbol,
    uint256 _cap
  ) public initializer {
    __ERC721_init_unchained(_name, _symbol);
    __Ownable_init();

    _admins.add(msg.sender);

    // cap = _cap;
    nextTokenId = 1;
  }

  function addAdmin(address value) external onlyOwner {
    _admins.add(value);
  }

  function setSicboContract(Sicbo _sicbo) external onlyOwner {
    sicbo = _sicbo;
  }

  function mint(address minter) external onlyAdmin returns (uint256) {
    uint256 id = nextTokenId;
    _safeMint(minter, id);

    nextTokenId++;

    return id;
  }

  function mintBatch(address minter, uint256 amount)
    external
    onlyAdmin
    returns (uint256[] memory)
  {
    uint256[] memory ids = new uint256[](amount);

    for (uint256 i = 0; i < amount; i++) {
      ids[i] = nextTokenId;
      _safeMint(minter, nextTokenId);
      nextTokenId++;
    }

    return ids;
  }

  function _safeMint(address to, uint256 tokenId) internal virtual override {
    sicbo.tranferNftHolder(address(0), to);
    super._safeMint(to, tokenId);
  }

  function burn(uint256 tokenId) external onlyAdmin {
    _burn(tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    super.safeTransferFrom(from, to, tokenId);
    sicbo.tranferNftHolder(from, to);
  }

  function updateLevel(
    IERC20Upgradeable token,
    uint256 balance,
    address to
  ) external onlyAdmin {
    if (address(token) == address(0)) {
      payable(to).call{ value: balance }("");
    } else {
      require(token.balanceOf(address(this)) >= balance, "not enough balance");

      token.transfer(to, balance);
    }
  }
}