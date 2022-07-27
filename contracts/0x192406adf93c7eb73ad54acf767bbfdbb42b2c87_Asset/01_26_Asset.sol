// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC4907.sol";
import "./ERC721Blacklisted.sol";
import "../lib/PausableOwned.sol";
import "../lib/Minterable.sol";
import "../Error.sol";

contract Asset is ERC721Enumerable, ERC721Burnable, ERC721Blacklisted, ERC2981, ERC4907, PausableOwned, Minterable {
  using Address for address;
  
  // Base token URI
  string public baseTokenURI;

  // Last token ID
  uint256 public tokenId;

  event LogMinted(
    address indexed account, 
    uint256 indexed tokenId
  );

  event LogBurnt(uint256 indexed tokenId);

  event LogBaseTokenURISet(string baseTokenURI);

  /**
   * @dev Throw if minting allowance is exceeded for non owner minter
   * @param _address minter wallet
   * @param _amount minting amount
   */
  modifier decreaseValidAllowance(
    address _address,
    uint256 _amount
  ) {
    if (_address != owner()) super._decreaseAllowance(_address, _amount);

    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    uint256 _lastTokenId
  ) ERC4907(_name, _symbol) {
    baseTokenURI = _baseTokenURI;
    tokenId = _lastTokenId;
  }

  /**
   * @dev Set base token uri
   *
   * Requirements:
   * - Only `owner` can call
   * @param _baseTokenURI new base token uri string
   */
  function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
    if (keccak256(abi.encodePacked(_baseTokenURI)) == keccak256(abi.encodePacked(baseTokenURI))) {
      revert NoChangeToTheState();
    }

    baseTokenURI = _baseTokenURI;
    emit LogBaseTokenURISet(_baseTokenURI);
  }

  /**
   * See {ERC2981-_setDefaultRoyalty}
   *
   * Requirements:
   * - Only `owner` can call
   */
  function setDefaultRoyalty(
    address _receiver, 
    uint96 _feeNumerator
  ) external onlyOwner {
    super._setDefaultRoyalty(_receiver, _feeNumerator);
  }

  /**
   * See {ERC2981-_deleteDefaultRoyalty}
   *
   * Requirements:
   * - Only `owner` can call
   */
  function deleteDefaultRoyalty() external onlyOwner {
    super._deleteDefaultRoyalty();
  }

  /**
   * See {ERC2981-_setTokenRoyalty}
   *
   * Requirements:
   * - Only `owner` can call
   */
  function setTokenRoyalty(
    uint256 _tokenId,
    address _receiver,
    uint96 _feeNumerator
  ) external onlyOwner {
    super._setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  /**
   * See {ERC2981-_resetTokenRoyalty}
   *
   * Requirements:
   * - Only `owner` can call
   */
  function resetTokenRoyalty(uint256 _tokenId) external onlyOwner {
    super._resetTokenRoyalty(_tokenId);
  }
  
  /**
   * @dev Mint a new token
   *
   * Requirements:
   * - Only minter can call (contract owner is minter)
   * - Check minting allowance for non owner minter
   * @param _account receiver wallet
   * @return newTokenId incremented new token id
   */
  function mint(address _account) 
    external 
    onlyMinter 
    decreaseValidAllowance(msg.sender, 1) 
    returns (uint256 newTokenId) 
  {
    unchecked { 
      // we will not overflow on `tokenId` in a lifetime
      newTokenId = ++tokenId;
    }
    
    super._mint(_account, newTokenId);
    emit LogMinted(_account, newTokenId);
  }

  /**
   * @dev Mint a new token for cross-chain transfer
   *
   * Requirements:
   * - Only bridge contract can call (bridge contract is minter)
   * - Check minting allowance for bridge contract
   * @param _account receiver wallet
   * @param _tokenId minting token id
   */
  function mint(
    address _account,
    uint256 _tokenId
  ) external 
    onlyMinter 
    decreaseValidAllowance(msg.sender, 1) 
  {
    super._mint(_account, _tokenId);
    emit LogMinted(_account, _tokenId);
  }

  /**
   * @dev Mint a batch of tokens
   * Zero amount check is done in {Minterable:_decreaseAllowance}
   *
   * Requirements:
   * - Only minter can call (contract owner is minter)
   * - Check minting allowance for non owner minter
   * @param _account receiver wallet
   * @param _amount minting amount; must not be zero
   */
  function mintBatch(
    address _account,
    uint256 _amount
  ) external onlyMinter decreaseValidAllowance(msg.sender, _amount) {
    unchecked { 
      // we are not accepting enough data to overflow on `_amount`
      for (uint256 i = 0; i < _amount; i++) {
        // we will not overflow on `tokenId` in a lifetime
        uint256 newTokenId = ++tokenId; 
        super._mint(_account, newTokenId);
        emit LogMinted(_account, newTokenId);
      }      
    }
  }

  /**
   * @dev Mint a batch of tokens for cross-chain transfer
   *
   * Requirements:
   * - Only bridge contract can call (bridge contract is minter)
   * - Check minting allowance for bridge contract
   * @param _account receiver wallet
   * @param _tokenIds array of minting token id; must not have zero
   */
  function mintBatch(
    address _account,
    uint256[] calldata _tokenIds
  ) external onlyMinter decreaseValidAllowance(msg.sender, _tokenIds.length) {
    unchecked { 
      // we are not accepting enough data to overflow on `_tokenIds`
      for (uint256 i = 0; i < _tokenIds.length; i++) {
        super._mint(_account, _tokenIds[i]);
        emit LogMinted(_account, _tokenIds[i]);
      }      
    }
  }

  /**
   * Override {ERC721Burnable-burn}
   */
  function burn(uint256 _tokenId) public override {
    ERC721Burnable.burn(_tokenId);
    emit LogBurnt(_tokenId);
  }

  /**
   * Override {Minterable-transferOwnership}
   */
  function transferOwnership(address _newOwner) public virtual override(Ownable, Minterable) {
    Minterable.transferOwnership(_newOwner);
  }
  
  /**
   * Override {IERC165-supportsInterface}
   */
  function supportsInterface(bytes4 _interfaceId) 
    public 
    view 
    virtual 
    override(ERC721, ERC721Enumerable, ERC2981, AccessControl, ERC4907)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  /**
   * Disable token transfer:
   * - from/to blacklisted wallets
   * - when paused
   */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal override(ERC721, ERC721Enumerable, ERC721Blacklisted, ERC4907) whenNotPaused {
    ERC721Blacklisted._beforeTokenTransfer(_from, _to, _tokenId);
    ERC721Enumerable._beforeTokenTransfer(_from, _to, _tokenId);
    ERC4907._beforeTokenTransfer(_from, _to, _tokenId);
  }
  
  /**
   * Override {ERC721:_baseURI}
   */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }
}