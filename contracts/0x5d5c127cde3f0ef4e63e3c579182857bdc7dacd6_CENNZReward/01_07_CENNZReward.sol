pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./ERC20Mintable.sol";
import "./SafeMath.sol";

contract CENNZReward {
  using SafeMath for uint256;

  address public cennzContract;
  address public cpayContract;
  address public manager;

  bool public finished;
  uint public finishedBlockNumber;
  uint public earnRatePerBlock;

  mapping(address => uint256) public balances;
  mapping(address => uint) public blockNumbers;

  /**
   * All methods tagged by this can only be called by the manager account
   */
  modifier restricted() {
    require((msg.sender == manager), "No permission");
      _;
  }

  /**
   * Init
   */
  constructor () public {
    manager = 0x62C9BBbb7c295c15801B2Bd5aBaD44B01952545E;
    finished = false;

    uint256 base = 1 ether;
    earnRatePerBlock = base.div(10).div(365 * 24 * 60 * 60).mul(15);
  }

  /**
   * Setting cennzContractAddress and cpayContractAddress
   */
  function changeContractAddress(address cennzContractAddress, address cpayContractAddress)
    public
    restricted()
  {
    cennzContract = cennzContractAddress;
    cpayContract = cpayContractAddress;
  }

  function cennzContractAddress()
    public
    view
    returns (address)
  {
    return cennzContract;
  }

  function cpayContractAddress()
    public
    view
    returns (address)
  {
    return cpayContract;
  }

  function finish()
    public
    restricted()
  {
    finished = true;
    finishedBlockNumber = block.number;
  }

  /**
   * Transfering tokens from sender's account to manager's account
   */
  function transferAnyERC20Token(address tokenAddress, uint amount)
    public
    restricted()
    returns (bool success)
  {
    return ERC20(tokenAddress).transfer(manager, amount);
  }

  /**
   * If the reward progress is not finished
   * and the message sender never get deposited before,
   * depositing CENNZ from the message sender's account to this contract.
   */
  function deposit(uint256 amount, address referrer) public {
    require((balances[msg.sender] == 0), "Account exist");
    require(!finished, "Deposit not enabled");

    IERC20 CENNZ = IERC20(cennzContract);
    require(CENNZ.transferFrom(msg.sender, address(this), amount), "Transfer failed");

    balances[msg.sender] = amount;
    blockNumbers[msg.sender] = block.number;
  }

  /**
   * If the reward progress is not finished,
   * withdrawing CENNZ from the message sender's account
   * and giving CPay as reward to message sender.
   */
  function withdraw() public {
    require(finished, "Withdraw not enabled");

    uint256 balance = balances[msg.sender];
    uint256 reward = getEarning(msg.sender);

    require((balance > 0), "Invalid balance");

    IERC20 CENNZ = IERC20(cennzContract);
    ERC20Mintable CPay = ERC20Mintable(cpayContract);

    require(CENNZ.transfer(msg.sender, balance), "Transfer failed");
    require(CPay.mint(msg.sender, reward), "Reward mint failed");

    balances[msg.sender] = 0;
  }

  function balanceOf(address user)
    public
    view
    returns (uint256)
  {
    return balances[user];
  }

  function depositBlockNumberOf(address user)
    public
    view
    returns (uint)
  {
    return blockNumbers[user];
  }

  function getEarnRatePerBlock()
    public
    view
    returns (uint)
  {
    return earnRatePerBlock;
  }

  /**
   * Getting amount of token earned by the user
   */
  function getEarning(address user)
    public
    view
    returns (uint)
  {
    uint256 balance = balances[user];
    uint depositBlockNumber = blockNumbers[user];
    uint duration;

    if (finished && finishedBlockNumber > 0) {
      duration = finishedBlockNumber - depositBlockNumber;
    } else {
      duration = block.number - depositBlockNumber;
    }

    if (duration < 0) {
      duration = 0;
    }

    uint256 earning = balance.div(1 ether).mul(duration.mul(earnRatePerBlock));
    return earning;
  }
}
