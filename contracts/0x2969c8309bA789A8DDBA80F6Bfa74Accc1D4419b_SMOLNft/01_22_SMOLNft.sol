// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/ISmoltingInu.sol';
import './SMOLNftRewards.sol';

/**
 * SMOL yield bearing NFTs
 */
contract SMOLNft is Ownable, ERC721Burnable, ERC721Enumerable, ERC721Pausable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint16 public constant PERCENT_DENOMENATOR = 1000;
  uint16 private constant FIVE_MINUTES = 60 * 5;

  Counters.Counter private _tokenIds;

  SMOLNftRewards private _rewards;
  mapping(address => bool) private _isRewardsExcluded;

  // user => timestamp of last mint
  // used for throttling wallets from minting too often
  mapping(address => uint256) public userLastMinted;

  // Base token uri
  string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while

  address public smol = 0x2bf6267c4997548d8de56087E5d48bDCCb877E77;
  uint256 public nativeCost = 9 ether / 100; // 0.09 ETH
  uint256 public smolCost = 100 * 10**18;
  uint8 public maxPerMint = 10;

  // Payment address
  address public paymentAddress = 0x98c574473313EAC3FC6af9740245949380ec166E;

  // Royalties address
  address public royaltyAddress = 0x98c574473313EAC3FC6af9740245949380ec166E;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  // Token info
  string public constant TOKEN_NAME = 'yield bearing smolting';
  string public constant TOKEN_SYMBOL = 'ybSMOL'; // yield bearing SMOL
  uint256 public constant TOTAL_TOKENS = 4269;

  // Public sale params
  uint256 public publicSaleStartTime;
  bool public publicSaleActive;
  bool public isRevealing;

  mapping(address => bool) public canMintFreeNft;
  mapping(address => uint256) public mintedFreeNftTimestamp;

  mapping(uint256 => uint256) public tokenMintedAt;
  mapping(uint256 => uint256) public tokenLastTransferredAt;

  event PublicSaleStart(uint256 indexed _saleStartTime);
  event PublicSalePaused(uint256 indexed _timeElapsed);
  event PublicSaleActive(bool indexed _publicSaleActive);
  event RoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);

  // Public sale active modifier
  modifier whenPublicSaleActive() {
    require(publicSaleActive, 'Public sale is not active');
    _;
  }

  // Public sale not active modifier
  modifier whenPublicSaleNotActive() {
    require(
      !publicSaleActive && publicSaleStartTime == 0,
      'Public sale is already active'
    );
    _;
  }

  // Owner or public sale active modifier
  modifier whenOwnerOrPublicSaleActive() {
    require(
      owner() == _msgSender() || publicSaleActive,
      'Public sale is not active'
    );
    _;
  }

  // -- Constructor --//
  constructor(string memory _baseTokenURI) ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
    baseTokenURI = _baseTokenURI;
    _rewards = new SMOLNftRewards(address(this));
    _rewards.transferOwnership(_msgSender());

    _isRewardsExcluded[address(this)] = true;
    _isRewardsExcluded[address(_rewards)] = true;
  }

  // -- External Functions -- //
  // Start public sale
  function startPublicSale() external onlyOwner whenPublicSaleNotActive {
    publicSaleStartTime = block.timestamp;
    publicSaleActive = true;
    emit PublicSaleStart(publicSaleStartTime);
  }

  // Set this value to the block.timestamp you'd like to reset to
  // Created as a way to fast foward in time for tier timing unit tests
  // Can also be used if needing to pause and restart public sale from original start time (returned in startPublicSale() above)
  function setPublicSaleStartTime(uint256 _publicSaleStartTime)
    external
    onlyOwner
  {
    publicSaleStartTime = _publicSaleStartTime;
    emit PublicSaleStart(publicSaleStartTime);
  }

  // Toggle public sale
  function togglePublicSaleActive() external onlyOwner {
    publicSaleActive = !publicSaleActive;
    emit PublicSaleActive(publicSaleActive);
  }

  // Pause public sale
  function pausePublicSale() external onlyOwner whenPublicSaleActive {
    publicSaleActive = false;
    emit PublicSalePaused(getElapsedSaleTime());
  }

  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (
      royaltyAddress,
      (_salePrice * royaltyBasisPoints) / PERCENT_DENOMENATOR
    );
  }

  function getElapsedSaleTime() public view returns (uint256) {
    return publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
  }

  function getRewards() external view returns (address) {
    return address(_rewards);
  }

  // Get mints left
  function getMintsLeft() public view returns (uint256) {
    uint256 currentSupply = super.totalSupply();
    return TOTAL_TOKENS - currentSupply;
  }

  // Mint token - requires tier and amount
  function mint(uint256 _amount) public payable whenOwnerOrPublicSaleActive {
    bool _isOwner = owner() == _msgSender();
    require(getElapsedSaleTime() > 0, 'sale not active');
    require(
      _isOwner || block.timestamp > userLastMinted[_msgSender()] + FIVE_MINUTES,
      'can only mint once per 5 minutes'
    );
    require(
      _amount > 0 && (_isOwner || _amount <= maxPerMint),
      'must mint at least one and cannot exceed max amount'
    );
    // Check there enough NFTs left to mint
    require(_amount <= getMintsLeft(), 'minting would exceed max supply');

    userLastMinted[_msgSender()] = block.timestamp;

    // pay for NFTs & handle free NFT mint logic here as well
    if (
      canMintFreeNft[_msgSender()] && mintedFreeNftTimestamp[_msgSender()] == 0
    ) {
      mintedFreeNftTimestamp[_msgSender()] = block.timestamp;
      _payToMint(_amount - 1);
    } else {
      _payToMint(_amount);
    }

    for (uint256 i = 0; i < _amount; i++) {
      _tokenIds.increment();

      // Safe mint
      _safeMint(_msgSender(), _tokenIds.current());

      // Store minted at timestamp by token id
      tokenMintedAt[_tokenIds.current()] = block.timestamp;
    }
    _setRewardsShares(address(0), _msgSender());
  }

  function _payToMint(uint256 _amount) internal whenOwnerOrPublicSaleActive {
    require(_amount > 0, 'must mit at least 1');
    bool isOwner = owner() == _msgSender();
    if (isOwner) {
      if (msg.value > 0) {
        Address.sendValue(payable(_msgSender()), msg.value);
      }
      return;
    }

    ISmoltingInu smolToken = ISmoltingInu(smol);
    uint256 totalNativeCost = nativeCost * _amount;
    uint256 totalSmolCost = smolCost * _amount;

    if (totalNativeCost > 0) {
      require(
        msg.value >= totalNativeCost,
        'not enough native token provided to mint'
      );
      uint256 balanceBefore = address(this).balance;
      Address.sendValue(payable(paymentAddress), totalNativeCost);
      // refund user for any extra native sent
      if (msg.value > totalNativeCost) {
        Address.sendValue(payable(_msgSender()), msg.value - totalNativeCost);
      }
      require(
        address(this).balance >= balanceBefore - msg.value,
        'too much native sent'
      );
    } else if (msg.value > 0) {
      Address.sendValue(payable(_msgSender()), msg.value);
    }

    if (totalSmolCost > 0) {
      require(
        smolToken.balanceOf(_msgSender()) >= totalSmolCost,
        'not enough SMOL balance to mint'
      );
      smolToken.gameBurn(_msgSender(), totalSmolCost);
    }
  }

  function setPaymentAddress(address _address) external onlyOwner {
    paymentAddress = _address;
  }

  // Set royalty wallet address
  function setRoyaltyAddress(address _address) external onlyOwner {
    royaltyAddress = _address;
  }

  function setSmolToken(address _smol) external onlyOwner {
    smol = _smol;
  }

  function setNativeCost(uint256 _wei) external onlyOwner {
    nativeCost = _wei;
  }

  function setSmolCost(uint256 _numTokens) external onlyOwner {
    smolCost = _numTokens;
  }

  // Set royalty basis points
  function setRoyaltyBasisPoints(uint256 _basisPoints) external onlyOwner {
    royaltyBasisPoints = _basisPoints;
    emit RoyaltyBasisPoints(_basisPoints);
  }

  // Set base URI
  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
  }

  function setRewards(address _contract) external onlyOwner {
    _rewards = SMOLNftRewards(_contract);
  }

  function setIsRewardsExcluded(address _wallet, bool _isExcluded)
    public
    onlyOwner
  {
    _isRewardsExcluded[_wallet] = _isExcluded;
    if (_isExcluded) {
      _rewards.setShare(_wallet, 0);
    } else {
      _rewards.setShare(_wallet, balanceOf(_wallet));
    }
  }

  function setMaxPerMint(uint8 _max) external onlyOwner {
    require(maxPerMint > 0, 'have to be able to mint at least 1 NFT');
    maxPerMint = _max;
  }

  function setCanMintFreeNft(address _wallet, bool _canMintFree)
    external
    onlyOwner
  {
    canMintFreeNft[_wallet] = _canMintFree;
  }

  function setCanMintFreeNftBulk(address[] memory _wallets, bool _canMintFree)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _wallets.length; i++) {
      canMintFreeNft[_wallets[i]] = _canMintFree;
    }
  }

  function isRewardsExcluded(address _wallet) external view returns (bool) {
    return _isRewardsExcluded[_wallet];
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_tokenId), 'Nonexistent token');

    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), '.json'));
  }

  function isMinted(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract.json'));
  }

  // Override supportsInterface - See {IERC165-supportsInterface}
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  // Pauses all token transfers - See {ERC721Pausable}
  function pause() public virtual onlyOwner {
    _pause();
  }

  // Unpauses all token transfers - See {ERC721Pausable}
  function unpause() public virtual onlyOwner {
    _unpause();
  }

  function reveal() external onlyOwner {
    require(!isRevealing, 'already revealing');
    isRevealing = true;
  }

  //-- Internal Functions --//

  function _setRewardsShares(address _from, address _to) internal {
    if (!_isRewardsExcluded[_from] && _from != address(0)) {
      _rewards.setShare(_from, balanceOf(_from));
    }
    if (!_isRewardsExcluded[_to] && _to != address(0)) {
      _rewards.setShare(_to, balanceOf(_to));
    }
  }

  // Get base URI
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  // Before all token transfer
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
    // Store token last transfer timestamp by id
    tokenLastTransferredAt[_tokenId] = block.timestamp;

    _setRewardsShares(_from, _to);

    super._beforeTokenTransfer(_from, _to, _tokenId);
  }
}