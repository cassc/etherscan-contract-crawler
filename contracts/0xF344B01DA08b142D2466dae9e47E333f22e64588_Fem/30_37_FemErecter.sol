// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './InitializedOwnable.sol';
import './IFemErecter.sol';

contract FemErecter is InitializedOwnable, IFemErecter {
  using SafeERC20 for IERC20;

  IFem public immutable override fem;
  address public immutable override devAddress;
  uint256 public immutable override devTokenBips;
  uint256 public immutable override saleStartTime;
  uint256 public immutable override saleEndTime;
  uint256 public immutable override saleDuration;
  uint256 public immutable override spendDeadline;
  uint256 public immutable override minimumEthRaised;

  bool public override ethClaimed;
  mapping(address => uint256) public override depositedAmount;

  modifier requireState(SaleState _state, string memory errorMessage) {
    require(state() == _state, errorMessage);
    _;
  }

  constructor(
    address _owner,
    address _devAddress,
    uint256 _devTokenBips,
    address _fem,
    uint32 _saleStartTime,
    uint32 _saleDuration,
    uint32 _timeToSpend,
    uint256 _minimumEthRaised
  ) InitializedOwnable(_owner) {
    require(_devTokenBips > 0, 'devTokenBips can not be 0');
    require(_devTokenBips < 1000, 'devTokenBips too high');
    require(_saleStartTime > block.timestamp, 'start too early');
    devAddress = _devAddress;
    devTokenBips = _devTokenBips;
    fem = IFem(_fem);
    saleStartTime = _saleStartTime;
    uint256 endTime = _saleStartTime + _saleDuration;
    saleEndTime = endTime;
    saleDuration = _saleDuration;
    spendDeadline = endTime + _timeToSpend;
    minimumEthRaised = _minimumEthRaised;
  }

  /**
   * @dev Reports the current state of the token sale.
   */
  function state() public view override returns (SaleState) {
    if (block.timestamp < saleStartTime) return SaleState.PENDING;
    if (block.timestamp < saleEndTime) return SaleState.ACTIVE;
    // If ETH has been claimed, the sale was a success
    if (ethClaimed) return SaleState.SUCCESS;
    // If insufficient ETH has been raised or deadline has passed, sale was a failure
    if (address(this).balance < minimumEthRaised || block.timestamp >= spendDeadline) return SaleState.FAILURE;
    // Sale is over with enough ETH raised, deadline has not passed to spend it
    return SaleState.FUNDS_PENDING;
  }

  /**
   * @notice Allows governance to claim ETH raised from the sale.
   * note: Only callable if {state()} is {SaleState.FUNDS_PENDING}
   * - Sale is over.
   * - Spend deadline has not passed.
   * - ETH has not already been claimed.
   * - More than {minimumEthRaised} was raised by the sale.
   */
  function claimETH(address to)
    external
    override
    onlyOwner
    requireState(SaleState.FUNDS_PENDING, 'Funds not pending governance claim')
  {
    ethClaimed = true;
    uint256 amount = address(this).balance;
    _sendETH(to, amount);
    emit EthClaimed(to, amount);
    fem.mint(devAddress, (fem.totalSupply() * devTokenBips) / 10000);
    fem.transferOwnership(owner());
  }

  /**
   * @notice Deposit ETH in exchange for equivalent amount of FEM.
   * note: Only callable if {state()} is {SaleState.ACTIVE}
   * - Sale has started.
   * - Sale is not over.
   */
  function deposit() external payable override requireState(SaleState.ACTIVE, 'Sale not active') {
    require(msg.value > 0, 'Can not deposit 0 ETH');
    depositedAmount[msg.sender] += msg.value;
    fem.mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  /**
   * @notice Burn FEM in exchange for equivalent amount of ETH.
   * note: Only callable if {state()} is {SaleState.FAILURE}
   * - Sale is over.
   * - Insufficient ETH raised OR spend deadline has passed without ETH being claimed.
   */
  function burnFem(uint256 amount) public override requireState(SaleState.FAILURE, 'Sale has not failed') {
    fem.burn(msg.sender, amount);
    _sendETH(_msgSender(), amount);
    emit Withdraw(msg.sender, amount);
  }

  function _sendETH(address to, uint256 amount) internal {
    (bool success, ) = to.call{value: amount}('');
    require(success, 'Failed to transfer ETH');
  }
}