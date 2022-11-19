//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Configurable} from "../utils/Configurable.sol";
import {ITokenERC20} from "../interfaces/ITokenERC20.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

contract Sale is AccessControl, Configurable {
  // stage
  struct Stage {
    uint256 supply; // stage supply
    uint256 rate; // tokens per wei (example: value 20 -> for 1 ETH gives 20 tokens)
    uint256 minAlloc; // minimum wei invested
    uint256 openingTime;
    uint256 closingTime;
  }
  struct Phase {
    Stage stage;
    uint256 soldTokens;
    uint256 weiRaised;
  }

  // storage
  Phase[] public stages;
  ITokenERC20 public erc20;
  IWhitelist public whitelist;

  address payable public immutable wallet;
  uint256 public immutable supply; // sale supply
  uint256 public immutable hardCap; // ether value of sale supply
  uint256 public weiRaised;

  // events
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );
  event TokenBurn(uint256 amount);

  // basic errors
  error SaleNotActive(uint256 timestamp);
  error SaleNotFinished(uint256 timestamp);
  error NoTokensLeft();

  // sale errors
  error InvalidConfig(uint256 supply, uint256 cap, address wallet, uint256 stagesCount);
  error SupplyMismatch(uint256 supply, uint256 totalSupply);
  error ValueMismatch(uint256 hardCap, uint256 totalValue);

  // stage errors
  error InvalidStageConfig(uint256 rate, uint8 i);
  error StartDateInThePast(uint256 start, uint256 now_, uint8 i);
  error StartDateNotBeforeEndDate(uint256 start, uint256 end, uint8 i);
  error SupplySmallerThanRate(uint256 supply, uint256 rate, uint8 i);

  // configuration errors
  error SupplyConfigurationMishmatch(uint256 saleSupply, uint256 supply);
  error BalanceNotEqualSupply(uint256 balance, uint256 supply);

  // buy errors
  error InvalidReceiver(address receiver);
  error NotEnoughBigInvestment(uint256 amount, uint256 minimum);
  error HardCapExceeded(uint256 amount, uint256 hardCap);
  error StageSupplyDrained(uint256 amount, uint256 supply);
  error WhitelistNotPassed(address member, uint256 weiAmount);

  // modifiers
  modifier onlyWhenActive() {
    getCurrentStage();
    _;
  }
  modifier onlyWhenFinished() {
    uint256 timestamp = block.timestamp;
    if (timestamp < closingTime()) {
      revert SaleNotFinished(timestamp);
    }
    _;
  }

  constructor(bytes memory arguments_) {
    // tx members
    address sender = tx.origin;

    // decode
    (uint256 supply_, uint256 hardCap_, address wallet_, Stage[] memory stages_) = abi.decode(
      arguments_,
      (uint256, uint256, address, Stage[])
    );

    // sale config
    uint256 stagesCount = stages_.length;
    if (
      supply_ == 0 ||
      hardCap_ == 0 ||
      wallet_ == address(0x0) ||
      stagesCount == 0 ||
      stagesCount > 16
    ) {
      revert InvalidConfig(supply_, hardCap_, wallet_, stages_.length);
    }

    uint256 totalSupply;
    uint256 totalValue;
    uint256 lastClosingTime = block.timestamp;
    for (uint8 i = 0; i < stages_.length; i++) {
      Stage memory stage = stages_[i];

      // stage config
      if (stage.rate == 0) {
        revert InvalidStageConfig(stage.rate, i);
      }

      // stage opening
      if (stage.openingTime < lastClosingTime) {
        revert StartDateInThePast(stage.openingTime, lastClosingTime, i);
      }

      // stage closing
      if (stage.openingTime >= stage.closingTime) {
        revert StartDateNotBeforeEndDate(stage.openingTime, stage.closingTime, i);
      }

      // requirement of OpenZeppelin crowdsale from V2
      // FIXME: to discuss if support for other rates is needed
      // 1 token (decimals 0) -> MAX 1 wei
      // 1 token (decimals 1) -> MAX 10 wei
      // 1 token (decimals 5) -> MAX 100 000 wei
      // 1 MLN token (decimals 0) -> MAX 1 MLN wei
      if (stage.supply < stage.rate) {
        revert SupplySmallerThanRate(stage.supply, stage.rate, i);
      }

      // increment counters
      totalValue += stage.supply / stage.rate;
      lastClosingTime = stage.closingTime;
      totalSupply += stage.supply;

      // storage
      stages.push(Phase(stage, 0, 0));
    }

    // sum of stages supply
    if (supply_ != totalSupply) {
      revert SupplyMismatch(supply_, totalSupply);
    }

    // sum of stages hard caps
    if (hardCap_ != totalValue) {
      revert ValueMismatch(hardCap_, totalValue);
    }

    // save storage
    supply = supply_;
    hardCap = hardCap_;
    wallet = payable(wallet_);

    // base role
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
  }

  function configure(address erc20_, address whitelist_)
    external
    onlyInState(State.UNCONFIGURED)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // storage
    erc20 = ITokenERC20(erc20_);
    whitelist = IWhitelist(whitelist_);

    // check supply vs params
    uint256 saleSupply = erc20.saleSupply();
    if (saleSupply != supply) {
      revert SupplyConfigurationMishmatch(saleSupply, supply);
    }

    // check configuration vs balance
    uint256 balance = erc20.balanceOf(address(this));
    if (saleSupply != balance) {
      revert BalanceNotEqualSupply(balance, saleSupply);
    }

    // state
    state = State.CONFIGURED;
  }

  function buyTokens(address _beneficiary)
    external
    payable
    onlyInState(State.CONFIGURED)
    onlyWhenActive
  {
    // current state
    uint8 currentStage = getCurrentStage();
    Phase memory phase = stages[currentStage];

    // tx members
    uint256 weiAmount = msg.value;

    // validate receiver
    if (_beneficiary == address(0)) {
      revert InvalidReceiver(_beneficiary);
    }

    // check min invesment
    if (weiAmount < phase.stage.minAlloc) {
      revert NotEnoughBigInvestment(weiAmount, phase.stage.minAlloc);
    }

    // check hardcap
    uint256 raised = weiRaised + weiAmount;
    if (raised > hardCap) {
      revert HardCapExceeded(raised, hardCap);
    }

    // calculate token amount to be sold
    uint256 tokenAmount = weiAmount * phase.stage.rate;

    // check supply
    uint256 sold = phase.soldTokens + tokenAmount;
    if (sold > phase.stage.supply) {
      revert StageSupplyDrained(sold, phase.stage.supply);
    }

    // use whitelist
    if (address(whitelist) != address(0x0)) {
      bool success = whitelist.use(weiAmount);
      if (!success) {
        revert WhitelistNotPassed(msg.sender, weiAmount);
      }
    }

    // update state
    weiRaised = raised;
    stages[currentStage].weiRaised += weiAmount;
    stages[currentStage].soldTokens = sold;

    // store profits
    wallet.transfer(weiAmount);

    // send tokens
    erc20.transfer(_beneficiary, tokenAmount);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
  }

  receive() external payable {
    this.buyTokens(msg.sender);
  }

  function stageCount() external view returns (uint256) {
    // frontend view
    return stages.length;
  }

  function rate() external view returns (uint256) {
    // rate from current stage
    return stages[getCurrentStage()].stage.rate;
  }

  function openingTime() external view returns (uint256) {
    // opening time of first stage
    return stages[0].stage.openingTime;
  }

  function closingTime() public view returns (uint256) {
    // closing time of last stage
    return stages[getLastStage()].stage.closingTime;
  }

  function tokensLeft() public view onlyInState(State.CONFIGURED) returns (uint256) {
    // tokens left on sale contract
    return erc20.balanceOf(address(this));
  }

  function getLastStage() internal view returns (uint8) {
    return uint8(stages.length - 1);
  }

  function getCurrentStage() public view returns (uint8) {
    // tx.members
    uint256 timestamp = block.timestamp;

    // return active stage
    for (uint8 i = 0; i < stages.length; i++) {
      if (stages[i].stage.openingTime <= timestamp && timestamp <= stages[i].stage.closingTime) {
        return i;
      }
    }

    // revert if no active stage
    revert SaleNotActive(timestamp);
  }

  function hasClosed() external view returns (bool) {
    // OpenZeppelin standard method
    return block.timestamp > closingTime();
  }

  function finalize() external onlyInState(State.CONFIGURED) onlyWhenFinished {
    // check tokens left
    uint256 tokenAmount = tokensLeft();

    // revert if no tokens left
    if (tokenAmount == 0) {
      revert NoTokensLeft();
    }

    // burn remaining tokens
    erc20.burn(tokenAmount);
    emit TokenBurn(tokenAmount);
  }
}