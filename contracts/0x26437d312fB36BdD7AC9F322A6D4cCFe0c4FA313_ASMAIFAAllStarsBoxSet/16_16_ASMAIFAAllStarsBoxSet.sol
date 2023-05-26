// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract ASMAIFAAllStarsBoxSet is ERC721Enumerable, ReentrancyGuard, Ownable {
  using ECDSA for bytes32;
  using Address for address;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  enum Status {
    Pending,
    PreSale,
    PublicSale,
    Finished
  }

  Status public status;

  address private _signer;

  string public baseURI;
  uint256 public maxAmountPerTx = 3;
  uint256 public constant maxSupply = 10000;
  uint256 public constant price = 0.09 * 10**18; // 0.09 ETH

  mapping(bytes => bool) public usedToken;
  mapping(address => bool) public presaleMinted;

  event Minted(address minter, uint256 amount);
  event StatusChanged(Status status);
  event BaseURIChanged(string newBaseURI);
  event SignerChanged(address signer);
  event BalanceWithdrawed(address recipient, uint256 value);

  constructor(address signer, address recipient)
    ERC721('ASMAIFAAllStarsBoxSet', 'AIFABOX')
  {
    _signer = signer;

    _safeMint(recipient, _tokenIds.current());
    _tokenIds.increment();
  }

  function getStatus() public view returns (Status) {
    return status;
  }

  function _hash(string calldata salt, address _address)
    internal
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(salt, address(this), _address));
  }

  function _verify(bytes32 hash, bytes memory token)
    internal
    view
    returns (bool)
  {
    return (_recover(hash, token) == _signer);
  }

  function _recover(bytes32 hash, bytes memory token)
    internal
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(token);
  }

  function presaleMint(string calldata salt, bytes calldata token)
    external
    payable
    nonReentrant
  {
    require(status == Status.PreSale, 'Presale is not active.');
    require(
      !Address.isContract(msg.sender),
      'Contracts are not allowed to mint.'
    );
    require(
      !presaleMinted[msg.sender],
      'The wallet address has already minted.'
    );
    require(
      _tokenIds.current() + 1 <= maxSupply,
      'Max supply of tokens exceeded.'
    );
    require(msg.value >= price, 'Ether value sent is incorrect.');
    require(_verify(_hash(salt, msg.sender), token), 'Invalid token.');

    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);

    _tokenIds.increment();
    presaleMinted[msg.sender] = true;

    emit Minted(msg.sender, 1);
  }

  function mint(
    string calldata salt,
    bytes calldata token,
    uint256 amount
  ) external payable nonReentrant {
    require(status == Status.PublicSale, 'Sale is not active.');
    require(
      !Address.isContract(msg.sender),
      'Contracts are not allowed to mint.'
    );
    require(
      amount <= maxAmountPerTx,
      'Amount should not exceed 3 per transaction.'
    );
    require(
      _tokenIds.current() + amount <= maxSupply,
      'Amount should not exceed max supply of tokens.'
    );
    require(msg.value >= price * amount, 'Ether value sent is incorrect.');
    require(!usedToken[token], 'The token has been used.');
    require(_verify(_hash(salt, msg.sender), token), 'Invalid token.');

    for (uint256 i = 0; i < amount; i++) {
      uint256 newItemId = _tokenIds.current();
      _safeMint(msg.sender, newItemId);
      _tokenIds.increment();
    }

    usedToken[token] = true;

    emit Minted(msg.sender, amount);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function withdrawAll(address recipient) external onlyOwner {
    uint256 balance = address(this).balance;
    payable(recipient).transfer(balance);
    emit BalanceWithdrawed(recipient, balance);
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
    emit BaseURIChanged(newBaseURI);
  }

  function setStatus(Status _status) external onlyOwner {
    status = _status;
    emit StatusChanged(_status);
  }

  function setSigner(address signer) external onlyOwner {
    _signer = signer;
    emit SignerChanged(signer);
  }
}