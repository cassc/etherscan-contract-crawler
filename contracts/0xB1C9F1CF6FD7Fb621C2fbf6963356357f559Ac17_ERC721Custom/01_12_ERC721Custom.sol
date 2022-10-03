// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'erc721a/contracts/ERC721A.sol';
import './IERC721Custom.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract ERC721Custom is IERC721Custom, ERC721A, AccessControl, ReentrancyGuard {
  using Strings for uint256;

  uint256 public freeMintLimit;
  uint256 public maxSupply;
  uint256 public mintPrice;
  uint256 public maxBatchMint = 5;
  bytes32 public merkleRoot;
  string public baseURI;

  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public freeMintClaimed;

  bool public airdropDone = false;

  address public devAddress = 0xEfF5ffD4659b9FaB41c2371B775d37F00b287CCf;

  constructor(
    address _admin,
    string memory _baseURI,
    string memory _tokenName,
    string memory _tokenSymbol,
    bytes32 _merkleRoot,
    uint256 _mintPrice,
    uint256 _freeMintLimit,
    uint256 _maxSupply
  ) ERC721A(_tokenName, _tokenSymbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    baseURI = _baseURI;
    merkleRoot = _merkleRoot;
    mintPrice = _mintPrice;
    freeMintLimit = _freeMintLimit;
    maxSupply = _maxSupply;
  }

  modifier _onlyAdmin() {
      require(
          hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
          "You are not allowed to perform this operation"
      );
      _;
  }

  modifier payableMintCompliance(uint256 _amount) {
    require(airdropDone, "Cant mint before the end of airdrop");
    require(_amount > 0 && _amount <= maxBatchMint, "You can mint from 1 to 5 token not less, not more, less is more");
    require(totalSupply() + _amount <= maxSupply, "Sorry bro no more token you miss your luck");
    require(msg.value >= mintPrice * _amount, "We said it's payable not free it's 0.002 ETH each NFT");
    _;
  }

  modifier freeMintCompliance(address to) {
    require(airdropDone, "Cant mint before the end of airdrop");
    require(totalSupply() + 1 <= freeMintLimit, "There is only 100 free NFT you miss your luck bro, be water");
    require(!freeMintClaimed[to], "You already claim a free mint with this wallet, create a new one we know you, fucking botters");
    _;
  }

  function checkMerkleProof(address to, bytes32[] calldata _merkleProof) public view returns(bool) {
    bytes32 leaf = keccak256(abi.encodePacked(to));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
      return false;
    }
    if (whitelistClaimed[to]) {
      return false;
    }
    return true;
  }

  function mintWhitelist(address to, bytes32[] calldata _merkleProof) public {
    require(totalSupply() + 1 <= maxSupply, "Sorry bro no more token you miss your luck");
    require(checkMerkleProof(to, _merkleProof), "Address is not whitelisted or have already claim");
    whitelistClaimed[to] = true;
    _safeMint(to, 1);
  }

  function freeMint(address to) public freeMintCompliance(to) {
    freeMintClaimed[to] = true;
    _safeMint(to, 1);
  }

  function payableMint(address to, uint256 amount) public payable payableMintCompliance(amount) {
    _safeMint(to, amount);
  }

  function mint(uint256 amount) public payable {
    if (totalSupply() + 1 <= freeMintLimit) {
      freeMint(_msgSender());
    } else {
      payableMint(_msgSender(), amount);
    }
  }

  function withdrawFund(address to) public _onlyAdmin nonReentrant {
    require(address(this).balance > 0, "No fund to withdraw I know you like money but go work moron");
    (bool hs, ) = payable(devAddress).call{value: address(this).balance * 22 / 100}('');
    require(hs);
    (bool os, ) = payable(to).call{value: address(this).balance}('');
    require(os);
  }

  function setAirdropDone(bool _state) public _onlyAdmin {
    airdropDone = _state;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721A)
    returns (string memory)
  {
    return string(abi.encodePacked(baseTokenURI(), _tokenId.toString(), '.json'));
  }

  function baseTokenURI() public view returns (string memory) {
    return baseURI;
  }
}