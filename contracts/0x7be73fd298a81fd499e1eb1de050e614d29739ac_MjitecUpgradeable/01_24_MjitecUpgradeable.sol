// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


abstract contract ContextMixin {
  function msgSender()
    internal
    view
    returns (address payable sender)
  {
    if (msg.sender == address(this)) {
        bytes memory array = msg.data;
        uint256 index = msg.data.length;
        assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
            sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
    } else {
        sender = payable(msg.sender);
    }
    return sender;
  }
}

contract MjitecUpgradeable is UUPSUpgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable, OwnableUpgradeable, ContextMixin, ReentrancyGuardUpgradeable {
  using StringsUpgradeable for uint256;
  
  string public baseURI;
  string public baseExtension;
  string public notRevealedUri;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmount;
  uint256 public nftPerAddressLimit;
//   uint256 public currentPhaseMintMaxAmount = 110;

  uint32 public publicSaleStart;
  uint32 public preSaleStart;

  bool public publicSalePaused;
  bool public preSalePaused;

  bool public revealed;
  bool public onlyWhitelisted;

  // for opensea royalties fee
  string public contractURI;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  mapping(address => uint256) addressMintedBalance;
  mapping(address => bool) public whiteList;

  address public safeTreasury;

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    string memory _contractURI,
    address _safeTreasury
  ) public initializer {
    __ERC721_init(_name, _symbol);
    __ERC721Enumerable_init();
    __Ownable_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();


    __MJITEC_init(_initBaseURI, _initNotRevealedUri, _contractURI, _safeTreasury);
  }

  function __MJITEC_init(
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    string memory _contractURI,
    address _safeTreasury
  ) internal {
    baseURI = _initBaseURI;
    notRevealedUri = _initNotRevealedUri;
    _setDefaultRoyalty(msg.sender, 1000);
    contractURI = _contractURI;

    baseExtension = ".json";
    notRevealedUri;
    cost = 0.01 ether;
    maxSupply = 10000;
    maxMintAmount = 10;
    nftPerAddressLimit = 10;

    publicSaleStart = 1647136800;
    preSaleStart = 1646964000;

    publicSalePaused = true;
    preSalePaused = true;

    revealed = false;
    onlyWhitelisted = true;

    safeTreasury = _safeTreasury;
  }

	// for opensea meta transaction
  function _msgSender() internal override view returns (address sender) {
		return ContextMixin.msgSender();
	}

  // internal
  function _baseURI() internal view virtual override returns(string memory) {
    return baseURI;
  }

  function preSaleMint(uint256 _mintAmount) public payable {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require((!preSalePaused) && (preSaleStart <= block.timestamp), "Not Reach Pre Sale Time");
    uint256 supply = totalSupply();
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    // require(supply + _mintAmount <= currentPhaseMintMaxAmount, "reach current Phase NFT limit");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
      if (onlyWhitelisted == true) {
        require(whiteList[msg.sender] == true, "user is not whitelisted");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
      }
      require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }

    (bool success, ) = payable(safeTreasury).call{value : msg.value}("");
    
    require(success == true, "not be able to send fund to treasury wallet");
  }

  function publicSaleMint(uint256 _mintAmount) public payable {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require((!publicSalePaused) && (publicSaleStart <= block.timestamp), "Not Reach Public Sale Time");
    uint256 supply = totalSupply();
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    // require(supply + _mintAmount <= currentPhaseMintMaxAmount, "reach current Phase NFT limit");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
    require(msg.value >= cost * _mintAmount, "insufficient funds");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }

    (bool success, ) = payable(safeTreasury).call{value : msg.value}("");
    
    require(success == true, "not be able to send fund to treasury wallet");
  }

  function authorizedMint(address _addr, uint256 _mintAmount) public onlyOwner {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    // require(supply + _mintAmount <= currentPhaseMintMaxAmount, "reach current Phase NFT limit");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    uint256 ownerMintedCount = addressMintedBalance[_addr];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[_addr]++;
      _safeMint(_addr, supply + i);
    }
  }

  function addUsersToWhiteList(address[] memory _addresses) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whiteList[_addresses[i]] = true;
    }
  }

  function removeUserFromWhiteList(address _address) public onlyOwner {
    require(whiteList[_address] == true, "user is not whitelisted");
    whiteList[_address] = false;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ?
      string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) :
      "";
  }

  function publicSaleIsActive() public view returns(bool) {
    return ((publicSaleStart <= block.timestamp) && (!publicSalePaused));
  }

  function preSaleIsActive() public view returns(bool) {
    return ((preSaleStart <= block.timestamp) && (!preSalePaused));
  }

  function setPreSalePause(bool _state) public onlyOwner {
    preSalePaused = _state;
  }

  function setPublicSalePause(bool _state) public onlyOwner {
    publicSalePaused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setContractURI(string memory _newContractURI) public onlyOwner {
    contractURI = _newContractURI;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function flipReveal(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setPublicSaleStart(uint32 timestamp) public onlyOwner {
    publicSaleStart = timestamp;
  }

  function setPreSaleStart(uint32 timestamp) public onlyOwner {
    preSaleStart = timestamp;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }

  function walletOfOwner(address _owner) public view returns(uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function getContractURI() public view returns (string memory) {
    return contractURI;
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
    _deleteDefaultRoyalty();
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable, ERC2981Upgradeable) returns (bool) {
    if(interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }

    return super.supportsInterface(interfaceId);
  }
  
  function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}