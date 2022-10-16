// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import './token/ERC721/ERC721.sol';
import './token/ERC721/extensions/ERC721Enumerable.sol';
import './token/ERC721/extensions/ERC721URIStorage.sol';
import './security/Pausable.sol';
import './access/Ownable.sol';
import './access/AccessControl.sol';
import './token/ERC721/extensions/ERC721Burnable.sol';

contract BestarzNFT is
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  Pausable,
  AccessControl,
  ERC721Burnable
{
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  string private _name = 'Bestarz NFT';
  string private _symbol = 'BESTARZ';

  bool _publicMint = true;

  constructor() ERC721(_name, _symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
  }

  function pause() public {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      'BestarzNFT: must have pauser role to pause'
    );
    _pause();
  }

  function unpause() public {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      'BestarzNFT: must have pauser role to pause'
    );
    _unpause();
  }

  function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string memory uri
  ) public returns (bool) {
    if (!_publicMint) {
      require(
        hasRole(MINTER_ROLE, _msgSender()),
        'BestarzNFT: must have minter role to mint'
      );
    }
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
    return true;
  }

  function mintMultiple(
    address[] memory to,
    uint256[] memory tokenId,
    string[] memory uri
  ) public returns (bool) {
    if (!_publicMint) {
      require(
        hasRole(MINTER_ROLE, _msgSender()),
        'BestarzNFT: must have minter role to mint'
      );
    }
    for (uint256 i = 0; i < to.length; i++) {
      _safeMint(to[i], tokenId[i]);
      _setTokenURI(tokenId[i], uri[i]);
    }
    return true;
  }

  function safeTransfer(
    address to,
    uint256 tokenId,
    bytes calldata data
  ) public virtual {
    super._safeTransfer(_msgSender(), to, tokenId, data);
  }

  function safeTransfer(address to, uint256 tokenId) public virtual {
    super._safeTransfer(_msgSender(), to, tokenId, '');
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}