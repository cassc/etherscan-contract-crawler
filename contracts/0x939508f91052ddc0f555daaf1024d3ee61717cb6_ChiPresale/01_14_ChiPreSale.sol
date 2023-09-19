// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/ChiErrors.sol";

contract ChiPresale is Ownable, Pausable {
  using SafeERC20 for IERC20;

  uint256 public constant totalSupply = 1000000 * 1e18; // in CHI
  uint256 public constant PRICE_MULTIPLIER = 1e4;
  ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  IWETH public immutable wethToken; // WETH
  IERC20 public immutable usdcToken; // USDC
  IERC20 public immutable tradeToken; // LUSD

  bytes32 public merkleRoot = "";
  uint256 public totalAmount = 0;
  uint256 public price = 10 * PRICE_MULTIPLIER; // in CHI/LUSD = 0.1 USD
  uint256 public minAmount = 1000 * 1e18; // in CHI
  uint256 public maxAmount = 500000 * 1e18; // in CHI
  uint256 public startTime;
  uint256 public publicStartTime;
  uint256 public endTime;

  address public treasuryAddr = 0xBF5044a8171392406586162D6b3C210Dfb0b6F96;

  mapping(address => uint256) public userBalance;

  event BuyToken(address indexed _account, uint256 _chiAmount);

  modifier isEligible(bytes32[] memory proof) {
    if (startTime > block.timestamp) {
      revert ChiErrors.NotStarted(block.timestamp);
    }
    if (endTime < block.timestamp) {
      revert ChiErrors.Ended(block.timestamp);
    }
    if (publicStartTime > block.timestamp) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      if (!MerkleProof.verify(proof, merkleRoot, leaf)) {
        revert ChiErrors.InvalidProof(msg.sender);
      }
    }
    _;
  }

  constructor(
    IWETH _wethToken,
    IERC20 _usdcToken,
    IERC20 _tradeToken,
    uint256 _startTime,
    uint256 _publicStartTime,
    uint256 _endTime
  ) {
    wethToken = _wethToken;
    usdcToken = _usdcToken;
    tradeToken = _tradeToken;
    setStartTime(_startTime);
    setPublicStartTime(_publicStartTime);
    setEndTime(_endTime);
  }

  function swapExactInputMultiHop(bytes memory path, uint256 amountIn) private returns (uint256 amountOut) {
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: path,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: 0
    });

    amountOut = swapRouter.exactInput{value: amountIn}(params);
  }

  function buyTokenWithEth(bytes32[] memory proof) external payable whenNotPaused isEligible(proof) {
    bytes memory path = abi.encodePacked(
      address(wethToken),
      uint24(500),
      address(usdcToken),
      uint24(500),
      address(tradeToken)
    );

    uint256 amountOut = swapExactInputMultiHop(path, msg.value);
    tradeToken.approve(address(this), amountOut);
    _buyToken(address(this), amountOut);
  }

  function buyToken(uint256 amount, bytes32[] memory proof) external whenNotPaused isEligible(proof) {
    _buyToken(msg.sender, amount);
  }

  function _buyToken(address payer, uint256 amount) private {
    uint256 chiAmount = (amount * price) / PRICE_MULTIPLIER;

    if (chiAmount + totalAmount > totalSupply) {
      revert ChiErrors.NotEnoughAmount(amount);
    }
    if (chiAmount + userBalance[msg.sender] < minAmount) {
      revert ChiErrors.UnderMinAmount(amount);
    }
    if (chiAmount + userBalance[msg.sender] > maxAmount) {
      revert ChiErrors.OverMaxAmount(amount);
    }

    tradeToken.safeTransferFrom(payer, treasuryAddr, amount);
    userBalance[msg.sender] += chiAmount;
    totalAmount += chiAmount;

    emit BuyToken(msg.sender, chiAmount);
  }

  // OWNERABLE FUNCTIONS

  function pauseSale() external whenNotPaused onlyOwner {
    _pause();
  }

  function unpauseSale() external whenPaused onlyOwner {
    _unpause();
  }

  function setPrice(uint256 _price) external onlyOwner {
    if (_price <= 0) {
      revert ChiErrors.ZeroAmount();
    }
    price = _price;
  }

  function setMinAmount(uint256 _amount) external onlyOwner {
    if (_amount <= 0) {
      revert ChiErrors.ZeroAmount();
    }
    minAmount = _amount;
  }

  function setMaxAmount(uint256 _amount) external onlyOwner {
    if (_amount <= 0) {
      revert ChiErrors.ZeroAmount();
    }
    maxAmount = _amount;
  }

  function setStartTime(uint256 _time) public onlyOwner {
    startTime = _time;
  }

  function setPublicStartTime(uint256 _time) public onlyOwner {
    publicStartTime = _time;
  }

  function setEndTime(uint256 _time) public onlyOwner {
    endTime = _time;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setTreasuryAddr(address _account) external onlyOwner {
    if (_account == address(0)) {
      revert ChiErrors.ZeroAddress();
    }
    treasuryAddr = _account;
  }
}