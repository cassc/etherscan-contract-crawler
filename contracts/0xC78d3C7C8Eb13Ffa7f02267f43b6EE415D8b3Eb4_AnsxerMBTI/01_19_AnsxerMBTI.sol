//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import "erc721psi/contracts/ERC721Psi.sol";

interface IUniswapRouter is ISwapRouter {
  function refundETH() external payable;
}

contract AnsxerMBTI is ERC721Psi, Ownable, Pausable {
  event Staked(address indexed owner, uint256[] tokenIds, uint256 timestamp);
  event Unstaked(address indexed owner, uint256[] tokenIds, uint256 timestamp);
  event Minted(uint256, uint256);
  event Received(address, uint256);

  enum MBTI {
    INTJ, INTP, INFJ, INFP,
    ISTJ, ISTP, ISFJ, ISFP,
    ENTJ, ENTP, ENFJ, ENFP,
    ESTJ, ESTP, ESFJ, ESFP
  }

  struct Allowlist {
      uint256 mintable;
      uint256 minted;
  }

  struct Order {
      MBTI mbti;
      uint256 amount;
  }

  struct TotalMint {
      string mbti;
      uint256 minted;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  //////////////
  // Constants
  //////////////

  uint256 public constant MAX_MINT_PER_TX = 16;
  uint256 public constant TEAM_EACH_MBTI_RESERVED = 25;
  uint256 public constant TEAM_TOTAL_RESERVED = 400;
  uint256 public constant MAX_EACH_MBTI_SUPPLY = 1_000;
  uint256 public constant MAX_SUPPLY = 16_000;
  uint256 public constant STAKING_DEADLINE = 4_294_967_295; // 2106-02-07
  uint256 public constant MINT_PRICE_USDC = 15_000_000; // $15

  //////////////
  // Internal
  //////////////

  uint8[16000] private _mbtiOfToken;
  uint16[16] private _mbtiTotalMints;
  string private _baseTokenURI;
  address private _signer;

  /////////////////////
  // Public Variables
  /////////////////////

  IUniswapRouter public constant swapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  IQuoter public constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
  address public immutable WETH9;
  address public immutable USDC;
  address public teamAddress;
  
  bool public isAllowlistSaleOn;
  bool public isPublicSaleOn;
  uint24 public poolFee = 500;
  uint256 public totalStaked;
  uint32[16000] public stakeAt;
  mapping(address => Allowlist) public allowlists;

  ////////////////
  // Actual Code
  ////////////////

  constructor(
    address signer,
    address _teamAddress,
    address _WETH9,
    address _USDC,
    string memory baseURI
  ) ERC721Psi("Ansxer MBTI", "AMBTI") {
    WETH9 = _WETH9; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    USDC = _USDC; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

    teamAddress = _teamAddress;
    _baseTokenURI = baseURI;
    _signer = signer;
  }

  //////////////////////
  // Setters for Owner
  //////////////////////

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setTeamAddress(address addr) external onlyOwner {
    teamAddress = addr;
  }

  function setSigner(address addr) external onlyOwner {
    _signer = addr;
  }

  function setPoolFee(uint256 _poolFee) external onlyOwner {
    poolFee = uint24(_poolFee);
  }

  function setAllowlistSaleOn() external onlyOwner {
    require(totalSupply() != 0, "Team hasn't minted yet");
    isAllowlistSaleOn = true;
  }

  function setPublicSaleOn() external onlyOwner {
    require(isAllowlistSaleOn, "Should let allowlist mint first");
    isAllowlistSaleOn = false;
    isPublicSaleOn = true;
  }

  function setAllowlist(address[] calldata addrs, uint256[] calldata maxMints) external onlyOwner {
    require(addrs.length == maxMints.length, "Both length must be the same!");
    unchecked {
      for (uint i; i < addrs.length; ++i) {
        allowlists[addrs[i]] = Allowlist(maxMints[i], 0);
      }
    }
  }

  function pauseMint(bool paused) external onlyOwner {
    if (paused)
      _pause();
    else
      _unpause();
  }
  
  ////////////
  // Minting
  ////////////

  function teamMint() external onlyOwner {
    require(totalSupply() == 0, "Team has already minted");
    unchecked {
      uint256 startTokenId;
      uint256[] memory tokenIds = new uint256[](TEAM_TOTAL_RESERVED);
      uint32 timestamp = uint32(block.timestamp);

      for (uint i; i < 16; ++i) {
        startTokenId = TEAM_EACH_MBTI_RESERVED * i;

        for (uint n; n < TEAM_EACH_MBTI_RESERVED; ++n) {
          _mbtiOfToken[startTokenId + n] = uint8(i);
          stakeAt[startTokenId + n] = timestamp;
          tokenIds[startTokenId + n] = startTokenId + n;
        }

        _mbtiTotalMints[i] = uint16(TEAM_EACH_MBTI_RESERVED);
      }
    
      totalStaked = TEAM_TOTAL_RESERVED;
      _mintMBTI(teamAddress, TEAM_TOTAL_RESERVED, tokenIds);
    }
  }

  function allowlistMint(Order[] calldata orders, bool staked, uint256 v, bytes32 r, bytes32 s) external whenNotPaused callerIsUser {
    require(isAllowlistSaleOn, "Contract is not ready for allowlist");

    bytes32 msgHash = keccak256(abi.encodePacked(address(this), msg.sender));
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    require(_signer == ecrecover(messageDigest, uint8(v), r, s), "You are not eligible for allowlist mint");

    uint256 mintable = allowlists[msg.sender].mintable;
    if (mintable == 0) {
      mintable = 1; // default mintable without setAllowlist
    }
    
    uint256 minted = allowlists[msg.sender].minted;
    uint256 mintAvailable = mintable - minted;
    (uint256 totalAmount, uint256[] memory stakedTokenIds) = _getTotalAmount(orders, staked);

    require(mintAvailable > 0, "Maximum allowlist mint quota");
    require(totalAmount > 0, "Amount cannot be zero");
    require(totalAmount <= mintAvailable, "Over allowlist mint quota");
    require(totalAmount <= MAX_MINT_PER_TX, "Maximum mint per transaction");
    require(totalAmount + totalSupply() <= MAX_SUPPLY, "Maximum supply");

    allowlists[msg.sender].minted += totalAmount;
    _mintMBTI(msg.sender, totalAmount, stakedTokenIds);
  }

  function publicSaleMint(Order[] calldata orders, bool staked) external payable whenNotPaused callerIsUser {
    require(isPublicSaleOn, "Contract is not ready for public sale");
    require(msg.value > 0, "ETH amount is required");
    
    (uint256 totalAmount, uint256[] memory stakedTokenIds) = _getTotalAmount(orders, staked);

    require(totalAmount > 0, "Amount cannot be zero");
    require(totalAmount <= MAX_MINT_PER_TX, "Maximum mint per transaction");
    require(totalAmount + totalSupply() <= MAX_SUPPLY, "Maximum supply");

    // Convert ETH to USDC to teamAddress
    uint256 usdcAmount = totalAmount * MINT_PRICE_USDC;
    uint256 deadline = block.timestamp + 20 minutes;
    IUniswapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
        WETH9,       // tokenIn
        USDC,        // tokenOut
        poolFee,     // fee
        teamAddress, // recipient
        deadline,    // deadline
        usdcAmount,  // amountOut
        msg.value,   // amountInMaximum
        0            // sqrtPriceLimitX96
    );
    
    uint256 ethAmountIn = swapRouter.exactOutputSingle{ value: msg.value }(params);
    swapRouter.refundETH();

    // refund leftover ETH to user
    if (msg.value > ethAmountIn) {
      payable(msg.sender).transfer(msg.value - ethAmountIn);
    }

    _mintMBTI(msg.sender, totalAmount, stakedTokenIds);
  }

  function _getTotalAmount(Order[] calldata orders, bool staked) internal returns (uint256, uint256[] memory) {
    unchecked {
      uint256 totalAmount;
      uint256 startTokenId = totalSupply();
      uint16 amount;
      uint8 mbti;

      for (uint i; i < orders.length; ++i) {
        mbti = uint8(orders[i].mbti);
        amount = uint16(orders[i].amount);

        require(amount > 0, "Amount cannot be zero");
        require(amount + _mbtiTotalMints[mbti] <= MAX_EACH_MBTI_SUPPLY, "Maximum MBTI supply");
        
        for (uint n; n < amount; ++n) {
          _mbtiOfToken[startTokenId + totalAmount + n] = mbti;
        }

        _mbtiTotalMints[mbti] += amount;
        totalAmount += amount;
      }
      
      if (staked) {
        uint256[] memory stakedTokenIds = new uint256[](totalAmount);
        uint32 timestamp = uint32(block.timestamp);

        for (uint i; i < totalAmount; ++i) {
          stakeAt[startTokenId + i] = timestamp;
          stakedTokenIds[i] = startTokenId + i;
        }

        totalStaked += totalAmount;
        return (totalAmount, stakedTokenIds);
      }

      return (totalAmount, new uint256[](0));
    }
  }

  function _mintMBTI(address to, uint256 amount, uint256[] memory stakedTokenIds) internal {
    _safeMint(to, amount);
    emit Minted(amount, totalSupply());

    if (stakedTokenIds.length > 0) {
      emit Staked(msg.sender, stakedTokenIds, block.timestamp);
    }
  }

  ////////////
  // Staking
  ////////////

  function stake(uint256[] calldata tokenIds) external {
    require(tokenIds.length > 0, "tokenIds must not be empty!");

    uint256 timestamp = block.timestamp;
    require(timestamp <= STAKING_DEADLINE, "Staking is closed, you can unstake only");

    unchecked {
      for (uint i; i < tokenIds.length; ++i) {
        require(ownerOf(tokenIds[i]) == msg.sender, "You are not the owner");
        require(stakeAt[tokenIds[i]] == 0, "Token has been staked");

        stakeAt[tokenIds[i]] = uint32(timestamp);
      }
      
      totalStaked += tokenIds.length;
      emit Staked(msg.sender, tokenIds, block.timestamp);
    }
  }

  function unstake(uint256[] calldata tokenIds) external {
    require(tokenIds.length > 0, "tokenIds must not be empty!");
    unchecked {
      for (uint i; i < tokenIds.length; ++i) {
        require(ownerOf(tokenIds[i]) == msg.sender, "You are not the owner");
        require(stakeAt[tokenIds[i]] > 0, "Token hasn't been staked");

        delete stakeAt[tokenIds[i]];
      }

      totalStaked -= tokenIds.length;
      emit Unstaked(msg.sender, tokenIds, block.timestamp);
    }
  }

  function _beforeTokenTransfers(address, address, uint256 id, uint256) override internal virtual {
    if (_exists(id)) require(stakeAt[id] == 0, "Token has been staked");
  }

  ///////////////////
  // Internal Views
  ///////////////////

  function _baseURI() override internal view virtual returns (string memory) {
    return _baseTokenURI;
  }

  /////////////////
  // Public Views
  /////////////////

  function mbtiKeys() public pure returns (string[16] memory) {
    return ["INTJ", "INTP", "INFJ", "INFP",
            "ISTJ", "ISTP", "ISFJ", "ISFP",
            "ENTJ", "ENTP", "ENFJ", "ENFP",
            "ESTJ", "ESTP", "ESFJ", "ESFP"];
  }

  function mbtiOfToken(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "Nonexistent token");
    return mbtiKeys()[_mbtiOfToken[tokenId]];
  }

  function mbtiTotalMints() public view returns (TotalMint[16] memory) {
    unchecked {
      string[16] memory keys = mbtiKeys();
      TotalMint[16] memory totalMints;
      for (uint i; i < keys.length; ++i) {
        totalMints[i] = TotalMint(keys[i], _mbtiTotalMints[i]);
      }
      return totalMints;
    }
  }

  function stakedBalanceOf(address owner) public view virtual returns (uint256) {
    unchecked {
      uint256 count;
      for (uint i; i < _minted; ++i){
        if (owner == ownerOf(i) && stakeAt[i] > 0){
          ++count;
        }
      }
      return count;
    }
  }

  function tokensOfOwner(address owner, bool stakedOnly) external view virtual returns (uint256[] memory) {
    unchecked {
      uint256 tokenIdsIdx;
      uint256 tokenIdsLength = stakedOnly ? stakedBalanceOf(owner) : balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      for (uint i; tokenIdsIdx != tokenIdsLength; ++i) {
        if (owner == ownerOf(i)) {
          if (!stakedOnly || stakeAt[i] > 0) {
            tokenIds[tokenIdsIdx++] = i;
          }
        }
      }
      return tokenIds;
    }
  }

  // DO NOT CALL ON-CHAIN (for front-end only)
  function getEstimatedETHforUSDC(uint256 usdcAmount) external payable returns (uint256) {
    return quoter.quoteExactOutputSingle(
        WETH9,      // tokenIn
        USDC,       // tokenOut
        poolFee,    // fee
        usdcAmount, // amountOut
        0           // sqrtPriceLimitX96
    );
  }

  /////////////
  // Fallback
  /////////////

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}