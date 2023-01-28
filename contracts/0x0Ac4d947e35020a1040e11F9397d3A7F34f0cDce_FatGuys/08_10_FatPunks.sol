// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "ERC721A/contracts/ERC721A.sol";

contract FatGuys is
  ERC721A,
  Ownable,
  ReentrancyGuard
{
  using Strings for uint256;
  using Counters for Counters.Counter;

  bytes32 private wlroot;

  uint256 public totalMaxSupply = 9500;
  uint256 public wlMintSupply = 10000;

  uint256 teamMintAmount = 100;
  uint256 publicMintAmount = 500;
  uint256 wlMintAmount = 2;

  bool public paused = true;
  bool public revealed = false;
  bool public publicMintState = true;
  bool public wlMintState = false;

  uint256 publicMprice = 3000000000000000;
  uint256 WLMprice = 1300000000000000;

  string public baseURI;
  string public notRevealedUri =
    'https://bafybeidg4d52whlwbndcxrlsqathhlai6yougftpeosaofwkpgyqpuuhhy.ipfs.nftstorage.link/unrevealed.json';
  string public baseExtension = '.json';

  mapping(address => uint256) public _publicClaimed;
  mapping(address => uint256) public _wlClaimed;

  Counters.Counter private _tokenIds;

  constructor(
    string memory uri,
    bytes32 wlMerkleroot
  )
    ERC721A('FATGUYS', 'FGS')
    ReentrancyGuard()
  {
    wlroot = wlMerkleroot;

    setBaseURI(uri);

    _safeMint(msg.sender, teamMintAmount);
    for(uint i = 0; i < teamMintAmount; i++)
    {
      _tokenIds.increment();
    }
  }

  function setPublicMintPrice(uint256 _newPublicPrice) public onlyOwner {
    publicMprice = _newPublicPrice;
  }
  function setWLMintPrice(uint256 _newWLPrice) public onlyOwner {
    WLMprice = _newWLPrice;
  }

  function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    totalMaxSupply = _newMaxSupply;
  }

  function setWLSupply(uint256 _newWLSupply) public onlyOwner {
    wlMintSupply = _newWLSupply;
  }

  function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
    baseURI = _tokenBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setMerkleRoot(bytes32 wlMerkleroot) public onlyOwner {
    wlroot = wlMerkleroot;
  }

  modifier onlyAccounts() {
    require(msg.sender == tx.origin, 'Not allowed origin');
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata _proof) {
    require(
      MerkleProof.verify(
        _proof,
        wlroot,
        keccak256(abi.encodePacked(msg.sender))
      ) == true,
      'Not allowed origin'
    );
    _;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function togglePause() public onlyOwner {
    paused = !paused;
  }

  function togglePublicMint() public onlyOwner {
    publicMintState = !publicMintState;
  }

  function toggleWL() public onlyOwner {
    wlMintState = !wlMintState;
  }

  function whitelistMint(
    address account,
    uint256 _amount,
    bytes32[] calldata _proof
  ) external payable isValidMerkleProof(_proof) onlyAccounts nonReentrant {
    require(msg.sender == account, 'Not allowed');
    require(wlMintState, 'WL Mint is OFF');
    require(!paused, 'Contract is paused');
    require(
      _amount <= wlMintAmount,
      "You can't mint so much tokens"
    );
    require(
      _wlClaimed[msg.sender] + _amount <= wlMintAmount,
      "You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= wlMintSupply, 'max supply for wl mint exceeded');
    require(WLMprice * _amount <= msg.value, 'Not enough ethers sent');

    _wlClaimed[msg.sender] += _amount;

    _safeMint(msg.sender, _amount);
    for(uint i = 0; i < _amount; i++)
    {
      _tokenIds.increment();
    }
  }
  
  function publicMint(uint256 _amount) external payable onlyAccounts nonReentrant {
    require(publicMintState, 'Public Mint is OFF');
    require(!paused, 'Contract is paused');
    require(_amount > 0, 'zero amount');
    require(
      _amount <= publicMintAmount, 
      "You can't mint so much tokens"
      );

    require(
      _publicClaimed[msg.sender] + _amount <= publicMintAmount,
      "You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= totalMaxSupply, 'Max supply for public mint exceeded');
    require(publicMprice * _amount <= msg.value, 'Not enough ethers sent');

    _publicClaimed[msg.sender] += _amount;

    _safeMint(msg.sender, _amount);
    for(uint i = 0; i < _amount; i++)
    {
      _tokenIds.increment();
    }
  }

  function totalSupply() public view override returns (uint) {
        return _tokenIds.current();
    }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
        _exists(tokenId),
        'ERC721Metadata: URI query for nonexistent token'
        );
        if (revealed == false) {
        return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return
        bytes(currentBaseURI).length > 0
            ? string(
            abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
            )
            : '';
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
  
    function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }
}