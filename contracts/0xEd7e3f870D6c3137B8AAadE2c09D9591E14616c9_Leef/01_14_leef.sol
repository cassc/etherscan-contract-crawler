// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Leef is ERC721A, Ownable, Pausable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  uint64  public  immutable _maxSupply = 1597;
  uint64  public            _mintPrice = 0.05 ether;
  uint256 public            _maxPerLeeflist = 2;
  bytes32 public            _proofRoot;
  string  public            _tokenURIBase;
  string  public            _tokenURIExtension;
  bool public               _onlyLeeflisted = true;

  address public constant cosmo     = 0xDDB404593d03fdE90D87d1070E026f45D9B2f41a;

  mapping(address => uint) public addressMintBalance;

  constructor(
    string memory _URIBase,
    string memory _URIExtension
  ) ERC721A("Leef", "LEEF") {
    _tokenURIBase = _URIBase;
    _tokenURIExtension = _URIExtension;
    _pause();
  }

  modifier mintCompliance(
    uint _quantity,
    bytes32[] memory _proof
  )
  {
    require(
      msg.value == (_mintPrice * _quantity),
      "Incorrect payment"
    );
    require(
      totalSupply() + _quantity <= _maxSupply,
      "Maximum supply exceeded"
    );
    if(_onlyLeeflisted)
    {
        require(
            addressMintBalance[msg.sender] + _quantity <= _maxPerLeeflist,
            "Address mint threshold exceeded"
        );

        require(
        MerkleProof.verify(_proof, _proofRoot, keccak256(abi.encodePacked(msg.sender))),
        "Failed allowlist proof"
        );
    }
    _;
  }

  function mint(uint _quantity, bytes32[] memory _proof)
    public
    payable
    mintCompliance(_quantity, _proof)
    whenNotPaused
  {
    addressMintBalance[msg.sender] += _quantity;
    _safeMint(msg.sender, _quantity);
  }

  function ownerMint(uint _quantity)
    public
    onlyOwner
  {
    require(
      _quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + _quantity <= _maxSupply,
      "Maximum supply exceeded"
    );
    _safeMint(msg.sender, _quantity);
  }

  function setURIBase(string memory _URIBase)
    public
    onlyOwner
  {
    _tokenURIBase = _URIBase;
  }

  function setURIExtension(string memory _URIExtension)
    public
    onlyOwner
  {
    _tokenURIExtension = _URIExtension;
  }

  function setPriceWei(uint64 _priceWei)
    public
    onlyOwner
  {
    _mintPrice = _priceWei;
  }

  function setProofRoot(bytes32 _root)
    public
    onlyOwner
  {
    _proofRoot = _root;
  }

  function setOnlyLeeflist()
    public
    onlyOwner
    {
        _onlyLeeflisted = true;
    }

  function setPublic()
    public
    onlyOwner
    {
        _onlyLeeflisted = false;
    }

  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
    Address.sendValue(payable(cosmo), address(this).balance);
  }

  function pause()
    public
    onlyOwner
  {
    _pause();
  }

  function unpause()
    public
    onlyOwner
  {
    _unpause();
  }

  function tokenURI(uint _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for non-existent token"
    );
    return string(abi.encodePacked(_tokenURIBase, _tokenId.toString(), _tokenURIExtension));
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return _tokenURIBase;
  }

  function _startTokenId()
    internal
    view
    virtual
    override
    returns (uint256)
  {
    return 1;
  }
}