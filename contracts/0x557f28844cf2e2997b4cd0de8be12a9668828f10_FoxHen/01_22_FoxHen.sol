// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "./Metadata.sol";

contract FoxHen is ERC721Enumerable, Ownable, VRFConsumerBase {
  uint256 public constant ETH_PRICE = 0.065 ether;
  uint256 public constant MAX_TOKENS = 20000;
  uint256 public constant ETH_TOKENS = 7000;
  uint16 public purchased = 0;

  uint24 public constant poolFee = 3000;
  address public WETH9;

  struct Minting {
    address minter;
    uint256 tokenId;
    bool fulfilled;
  }
  mapping(bytes32=>Minting) mintings;

  struct TokenWithMetadata {
    uint256 tokenId;
    bool isFox;
    string metadata;
  }

  mapping(uint256=>bool) public isFox;
  uint256[] public foxes;
  uint16 public stolenMints;
  mapping(uint256=>uint256) public traitsOfToken;
  mapping(uint256=>bool) public traitsTaken;
  bool public mainSaleStarted;
  mapping(bytes=>bool) public signatureUsed;

  IERC20 eggs;
  ISwapRouter swapRouter;
  AggregatorV3Interface priceFeed;
  Metadata metadata;

  bytes32 internal keyHash;
  uint256 internal fee;

  constructor(address _eggs, address _vrf, address _link, bytes32 _keyHash, uint256 _fee, address _swapRouter, address _metadata, address _WETH, address _feed) ERC721("FoxHen", 'FH') VRFConsumerBase(_vrf, _link) {
    eggs = IERC20(_eggs);
    swapRouter = ISwapRouter(_swapRouter);
    priceFeed = AggregatorV3Interface(_feed);
    metadata = Metadata(_metadata);
    keyHash = _keyHash;
    fee = _fee;
    WETH9 = _WETH;
    require(IERC20(_link).approve(msg.sender, type(uint256).max));
    require(eggs.approve(msg.sender, type(uint256).max));
  }

  // Internal
  function swapEthForLINK(uint256 amount) internal {
    if (LINK.balanceOf(address(this)) < amount * fee) {
      uint256 minAmount = 99 * linkPrice() * msg.value / 100;
      ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: address(LINK),
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: msg.value,
            amountOutMinimum: minAmount,
            sqrtPriceLimitX96: 0
        });
      swapRouter.exactInputSingle{ value: msg.value }(params);
    }
  }

  function setTraits(uint256 tokenId, uint256 seed) internal returns (uint256) {
    uint256 maxTraits = 16 ** 4;
    uint256 nextRandom = uint256(keccak256(abi.encode(seed, 1)));
    uint256 traitsID = nextRandom % maxTraits;
    while(traitsTaken[traitsID]) {
      nextRandom = uint256(keccak256(abi.encode(nextRandom, 1)));
      traitsID = nextRandom % maxTraits;
    }
    traitsTaken[traitsID] = true;
    traitsOfToken[tokenId] = traitsID;
    return traitsID;
  }

  function setSpecies(uint256 tokenId, uint256 seed) internal returns (bool) {
    uint256 random = uint256(keccak256(abi.encode(seed, 2))) % 10;
    if (random == 0) {
      isFox[tokenId] = true;
      foxes.push(tokenId);
      return true;
    }
    return false;
  }

  function getRecipient(uint256 tokenId, address minter, uint256 seed) internal view returns (address) {
    if (tokenId > ETH_TOKENS && (uint256(keccak256(abi.encode(seed, 3))) % 10) == 0) {
      uint256 fox = foxes[uint256(keccak256(abi.encode(seed, 4))) % foxes.length];
      address owner = ownerOf(fox);
      if (owner != address(0)) {
        return owner;
      }
    }
    return minter;
  }

  // Reads
  function eggsPrice() public view returns (uint256) {
    require(purchased >= ETH_TOKENS);
    uint16 secondGen = purchased - uint16(ETH_TOKENS);
    if (secondGen < 5000) {
      return 30 ether;
    }
    if (secondGen < 10000) {
      return 60 ether;
    }
    return 120 ether;
  }

  function foxCount() public view returns (uint256) {
    return foxes.length;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return metadata.tokenMetadata(isFox[tokenId], traitsOfToken[tokenId], tokenId);
  }

  function linkPrice() public view returns (uint256) {
    (, int price,,,) = priceFeed.latestRoundData();
    return uint256(price);
  }

  function allTokensOfOwner(address owner) public view returns (TokenWithMetadata[] memory) {
    uint256 balance = balanceOf(owner);
    TokenWithMetadata[] memory tokens = new TokenWithMetadata[](balance);
    for (uint256 i = 0; i < balance; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(owner, i);
      string memory data = tokenURI(tokenId);
      tokens[i] = TokenWithMetadata(tokenId, isFox[tokenId], data);
    }
    return tokens;
  }

  // Public
  function buyFromWhitelist(bytes memory signature, uint256 seed) public payable {
    address minter = _msgSender();
    require(tx.origin == minter, "Contracts not allowed");
    require(purchased + 1 <= ETH_TOKENS, "Sold out");
    require(ETH_PRICE <= msg.value, "You need to send enough eth");
    require(!signatureUsed[signature], "Signature already used");

    bytes32 messageHash = keccak256(abi.encodePacked("foxhen", msg.sender, seed));
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);

    address signer = ECDSA.recover(digest, signature);
    require(signer == owner(), "Invalid signature");
    signatureUsed[signature] = true;
    
    purchased += 1;

    swapEthForLINK(1);

    bytes32 requestId = requestRandomness(keyHash, fee);
    mintings[requestId] = Minting(minter, purchased, false);
  }

  function buyWithEth(uint16 amount) public payable {
    require(mainSaleStarted, "Main Sale hasn't started yet");
    address minter = _msgSender();
    require(tx.origin == minter, "Contracts not allowed");
    require(amount > 0 && amount <= 20, "Max 20 mints per tx");
    require(purchased + amount <= ETH_TOKENS, "Sold out");
    require(amount * ETH_PRICE <= msg.value, "You need to send enough eth");

    uint256 initialPurchased = purchased;
    purchased += amount;
    swapEthForLINK(amount);

    for (uint16 i = 1; i <= amount; i++) {
      bytes32 requestId = requestRandomness(keyHash, fee);
      mintings[requestId] = Minting(minter, initialPurchased + i, false);
    }
  }

  function buyWithEggs(uint16 amount) public {
    address minter = _msgSender();
    require(mainSaleStarted, "Main Sale hasn't started yet");
    require(tx.origin == minter, "Contracts not allowed");
    require(amount > 0 && amount <= 20, "Max 20 mints per tx");
    require(purchased > ETH_TOKENS, "Eggs sale not active");
    require(purchased + amount <= MAX_TOKENS, "Sold out");

    uint256 price = amount * eggsPrice();
    require(price <= eggs.allowance(minter, address(this)) && price <= eggs.balanceOf(minter), "You need to send enough eggs");
    
    uint256 initialPurchased = purchased;
    purchased += amount;
    require(eggs.transferFrom(minter, address(this), price));

    for (uint16 i = 1; i <= amount; i++) {
      bytes32 requestId = requestRandomness(keyHash, fee);
      mintings[requestId] = Minting(minter, initialPurchased + i, false);
    }
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    Minting storage minting = mintings[requestId];
    require(minting.minter != address(0));
    setSpecies(minting.tokenId, randomness);
    setTraits(minting.tokenId, randomness);

    address recipient = getRecipient(minting.tokenId, minting.minter, randomness);
    if (recipient != minting.minter) {
      stolenMints++;
    }
    _mint(recipient, minting.tokenId);
  }

  // Admin
  function withdraw(uint256 amount) external onlyOwner {
    payable(owner()).transfer(amount);
  }

  function toggleMainSale() public onlyOwner {
    mainSaleStarted = !mainSaleStarted;
  }
}