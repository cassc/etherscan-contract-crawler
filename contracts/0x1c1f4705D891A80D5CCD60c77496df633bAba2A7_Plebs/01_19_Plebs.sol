// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./rarible/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract Plebs is ERC721URIStorage, Ownable, RoyaltiesV2Impl {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string private _customBaseURI;
  uint256 private _price;
  uint256 private _maxMintable;

  string private _contractURI;
  address private _manager;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  bool private _onlyWhitelist;

  mapping (address => uint256) private _whitelistMintAmounts;
  mapping (address => uint256) private _standardMintAmounts;

  constructor(string memory customBaseURI_, uint256 maxMintable_, address benefactor_, bool onlyWhitelist_) ERC721("Pleb Punks", "PLEB") {
    _customBaseURI = customBaseURI_;
    _price = 0.1 ether;
    _maxMintable = maxMintable_;
    _contractURI = 'https://punkaverse-api.herokuapp.com/api/contract_overview';

    _onlyWhitelist = onlyWhitelist_;

    _manager = msg.sender;
    transferOwnership(benefactor_);
  }

  modifier onlyManager() {
    require(_manager == msg.sender, "Plebs: caller is not the manager");
    _;
  }

  function whitelistMintAmount(address account) public view returns (uint256) {
    return _whitelistMintAmounts[account];
  }

  function standardMintAmount(address account) public view returns (uint256) {
    return _standardMintAmounts[account];
  }

  function setBaseURI(string memory customBaseURI_) public onlyManager {
    _customBaseURI = customBaseURI_;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory contractURI_) public onlyManager {
    _contractURI = contractURI_;
  }

  function setNewManager(address _newManager) public onlyManager {
    _manager = _newManager;
  }

  function setWhitelistedOnly(bool status) public onlyManager {
    _onlyWhitelist = status;
  }

  function airdrop(address[] memory _list) public onlyManager {
    for (uint i = 0; i < _list.length; i++) {
      _tokenIds.increment();
      require(_tokenIds.current() <= _maxMintable, "Project is finished minting.");

      setRoyaltiesOnMint(_tokenIds.current(), payable(owner()), 500);

      uint256 newItemId = _tokenIds.current();
      _mint(_list[i], newItemId);
    }
  }

  function preMint() public view returns (bool) {
    return _onlyWhitelist;
  }

  function purchase(uint256 quantity) public payable {
    require(msg.value >= (_price * quantity), "Not enough ETH sent.");
    require(quantity <= 10, "Can't mint more than 10 at a time.");

    if (_onlyWhitelist) {
      require((_whitelistMintAmounts[msg.sender] + quantity) <= 4, "During the whitelist mint, you can only mint a maximum of 4.");
    } else {
      require((_standardMintAmounts[msg.sender] + quantity) <= 10, "You have already minted your maximum amount.");
    }

    payable(owner()).transfer(msg.value);

    for(uint i = 0; i < quantity; i++) {
      mintForPurchase(msg.sender);
    }
  }

  function currentSupply() public view returns (uint256) {
    return _tokenIds.current();
  }

  function mintForPurchase(address recipient) private {
    _tokenIds.increment();
    require(_tokenIds.current() <= _maxMintable, "Project is finished minting.");

    if (_onlyWhitelist) {
      _whitelistMintAmounts[recipient] += 1;
    } else {
      _standardMintAmounts[recipient] += 1;
    }

    setRoyaltiesOnMint(_tokenIds.current(), payable(owner()), 500);

    uint256 newItemId = _tokenIds.current();
    _mint(recipient, newItemId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _customBaseURI;
  }

  function royaltyInfo(
    uint256 _tokenId, 
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    return (owner(), ((_salePrice * 500) / 10000));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    if (interfaceId == _INTERFACE_ID_ERC2981 || interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyManager {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesReceipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

  function setRoyaltiesOnMint(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) private {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesReceipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }
}