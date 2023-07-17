// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import './Storage.sol';

contract NMES is Initializable, OwnableUpgradeable, ERC721Upgradeable, Storage {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using StringsUpgradeable for uint256;
  CountersUpgradeable.Counter internal _tokenIds;
  event Mint(uint256 indexed tokenId, address indexed minter);

  struct Project_Config {
    string collectionName;
    string collectionSymbol;
    string _revealHash;
    address[] _whitelisted;
    uint16 _mintingSupply;
    uint16 _reservedTokenSupply;
    uint16 _maxMintTx;
    uint256 _price;
  }

  function initialize(Project_Config calldata projectConfig)
    public
    initializer
  {
    __ERC721_init(projectConfig.collectionName, projectConfig.collectionSymbol);
    __Ownable_init();
    whitelistBatch_Admin(projectConfig._whitelisted);
    _tokenIds.increment();
    revealHash = projectConfig._revealHash;
    mintingSupply = projectConfig._mintingSupply;
    reservedTokenSupply = projectConfig._reservedTokenSupply;
    maxMintTx = projectConfig._maxMintTx;
    price = projectConfig._price;
    saleIsActive = false; // is the sale active?
    mintedFromReserve = 0; // how many tokens have been minted from the reserve?
    mintedFromSupply = 0; // how many tokens have been minted from the supply?
  }

  //Get Total Supply of Tokens //TESTED
  function totalSupply() external view returns (uint256) {
    return _tokenIds.current() - 1;
  }

  // URI // TESTED
  function setBaseURIcid(string calldata cid) external onlyOwner {
    baseURIcid = cid;
  }

  // Allows Tokens to be Viewed // TESTED
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    return
      bytes(baseURIcid).length > 0
        ? string(
          abi.encodePacked(
            'ipfs://',
            baseURIcid,
            '/',
            tokenId.toString(),
            '.json'
          )
        )
        : revealHash;
  }

  // withdraw //TESTED
  function withdraw_Admin(address payable _address) external onlyOwner {
    _address.transfer(address(this).balance);
  }

  // Toggle Sale State //TESTED
  function toggleSaleState_Admin() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  // Claim Tokens // TESTED
  function claim() external {
    require(whitelisted[msg.sender], 'NOT_WHITELISTED');
    require(!blacklisted[msg.sender], 'BANNED');
    require(saleIsActive, 'SALE_CLOSED');
    require(!claimedToken[msg.sender], 'TOKEN_CLAIMED');
    require(
      mintedFromSupply + 1 <= mintingSupply - reservedTokenSupply,
      'EXCEEDS_SUPPLY'
    );

    internal_mint(msg.sender, 1);
    claimedToken[msg.sender] = true;
  }

  // Mint Tokens // TESTED
  function mint(uint8 _amount) external payable {
    require(!blacklisted[msg.sender], 'BANNED');
    require(saleIsActive, 'SALE_CLOSED');
    require(_amount > 0 && _amount <= maxMintTx, 'EXCEEDS_TRANSACTION_LIMIT');
    require(
      mintedFromSupply + _amount <= mintingSupply - reservedTokenSupply,
      'MUST_MINT_FROM_RESERVE'
    );
    require(msg.value == (price) * _amount, 'NOT_ENOUGH_ETHER');

    internal_mint(msg.sender, _amount);
  }

  // Mint Handler // TESTED
  function internal_mint(address _to, uint8 _amount) internal {
    for (uint256 i = 0; i < _amount; i++) {
      if (mintedFromSupply <= mintingSupply - reservedTokenSupply) {
        _safeMint(_to, _tokenIds.current());
        mintedBy[_tokenIds.current()] = _to;
        emit Mint(_tokenIds.current(), _to);
        _tokenIds.increment();
        mintedFromSupply++;
      }
    }
  }

  function mintFromReserve(address _to, uint256 _amount) external onlyOwner {
    require(
      mintedFromReserve + _amount <= reservedTokenSupply,
      'EXCEEDS_SUPPLY'
    );
    for (uint256 i; i < _amount; i++) {
      if (mintedFromReserve < reservedTokenSupply) {
        _safeMint(_to, _tokenIds.current());
        mintedBy[_tokenIds.current()] = _to;
        emit Mint(_tokenIds.current(), _to);
        _tokenIds.increment();
        mintedFromReserve++;
      }
    }
  }

  // SETS WHITELIST // TESTED
  function whitelistBatch_Admin(address[] calldata _to) public onlyOwner {
    for (uint256 i = 0; i < _to.length; i++) {
      whitelisted[_to[i]] = true;
    }
  }

  // BANS MINTER // TESTED
  function blacklistBatch_Admin(address[] calldata _addr) external onlyOwner {
    for (uint256 i = 0; i < _addr.length; i++) {
      blacklisted[_addr[i]] = true;
    }
  }
}