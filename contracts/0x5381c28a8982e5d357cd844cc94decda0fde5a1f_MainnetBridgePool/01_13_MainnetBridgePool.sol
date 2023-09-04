// "SPDX-License-Identifier: MIT"

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import './Uniswap.sol';

contract MainnetBridgePool is AccessControl, ReentrancyGuard {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public raini;

  event Deposited(address indexed spender, address recipient, uint256 amount, uint256 requestId);
  event Withdrawn(address indexed owner, uint256 amount, uint256 requestId);
  event EthWithdrawn(uint256 amount);
  event FeeSet(uint256 fee, uint256 percentFee, uint256 percentFeeDecimals);
  event AutoWithdrawFeeSet(bool autoWithdraw);
  event TreasuryAddressSet(address treasuryAddress);

  uint256 public  requestId;
  uint256 public  fee;
  uint256 public  percentFee;
  uint    public  percentFeeDecimals;
  bool    public  autoWithdrawFee;
  address public  treasuryAddress;

  address private constant  UNIROUTER     = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant  FACTORY       = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address private           WETHAddress   = Uniswap(UNIROUTER).WETH();

  constructor(address _raini) {
    require(_raini != address(0), "MainnetBridgePool: _raini is zero address");

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    treasuryAddress = _msgSender();
    raini = IERC20(_raini);
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "MainnetBridgePool: caller is not a minter");
    _;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MainnetBridgePool: caller is not an owner");
    _;
  }

  function getFee(uint _amount) public view returns (uint256) {
    address lp = Uniswap(FACTORY).getPair(address(raini), WETHAddress);
    (uint reserve0, uint reserve1, ) = Uniswap(lp).getReserves();
    uint256 eth;
    if(Uniswap(lp).token0() == address(raini)) {
      eth = reserve1.mul(_amount).div(reserve0);
    } else {
      eth = reserve0.mul(_amount).div(reserve1);
    }
    return fee + eth.mul(percentFee).div(10 ** percentFeeDecimals);
  }

  function setFee(uint256 _fee, uint256 _percentFee, uint256 _percentFeeDecimals)
    external onlyOwner {
      fee = _fee;
      percentFee = _percentFee;
      percentFeeDecimals = _percentFeeDecimals;
      emit FeeSet(_fee, _percentFee, _percentFeeDecimals);
  }

  function setAutoWithdrawFee(bool _autoWithdrawFee)
    external onlyOwner {
      autoWithdrawFee = _autoWithdrawFee;
      emit AutoWithdrawFeeSet(autoWithdrawFee);
  }

  function setTreasuryAddress(address _treasuryAddress)
    external onlyOwner {
      treasuryAddress = _treasuryAddress;
      emit TreasuryAddressSet(_treasuryAddress);
  }  

  function deposit(address _recipient, uint256 _amount) 
    external payable nonReentrant {
      uint256 depositFee = getFee(_amount);
      require(msg.value >= depositFee, "MainnetBridgePool: not enough eth");

      raini.safeTransferFrom(_msgSender(), address(this), _amount);

      uint256 refund = msg.value - depositFee;
      if(refund > 0) {
        (bool refundSuccess, ) = _msgSender().call{ value: refund }("");
        require(refundSuccess, "MainnetBridgePool: refund transfer failed");
      }

      if (autoWithdrawFee) {
        (bool withdrawSuccess, ) = treasuryAddress.call{ value: depositFee }("");
        require(withdrawSuccess, "MainnetBridgePool: withdraw transfer failed");
      }

      requestId++;
      emit Deposited(_msgSender(), _recipient, _amount, requestId);
  }

  function withdraw(address[] memory _owners, uint256[] memory _amounts, uint256[] memory _requestsIds) 
    external onlyMinter {
      require(_owners.length == _amounts.length && _owners.length == _requestsIds.length, "MainnetBridgePool: Arrays length not equal");

      for (uint256 i; i < _owners.length; i++) {
        raini.safeTransfer(_owners[i], _amounts[i]);
        emit Withdrawn(_owners[i], _amounts[i], _requestsIds[i]);
      }
  }

  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "MainnetBridgePool: not enough balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "MainnetBridgePool: transfer failed");
      emit EthWithdrawn(_amount);
  }
}