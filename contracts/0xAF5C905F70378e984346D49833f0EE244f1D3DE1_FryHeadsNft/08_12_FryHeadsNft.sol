// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

interface IWETH9 {
  function withdraw(uint wad) external payable;

}
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FryHeadsNft is ERC721A, DefaultOperatorFilterer, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  uint public donationCount = 0;
  // Charity infos
  struct charity {
    string name;
    string short_name;
    string description;
    address addr;
    uint count;
  }
  charity[] public charities;

  // List of charities associated to each token
  int[] public tokenCharity;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    _initCharities();
  }

  // Event to debug charity withdraw
  event CharityWidthdraw(string name, address addr, uint count, uint256 toPay);

  // Fallbacks and plain transfer support
  fallback() external payable { }
  receive() external payable { }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function getCharitiesCount() public view returns (uint) {
    return charities.length;
  }

  function getTokenAssociatedCharity(uint256 _tokenId) public view returns (int) {
    return tokenCharity[_tokenId];
  }

  function _initCharities() internal onlyOwner {
    charities.push(charity({
      name: "Education",
      short_name: "Education",
      description: "Support US-based charities devoted to providing high-quality education. <a href='https://thegivingblock.com/impact-index-funds/education/' target='_blank'>See on Giving Block.</a>",
      //addr: 0x886206B3c8E3D877755E16d013412C1686827133, // Dev wallets 133
      addr: 0xC40F82716642DE7e09053510d584888C424413ED, // REAL ones
      count: 0
    }));
    charities.push(charity({
      name: "Environment",
      short_name: "Environment",
      description: "Support US-based charities protecting the environment. <a href='https://thegivingblock.com/impact-index-funds/environment/' target='_blank'>See on Giving Block.</a>",
      // addr: 0x95Bb8d2D7dac1B1c125877B22Dfd29B69d951c51, //Dev wallets c51
      addr: 0x9D0CBf22Ea2132D6E8EBdd6DdC760b309bFa4cc6,
      count: 0
    }));
    charities.push(charity({
      name: "Civil & Human Rights",
      short_name: "Civil",
      description: "Support US-based charities focused on civil and human rights issues. <a href='https://thegivingblock.com/impact-index-funds/civil-human-rights/' target='_blank'>See on Giving Block.</a>",
      //addr: 0x886206B3c8E3D877755E16d013412C1686827133,
      addr: 0xD23C066530b47cB2246F5CaeD48330fAb0F750AA,
      count: 0
    }));
    charities.push(charity({
      name: "Children & Youth",
      short_name: "Children",
      description: "Support US-based charities serving the needs of children. <a href='https://thegivingblock.com/impact-index-funds/children-youth/' target='_blank'>See on Giving Block.</a>",
      //addr: 0x95Bb8d2D7dac1B1c125877B22Dfd29B69d951c51,
      addr: 0xcE7348719d5d98Cf1a6876205A4d519Ae8E47a6d,
      count: 0
    }));
    charities.push(charity({
      name: "Poverty & Housing",
      short_name: "Poverty",
      description: "Support US-based charities working to relieve the difficulties of poverty and homelessness. <a href='https://thegivingblock.com/impact-index-funds/poverty-housing/' target='_blank'>See on Giving Block.</a>",
      //addr: 0x886206B3c8E3D877755E16d013412C1686827133,
      addr: 0x2FB414edE7579a4E0932fbAF78f539c4C27fB1E6,
      count: 0
    }));
    charities.push(charity({
      name: "Animals",
      short_name: "Animals",
      description: "Support US-based charities devoted to animal rights and protection. <a href='https://thegivingblock.com/impact-index-funds/animals/' target='_blank'>See on Giving Block.</a>",
      //addr: 0x95Bb8d2D7dac1B1c125877B22Dfd29B69d951c51,
      addr: 0xd71A6a4D4F4CD8D85E25898Da566179D9f9D8eE1,
      count: 0
    }));

    // Push empty charity for token #0 as there is none
    tokenCharity.push(-1);
  }

  function whitelistMint(uint256 _mintAmount, uint _charityId, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    donationCount += _mintAmount;
    charities[_charityId].count += _mintAmount;
    for (uint i = (totalSupply()+1); i <= (totalSupply() + _mintAmount); i++) {
      tokenCharity.push(int(_charityId));
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount, uint _charityId) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    donationCount += _mintAmount;
    charities[_charityId].count += _mintAmount;
    for (uint i = (totalSupply()+1); i <= (totalSupply() + _mintAmount); i++) {
      tokenCharity.push(int(_charityId));
    }
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) external mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  // function walletOfOwner(address _owner) external view returns (uint256[] memory) {
  //   uint256 ownerTokenCount = balanceOf(_owner);
  //   uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
  //   uint256 currentTokenId = _startTokenId();
  //   uint256 ownedTokenIndex = 0;
  //   address latestOwnerAddress;

  //   while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
  //     TokenOwnership memory ownership = _ownerships[currentTokenId];

  //     if (!ownership.burned) {
  //       if (ownership.addr != address(0)) {
  //         latestOwnerAddress = ownership.addr;
  //       }

  //       if (latestOwnerAddress == _owner) {
  //         ownedTokenIds[ownedTokenIndex] = currentTokenId;

  //         ownedTokenIndex++;
  //       }
  //     }

  //     currentTokenId++;
  //   }

  //   return ownedTokenIds;
  // }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function payableToCharity() public view returns (uint256) {
    return address(this).balance * 50 / 100;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) external onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public nonReentrant {
    uint toCharities = payableToCharity();

    // We should always have donations if the contract has a positive balance
    if (donationCount > 0) {
      // Distribute funds to all charities with a count > 0
      for (uint i = 0; i < 6; i++) {
        if (charities[i].count == 0) {
          continue;
        }

        // What we need to send to this charity
        uint256 toPay = 0;
        toPay = toCharities * (charities[i].count * 100 / donationCount) / 100;

        // Emit an event for logging
        emit CharityWidthdraw(charities[i].name, charities[i].addr, charities[i].count, toPay);

        (bool ch, ) = payable(charities[i].addr).call{value: toPay}('');  
        require(ch);
      }
    }

    // Send half of the remaining to the artist
    (bool ar, ) = payable(0xbCaC001F2e9aFa28B4b719a98A368D982F4b87de).call{value: address(this).balance / 2}('');
    require(ar);

    // This will transfer the remaining contract balance to the owner/dev.
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function withdrawETH() public {
    // address WETH9 = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // Goerli
    address WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet
    uint balanceWETH = IERC20(WETH9).balanceOf(address(this));
    if (balanceWETH > 0) {
      IWETH9(WETH9).withdraw(balanceWETH);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      payable
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }
}