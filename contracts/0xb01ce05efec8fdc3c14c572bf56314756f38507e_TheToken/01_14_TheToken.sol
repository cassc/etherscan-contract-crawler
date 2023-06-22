// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IEIP2981.sol";

// The Token
// Look beyond the Image, the Token is the only constant.
//
// @artist: Del
// @dev: 0xG

contract TheToken is AdminControl, IEIP2981, ERC1155 {
  struct Royalties {
    address recipient;
    uint256 amount;
  }

  struct Config {
    string[] uris;
    uint256 start;
    uint256 interval;
    bool locked;
    Royalties royalties;
  }

  mapping(uint256 => Config) private _configs;

  constructor() ERC1155("") { }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AdminControl, ERC1155)
    returns (bool)
  {
    return
      AdminControl.supportsInterface(interfaceId) ||
      ERC1155.supportsInterface(interfaceId) ||
      interfaceId == type(IEIP2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function setConfig(uint256 tokenId, Config calldata config_) external adminRequired {
    require(!_configs[tokenId].locked, 'The token is locked and you cannot change its metadata.');
    _configs[tokenId] = config_;
  }

  function lockConfig(uint256 tokenId) external adminRequired {
    _configs[tokenId].locked = true;
  }

  function mint(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external adminRequired {
    for (uint256 i = 0; i < ids.length; ++i) {
      require(!_configs[ids[i]].locked, 'A token is locked and you cannot mint with this configuration.');
    }
    _mintBatch(to, ids, amounts, "");
  }

  function mintWithConfig(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    Config calldata config_
  ) external adminRequired {
    for (uint256 i = 0; i < ids.length; ++i) {
      require(!_configs[ids[i]].locked, 'A token is locked and you cannot mint with this configuration.');
      _configs[ids[i]] = config_;
    }
    _mintBatch(to, ids, amounts, "");
  }

  function burn(
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external adminRequired {
    _burnBatch(_msgSender(), ids, amounts);
  }

  function setGlobalUri(string calldata newuri) external adminRequired {
    _setURI(newuri);
  }

  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    Config memory config = _configs[tokenId];
    if (config.uris.length == 0) {
      return super.uri(tokenId);
    }
    if (config.uris.length == 1 || block.timestamp <= config.start) {
      return config.uris[0];
    }
    uint256 i = ((block.timestamp - config.start) / config.interval) % config.uris.length;
    return config.uris[i < config.uris.length ? i : config.uris.length - 1];
  }

  function setRoyalties(uint256 tokenId, Royalties calldata royaltiesConfig) external adminRequired {
    require(!_configs[tokenId].locked, 'The token is locked and you cannot change its royalties.');
    _configs[tokenId].royalties = royaltiesConfig;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) public override view returns (address, uint256) {
    if (_configs[tokenId].royalties.recipient != address(0)) {
      return (_configs[tokenId].royalties.recipient, salePrice * _configs[tokenId].royalties.amount / 10000);
    }

    return (address(0), 0);
  }

  function withdraw(address recipient) external adminRequired {
    payable(recipient).transfer(address(this).balance);
  }
}