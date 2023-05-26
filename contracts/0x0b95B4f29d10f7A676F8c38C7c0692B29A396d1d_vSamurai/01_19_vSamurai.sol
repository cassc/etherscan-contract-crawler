// SPDX-License-Identifier: MIT
// .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | | ____   ____  | || |    _______   | || |      __      | || | ____    ____ | || | _____  _____ | || |  _______     | || |      __      | || |     _____    | |
// | ||_  _| |_  _| | || |   /  ___  |  | || |     /  \     | || ||_   \  /   _|| || ||_   _||_   _|| || | |_   __ \    | || |     /  \     | || |    |_   _|   | |
// | |  \ \   / /   | || |  |  (__ \_|  | || |    / /\ \    | || |  |   \/   |  | || |  | |    | |  | || |   | |__) |   | || |    / /\ \    | || |      | |     | |
// | |   \ \ / /    | || |   '.___`-.   | || |   / ____ \   | || |  | |\  /| |  | || |  | '    ' |  | || |   |  __ /    | || |   / ____ \   | || |      | |     | |
// | |    \ ' /     | || |  |`\____) |  | || | _/ /    \ \_ | || | _| |_\/_| |_ | || |   \ `--' /   | || |  _| |  \ \_  | || | _/ /    \ \_ | || |     _| |_    | |
// | |     \_/      | || |  |_______.'  | || ||____|  |____|| || ||_____||_____|| || |    `.__.'    | || | |____| |___| | || ||____|  |____|| || |    |_____|   | |
// | |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' |
// Website: https://vsamurai.io
// Developers: https://buildingideas.io
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Withdrawable.sol";
import "./Whitelistable.sol";
import "./ERC721A.sol";
import "./Rewardable.sol";
import "./Breedable.sol";

contract vSamurai is Ownable, ERC721A, Withdrawable, Whitelistable, Rewardable, Breedable {
  uint256 public immutable maxPerWalletWhitelist;
  uint256 public immutable maxPerWalletPublicSale;

  string public baseTokenURI;

  address public proxyRegistryAddress;

  uint256 public NFT_PRICE = 0.075 ether;
  uint256 public NFT_PRICE_PRESALE = 0.075 ether;
  uint public constant MAX_SUPPLY = 10000;

  mapping(address => bool) public projectProxy; 
  mapping(address => uint) public addressToWhitelistMinted;
  mapping(address => uint) public addressToMinted;

  bool public hasSaleStarted = false;
  bool public hasPreSaleStarted = false;  

  uint public MAX_NFT_CLAIMS = 25;
  uint public NFT_CLAIMED = 0;

  constructor(
    string memory _baseUri,
    uint256 _maxPerWalletWhitelist,
    uint256 _maxPerWalletPublicSale,
    address _developerAddress,
    uint256 _developerFee,
    address _proxyRegistryAddress,
    address _owner,
    address _signer
  ) ERC721A("vSamurai", "VS") Whitelistable(_signer) {
    baseTokenURI = _baseUri;
    maxPerWalletWhitelist = _maxPerWalletWhitelist;
    maxPerWalletPublicSale = _maxPerWalletPublicSale;
    proxyRegistryAddress = _proxyRegistryAddress;
    setDeveloperPaymentAddress(_developerAddress);
    setDeveloperPaymentFee(_developerFee);
    transferOwnership(_owner);
  }

  modifier callerIsUser() {
    require(tx.origin == _msgSender(), "The caller is another contract");
    _;
  }

  function whitelistMint(bytes calldata signature, uint256 _quantity) external payable callerIsUser requiresWhitelist(signature) {
    require(msg.value >= NFT_PRICE_PRESALE * _quantity, "Incorrect ether value");
    require(hasPreSaleStarted, "Presale has not started");
    require(_quantity <= maxPerWalletWhitelist, "Exceeds max per tx");
    require(addressToWhitelistMinted[_msgSender()] + _quantity <= maxPerWalletWhitelist, "Exceeds whitelist supply");
    require(MAX_SUPPLY - MAX_NFT_CLAIMS > totalSupply() + _quantity, "Exceeds supply");
    _safeMint(_msgSender(), _quantity);
    addressToWhitelistMinted[_msgSender()] += _quantity;
  }

  function publicSaleMint(uint256 _quantity) external payable callerIsUser {
    require(msg.value >= NFT_PRICE * _quantity, "Incorrect ether value");
    require(_quantity <= maxPerWalletPublicSale, "Exceeds max per tx");
    require(addressToMinted[_msgSender()] + _quantity <= maxPerWalletPublicSale, "Exceeds mints for this wallet");
    require(hasSaleStarted, "Sale has not started");
    require(MAX_SUPPLY - MAX_NFT_CLAIMS > totalSupply() + _quantity, "Exceeds supply");
    _safeMint(_msgSender(), _quantity);
    addressToMinted[_msgSender()] += _quantity;

  }


  function devMint(address recipient, uint256 _quantity) external onlyOwner {
    require(_quantity <= MAX_NFT_CLAIMS, "Exceeds max claims");
    require(_quantity + NFT_CLAIMED <= MAX_NFT_CLAIMS, "Exceeds max claims");
    require(MAX_SUPPLY - MAX_NFT_CLAIMS > totalSupply() + _quantity, "Exceeds supply");
    uint256 numChunks = _quantity / maxPerWalletPublicSale;

    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(recipient, maxPerWalletPublicSale);
    }

    uint256 modulo = _quantity % maxPerWalletPublicSale;
    if(modulo != 0) {
      _safeMint(recipient, modulo);
    }

    NFT_CLAIMED += _quantity;
  }

  function transferFrom(address from, address to, uint256 tokenId) public override {
    if (address(yieldToken) != address(0)) {
      yieldToken.updateReward(from, to, tokenId);
    }
    ERC721A.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
    if (address(yieldToken) != address(0)) {
      yieldToken.updateReward(from, to, tokenId);
    }
    ERC721A.safeTransferFrom(from, to, tokenId, _data);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseTokenURI = baseURI;
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }

  function flipSaleState() public onlyOwner {
    hasSaleStarted = !hasSaleStarted;
  }
  
  function flipPreSaleState() public onlyOwner {
    hasPreSaleStarted = !hasPreSaleStarted;
  }

  function setPresalePrice(uint256 nftPublicPrice) public onlyOwner {
    NFT_PRICE_PRESALE = nftPublicPrice;
  }
  
  function setMintPrice(uint256 nftPrice) public onlyOwner {
    NFT_PRICE = nftPrice;
  }

  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) {
      return true;
    }
    return super.isApprovedForAll(_owner, operator);
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function flipProxyState(address proxyAddress) public onlyOwner {
    projectProxy[proxyAddress] = !projectProxy[proxyAddress];
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  // Eventually, instead of using this, call our subgraph which is much faster 
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
      uint256[] memory a = new uint256[](balanceOf(owner)); 
      uint256 end = _currentIndex;
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      for (uint256 i; i < end; i++) {
        TokenOwnership memory ownership = _ownerships[i];
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          a[tokenIdsIdx++] = i;
        }
      }
      return a;    
    }
  }
}

contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}