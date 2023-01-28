pragma solidity ^0.5.16;

import "./openzeppelin/SafeMath.sol";
import "./openzeppelin/SafeERC20.sol";
import "./interfaces/IETF.sol";
import "./interfaces/IPoolEscrow.sol";
import "./interfaces/ITaxManagerOld.sol";

interface IUniswapV2Pair {
  function sync() external;
}

contract BasicRebaser {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Updated(uint256 snp, uint256 etf);
  event NoUpdateSNP();
  event NoUpdateETF();
  event NoRebaseNeeded();
  event StillCold();
  event NotInitialized();

  uint256 public constant BASE = 1e18;
  uint256 public constant WINDOW_SIZE = 24;

  address public etf;
  uint256[] public pricesSNP = new uint256[](WINDOW_SIZE);
  uint256[] public pricesETF = new uint256[](WINDOW_SIZE);
  uint256 public pendingSNPPrice = 0;
  uint256 public pendingETFPrice = 0;
  bool public noPending = true;
  uint256 public averageSNP;
  uint256 public averageETF;
  uint256 public lastUpdate;
  uint256 public frequency = 1 hours;
  uint256 public counter = 0;
  uint256 public epoch = 1;
  uint256 public positiveEpochCount = 0;
  uint256 public positiveRebaseLimit = 700; // 7.0% by default
  uint256 public negativeRebaseLimit = 200; // 2.0% by default
  uint256 public constant basisBase = 10000; // 100%
  ITaxManager public taxManager;
  mapping (uint256 => uint256) public rebaseBlockNumber;
  mapping (uint256 => uint256) public rebaseDelta;
  address public secondaryPool;
  address public governance;

  uint256 public nextRebase = 0;
  uint256 public constant REBASE_DELAY = WINDOW_SIZE * 1 hours;
  IUniswapV2Pair public uniswapSyncer;

  modifier onlyGov() {
    require(msg.sender == governance, "only gov");
    _;
  }

  constructor (address token, address _secondaryPool, address _taxManager) public {
    etf = token;
    secondaryPool = _secondaryPool;
    taxManager = ITaxManager(_taxManager);
    governance = msg.sender;
  }

  function setPair(address _uniswapPair) public onlyGov {
    uniswapSyncer = IUniswapV2Pair(_uniswapPair);
  }

  function getPositiveEpochCount() public view returns (uint256) {
    return positiveEpochCount;
  }

  function getBlockForPositiveEpoch(uint256 _epoch) public view returns (uint256) {
    return rebaseBlockNumber[_epoch];
  }

  function getDeltaForPositiveEpoch(uint256 _epoch) public view returns (uint256) {
    return rebaseDelta[_epoch];
  }

  function setNextRebase(uint256 next) external onlyGov {
    require(nextRebase == 0, "Only one time activation");
    nextRebase = next;
  }

  function setGovernance(address account) external onlyGov {
    governance = account;
  }

  function setSecondaryPool(address pool) external onlyGov {
    secondaryPool = pool;
  }

  function setRebaseLimit(uint256 _limit, bool positive) external onlyGov {
    require(_limit <= 2500); // 0% to 25%
      if(positive)
        positiveRebaseLimit = _limit;
      else
        negativeRebaseLimit = _limit;
  }

  function setTaxManager(address _taxManager) external onlyGov {
    taxManager = ITaxManager(_taxManager);
  }

  function checkRebase() external {
    // etf ensures that we do not have smart contracts rebasing
    require (msg.sender == address(etf), "only through etf");
    rebase();
    recordPrice();
  }

  function recordPrice() public {
    if (msg.sender != tx.origin && msg.sender != address(etf)) {
      // smart contracts could manipulate data via flashloans,
      // thus we forbid them from updating the price
      return;
    }

    if (block.timestamp < lastUpdate + frequency) {
      // addition is running on timestamps, this will never overflow
      // we leave at least the specified period between two updates
      return;
    }

    (bool successSNP, uint256 priceSNP) = getPriceSNP();
    (bool successETF, uint256 priceETF) = getPriceETF();
    if (!successETF) {
      // price of ETF was not returned properly
      emit NoUpdateETF();
      return;
    }
    if (!successSNP) {
      // price of SNP was not returned properly
      emit NoUpdateSNP();
      return;
    }
    lastUpdate = block.timestamp;

    if (noPending) {
      // we start recording with 1 hour delay
      pendingSNPPrice = priceSNP;
      pendingETFPrice = priceETF;
      noPending = false;
    } else if (counter < WINDOW_SIZE) {
      // still in the warming up phase
      averageSNP = averageSNP.mul(counter).add(pendingSNPPrice).div(counter.add(1));
      averageETF = averageETF.mul(counter).add(pendingETFPrice).div(counter.add(1));
      pricesSNP[counter] = pendingSNPPrice;
      pricesETF[counter] = pendingETFPrice;
      pendingSNPPrice = priceSNP;
      pendingETFPrice = priceETF;
      counter++;
    } else {
      uint256 index = counter % WINDOW_SIZE;
      averageSNP = averageSNP.mul(WINDOW_SIZE).sub(pricesSNP[index]).add(pendingSNPPrice).div(WINDOW_SIZE);
      averageETF = averageETF.mul(WINDOW_SIZE).sub(pricesETF[index]).add(pendingETFPrice).div(WINDOW_SIZE);
      pricesSNP[index] = pendingSNPPrice;
      pricesETF[index] = pendingETFPrice;
      pendingSNPPrice = priceSNP;
      pendingETFPrice = priceETF;
      counter++;
    }
    emit Updated(pendingSNPPrice, pendingETFPrice);
  }

    function immediateRecordPrice() public onlyGov {

    (bool successSNP, uint256 priceSNP) = getPriceSNP();
    (bool successETF, uint256 priceETF) = getPriceETF();
    if (!successETF) {
      // price of ETF was not returned properly
      emit NoUpdateETF();
      return;
    }
    if (!successSNP) {
      // price of SNP was not returned properly
      emit NoUpdateSNP();
      return;
    }
    lastUpdate = block.timestamp;

    if (noPending) {
      // we start recording with 1 hour delay
      pendingSNPPrice = priceSNP;
      pendingETFPrice = priceETF;
      noPending = false;
    } else if (counter < WINDOW_SIZE) {
      // still in the warming up phase
      averageSNP = averageSNP.mul(counter).add(pendingSNPPrice).div(counter.add(1));
      averageETF = averageETF.mul(counter).add(pendingETFPrice).div(counter.add(1));
      pricesSNP[counter] = pendingSNPPrice;
      pricesETF[counter] = pendingETFPrice;
      pendingSNPPrice = priceSNP;
      pendingETFPrice = priceETF;
      counter++;
    } else {
      uint256 index = counter % WINDOW_SIZE;
      averageSNP = averageSNP.mul(WINDOW_SIZE).sub(pricesSNP[index]).add(pendingSNPPrice).div(WINDOW_SIZE);
      averageETF = averageETF.mul(WINDOW_SIZE).sub(pricesETF[index]).add(pendingETFPrice).div(WINDOW_SIZE);
      pricesSNP[index] = pendingSNPPrice;
      pricesETF[index] = pendingETFPrice;
      pendingSNPPrice = priceSNP;
      pendingETFPrice = priceETF;
      counter++;
    }
    emit Updated(pendingSNPPrice, pendingETFPrice);
  }

  function rebase() public {
    // make public rebasing only after initialization
    if (nextRebase == 0 && msg.sender != governance) {
      emit NotInitialized();
      return;
    }
    if (counter <= WINDOW_SIZE && msg.sender != governance) {
      emit StillCold();
      return;
    }
    // We want to rebase only at 12:00 UTC and 24 hours later
    if (block.timestamp < nextRebase) {
      return;
    } else {
      nextRebase = nextRebase + REBASE_DELAY;
    }

    // only rebase if there is a 5% difference between the price of SNP and ETF
    uint256 highThreshold = averageSNP.mul(105).div(100);
    uint256 lowThreshold = averageSNP.mul(95).div(100);

    if (averageETF > highThreshold) {
      // ETF is too expensive, this is a positive rebase increasing the supply
      uint256 factor = BASE.sub(BASE.mul(averageETF.sub(averageSNP)).div(averageETF.mul(10)));
      uint256 increase = BASE.sub(factor);
      uint256 realAdjustment = increase.mul(BASE).div(factor);
      uint256 currentSupply = IERC20(etf).totalSupply();
      uint256 desiredSupply = currentSupply.add(currentSupply.mul(realAdjustment).div(BASE));
      uint256 upperLimit = currentSupply.mul(basisBase.add(positiveRebaseLimit)).div(basisBase);
      if(desiredSupply > upperLimit) // Increase expected rebase is above the limit
        desiredSupply = upperLimit;
      uint256 preTaxDelta = desiredSupply.mul(BASE).div(currentSupply).sub(BASE);
      positiveEpochCount++;
      rebaseBlockNumber[positiveEpochCount] = block.number;
      uint256 perpetualPoolTax = taxManager.getPerpetualPoolTaxRate();
      uint256 totalTax = taxManager.getTotalTaxAtMint();
      uint256 taxDivisor = taxManager.getTaxBaseDivisor();
      uint256 secondaryPoolBudget = desiredSupply.sub(currentSupply).mul(perpetualPoolTax).div(taxDivisor); // 4.5% to perpetual pool/escrow
      uint256 totalRewardBudget = desiredSupply.sub(currentSupply).mul(totalTax).div(taxDivisor); // This amount of token will get minted when rewards are claimed and distributed via perpetual pool
      desiredSupply = desiredSupply.sub(totalRewardBudget);

      // Cannot underflow as desiredSupply > currentSupply, the result is positive
      // delta = (desiredSupply / currentSupply) * 100 - 100
      uint256 delta = desiredSupply.mul(BASE).div(currentSupply).sub(BASE);
      uint256 deltaDifference = preTaxDelta.sub(delta); // Percentage of delta reduced due to tax
      rebaseDelta[positiveEpochCount] = deltaDifference; // Record pre-tax delta differemce, this is the amount of token in percent that needs to be minted for tax
      IETF(etf).rebase(epoch, delta, true);

      if (secondaryPool != address(0)) {
        // notify the pool escrow that tokens are available
        IETF(etf).mint(address(this), secondaryPoolBudget);
        IERC20(etf).safeApprove(secondaryPool, 0);
        IERC20(etf).safeApprove(secondaryPool, secondaryPoolBudget);
        IPoolEscrow(secondaryPool).notifySecondaryTokens(secondaryPoolBudget);
      } else {
        // Incase perpetual pool address was not set
        address perpetualPool = taxManager.getPerpetualPool();
        IETF(etf).mint(perpetualPool, secondaryPoolBudget);
      }
      uniswapSyncer.sync();
      epoch++;

    } else if (averageETF < lowThreshold) {
      // ETF is too cheap, this is a negative rebase decreasing the supply
      uint256 factor = BASE.add(BASE.mul(averageSNP.sub(averageETF)).div(averageETF.mul(10)));
      uint256 increase = factor.sub(BASE);
      uint256 realAdjustment = increase.mul(BASE).div(factor);
      uint256 currentSupply = IERC20(etf).totalSupply();
      uint256 desiredSupply = currentSupply.sub(currentSupply.mul(realAdjustment).div(BASE));
      uint256 lowerLimit = currentSupply.mul(basisBase.sub(negativeRebaseLimit)).div(basisBase);
      if(desiredSupply < lowerLimit) // Decrease expected rebase is below the limit
        desiredSupply = lowerLimit;
      // Cannot overflow as desiredSupply < currentSupply
      // delta = 100 - (desiredSupply / currentSupply) * 100
      uint256 delta = uint256(BASE).sub(desiredSupply.mul(BASE).div(currentSupply));
      IETF(etf).rebase(epoch, delta, false);
      uniswapSyncer.sync();
      epoch++;
    } else {
      // else the price is within bounds
      emit NoRebaseNeeded();
    }
  }

  /**
  * Calculates how a rebase would look if it was triggered now.
  */
  function calculateRealTimeRebasePreTax() public view returns (uint256, uint256) {
    // only rebase if there is a 5% difference between the price of SNP and ETF
    uint256 highThreshold = averageSNP.mul(105).div(100);
    uint256 lowThreshold = averageSNP.mul(95).div(100);

    if (averageETF > highThreshold) {
      // ETF is too expensive, this is a positive rebase increasing the supply
      uint256 factor = BASE.sub(BASE.mul(averageETF.sub(averageSNP)).div(averageETF.mul(10)));
      uint256 increase = BASE.sub(factor);
      uint256 realAdjustment = increase.mul(BASE).div(factor);
      uint256 currentSupply = IERC20(etf).totalSupply();
      uint256 desiredSupply = currentSupply.add(currentSupply.mul(realAdjustment).div(BASE));
      uint256 upperLimit = currentSupply.mul(basisBase.add(positiveRebaseLimit)).div(basisBase);
      if(desiredSupply > upperLimit) // Increase expected rebase is above the limit
        desiredSupply = upperLimit;
      uint256 perpetualPoolTax = taxManager.getPerpetualPoolTaxRate();
      uint256 totalTax = taxManager.getTotalTaxAtMint();
      uint256 taxDivisor = taxManager.getTaxBaseDivisor();
      uint256 secondaryPoolBudget = desiredSupply.sub(currentSupply).mul(perpetualPoolTax).div(taxDivisor); // 4.5% to perpetual pool/escrow
      uint256 totalRewardBudget = desiredSupply.sub(currentSupply).mul(totalTax).div(taxDivisor); // This amount of token will get minted when rewards are claimed and distributed via perpetual pool
      desiredSupply = desiredSupply.sub(totalRewardBudget);

      // Cannot underflow as desiredSupply > currentSupply, the result is positive
      // delta = (desiredSupply / currentSupply) * 100 - 100
      uint256 delta = desiredSupply.mul(BASE).div(currentSupply).sub(BASE);
      return (delta, secondaryPool == address(0) ? 0 : secondaryPoolBudget);
    } else if (averageETF < lowThreshold) {
      // ETF is too cheap, this is a negative rebase decreasing the supply
      uint256 factor = BASE.add(BASE.mul(averageSNP.sub(averageETF)).div(averageETF.mul(10)));
      uint256 increase = factor.sub(BASE);
      uint256 realAdjustment = increase.mul(BASE).div(factor);
      uint256 currentSupply = IERC20(etf).totalSupply();
      uint256 desiredSupply = currentSupply.sub(currentSupply.mul(realAdjustment).div(BASE));
      uint256 lowerLimit = currentSupply.mul(basisBase.sub(negativeRebaseLimit)).div(basisBase);
      if(desiredSupply < lowerLimit) // Decrease expected rebase is below the limit
        desiredSupply = lowerLimit;
      // Cannot overflow as desiredSupply < currentSupply
      // delta = 100 - (desiredSupply / currentSupply) * 100
      uint256 delta = uint256(BASE).sub(desiredSupply.mul(BASE).div(currentSupply));
      return (delta, 0);
    } else {
      return (0,0);
    }
  }
  function recoverTokens(
    address _token,
    address benefactor
  ) public onlyGov {
    uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(benefactor, tokenBalance);
  }

  function getPriceSNP() public view returns (bool, uint256);
  function getPriceETF() public view returns (bool, uint256);
}