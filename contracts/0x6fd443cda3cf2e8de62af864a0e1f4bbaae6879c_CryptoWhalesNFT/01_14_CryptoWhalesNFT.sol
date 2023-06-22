// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "hardhat/console.sol";

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy { }
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CryptoWhalesNFT is ERC721, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public mintCost = 0.045 ether;
  uint256 public maxSupply = 7777;

  // Max number of NFTs that can be minted at one time
  uint256 public maxMintAmount = 5;
  // max number of NFTs a wallet can mint/hold
  // uint256 public nftPerAddressLimit = 5;
  
  address public openSeaProxyRegistryAddress;
  bool public isOpenSeaProxyActive = true;

  bool public pausedMint = true;

  // reveal
  bool public revealed = false;
  string public notRevealedUri;

  address public signerAddress;

  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    address _openSeaProxyRegistryAddress,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    baseURI = _initBaseURI;
    notRevealedUri = _initNotRevealedUri;
    openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    signerAddress = msg.sender;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function verifySender(bytes memory signature, uint256 _maxAllowed) public view returns (bool) {
    bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, ":", Strings.toString(_maxAllowed))));
    return ECDSA.recover(hash, signature) == signerAddress;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
  
  // public
  function mint(uint256 _mintAmount, bytes memory signature, uint256 _maxAllowed) public payable mintCompliance(_mintAmount) {
    require(!pausedMint, "Contract is paused");
    require(msg.value >= mintCost * _mintAmount);
    require(verifySender(signature, _maxAllowed), "Invalid Access");

    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= _maxAllowed, "Max NFT per address exceeded");
    
    _mintLoop(msg.sender, _mintAmount);
  }

  // Owner
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      addressMintedBalance[_receiver]++;
      _safeMint(_receiver, supply.current());
    }
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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
      "ERC721Metadata: URI query for nonexistent token"
    );

    if(revealed == false) {
      return notRevealedUri;
    }
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
  }

  function setMintCost(uint256 _newCost) external onlyOwner {
    mintCost = _newCost;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }

  // function setMaxAddressNftLimit(uint256 _newMaxLimit) external onlyOwner {
  //   nftPerAddressLimit = _newMaxLimit;
  // }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function reveal() public onlyOwner {
      revealed = true;
  }

  function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  // function to disable gasless listings for security in case
  // opensea ever shuts down or is compromised
  function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
      external
      onlyOwner
  {
      isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  function setOpenSeaProxyRegistryAddress(
        address _openSeaProxyRegistryAddress
    ) external onlyOwner {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

  function setSignerAddress(address _newSignerAddress) external onlyOwner {
    signerAddress = _newSignerAddress;
  }

  function pauseMint(bool _state) external onlyOwner {
    pausedMint = _state;
  }

  function withdraw(uint256 _percentWithdrawl) public payable onlyOwner {
    require(address(this).balance != 0, "Balance is zero");
    require(_percentWithdrawl > 0 && _percentWithdrawl <= 100, "Withdrawl percent should be > 0 and <= 100");
    

    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance * _percentWithdrawl / 100}("");
    require(os);
    // =============================================================================
  }

  /**
    * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
    */
  function isApprovedForAll(address owner, address operator)
      public
      view
      override
      returns (bool)
  {
      // Get a reference to OpenSea's proxy registry contract by instantiating
      // the contract using the already existing address.
      ProxyRegistry proxyRegistry = ProxyRegistry(
          openSeaProxyRegistryAddress
      );
      if (
          isOpenSeaProxyActive &&
          address(proxyRegistry.proxies(owner)) == operator
      ) {
          return true;
      }

      return super.isApprovedForAll(owner, operator);
  }
}