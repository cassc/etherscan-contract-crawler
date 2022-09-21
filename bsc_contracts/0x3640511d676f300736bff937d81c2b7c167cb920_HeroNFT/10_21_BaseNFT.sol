// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../libs/fota/ArrayUtil.sol";
import "../libs/fota/NFTAuth.sol";

abstract contract BaseNFT is NFTAuth, ERC721Upgradeable {

  mapping (uint16 => address) public creators;
  mapping (address => uint) public nonces;

  uint private constant idDivider = 100000000;
  bool burning;

  event OwnPriceUpdated(
    uint tokenId,
    uint ownPrice
  );
  event AllOwnPriceUpdated(
    uint tokenId,
    uint ownPrice,
    uint fotaOwnPrice
  );
  event MinPriceUpdated(
    uint tokenId,
    uint minPrice
  );

  function initialize(
    address _mainAdmin,
    string calldata _name,
    string calldata _symbol
  ) virtual public {
    NFTAuth.initialize(_mainAdmin);
    ERC721Upgradeable.__ERC721_init(_name, _symbol);
  }

  function setCreator(uint16 _class, address _creator) onlyMainAdmin external {
    creators[_class] = _creator;
  }

  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    burning = true;
    _burn(tokenId);
    burning = false;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint _tokenId
  ) virtual internal override {
    if (!burning) {
      require(_isMintAdmin() || _isTransferAble(), "NFT: no transferable right");
    }
    _from;
    _to;
    _tokenId;
  }

  function _genNewId(uint _index) internal view returns (uint) {
    uint tokenId = block.timestamp % idDivider + _index;
    while(_exists(tokenId)) {
      tokenId = block.timestamp % idDivider * 10 + ++_index;
    }
    return tokenId;
  }

  function updateOwnPrice(uint _tokenId, uint _ownPrice) virtual external;
  function getCreator(uint _tokenId) virtual external returns (address);
}