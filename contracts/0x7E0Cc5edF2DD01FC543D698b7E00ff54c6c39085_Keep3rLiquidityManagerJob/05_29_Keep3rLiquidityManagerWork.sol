// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './Keep3rLiquidityManagerEscrowsHandler.sol';
import './Keep3rLiquidityManagerJobHandler.sol';
import './Keep3rLiquidityManagerJobsLiquidityHandler.sol';
import './Keep3rLiquidityManagerParameters.sol';
import './Keep3rLiquidityManagerUserJobsLiquidityHandler.sol';
import './Keep3rLiquidityManagerUserLiquidityHandler.sol';

interface IKeep3rLiquidityManagerWork {
  enum Actions { None, AddLiquidityToJob, ApplyCreditToJob, UnbondLiquidityFromJob, RemoveLiquidityFromJob }
  enum Steps { NotStarted, LiquidityAdded, CreditApplied, UnbondingLiquidity }

  // Actions by Keeper
  event Worked(address indexed _job);
  // Actions forced by governor
  event ForceWorked(address indexed _job);

  function getNextAction(address _job) external view returns (address _escrow, Actions _action);

  function workable(address _job) external view returns (bool);

  function jobEscrowStep(address _job, address _escrow) external view returns (Steps _step);

  function jobEscrowTimestamp(address _job, address _escrow) external view returns (uint256 _timestamp);

  function work(address _job) external;

  function forceWork(address _job) external;
}

abstract contract Keep3rLiquidityManagerWork is Keep3rLiquidityManagerUserJobsLiquidityHandler, IKeep3rLiquidityManagerWork {
  // job => escrow => Steps
  mapping(address => mapping(address => Steps)) public override jobEscrowStep;
  // job => escrow => timestamp
  mapping(address => mapping(address => uint256)) public override jobEscrowTimestamp;

  // Since all liquidity behaves the same, we just need to check one of them
  function getNextAction(address _job) public view override returns (address _escrow, Actions _action) {
    require(_jobLiquidities[_job].length() > 0, 'Keep3rLiquidityManager::getNextAction:job-has-no-liquidity');

    Steps _escrow1Step = jobEscrowStep[_job][escrow1];
    Steps _escrow2Step = jobEscrowStep[_job][escrow2];

    // Init (add liquidity to escrow1)
    if (_escrow1Step == Steps.NotStarted && _escrow2Step == Steps.NotStarted) {
      return (escrow1, Actions.AddLiquidityToJob);
    }

    // Init (add liquidity to NotStarted escrow)
    if ((_escrow1Step == Steps.NotStarted || _escrow2Step == Steps.NotStarted) && _jobHasDesiredLiquidities(_job)) {
      _escrow = _escrow1Step == Steps.NotStarted ? escrow1 : escrow2;
      address _otherEscrow = _escrow == escrow1 ? escrow2 : escrow1;

      // on _otherEscrow step CreditApplied
      if (jobEscrowStep[_job][_otherEscrow] == Steps.CreditApplied) {
        // make sure to wait 14 days
        if (block.timestamp > jobEscrowTimestamp[_job][_otherEscrow].add(14 days)) {
          // add liquidity to NotStarted _escrow
          return (_escrow, Actions.AddLiquidityToJob);
        }
      }

      // on _otherEscrow step UnbondingLiquidity add liquidity
      if (jobEscrowStep[_job][_otherEscrow] == Steps.UnbondingLiquidity) {
        // add liquidity to NotStarted _escrow
        return (_escrow, Actions.AddLiquidityToJob);
      }
    }

    // can return None, ApplyCreditToJob and RemoveLiquidityFromJob.
    _action = _getNextActionOnStep(escrow1, _escrow1Step, _escrow2Step, _job);
    if (_action != Actions.None) return (escrow1, _action);

    // if escrow1 next actions is None we need to check escrow2

    _action = _getNextActionOnStep(escrow2, _escrow2Step, _escrow1Step, _job);
    if (_action != Actions.None) return (escrow2, _action);

    return (address(0), Actions.None);
  }

  function _jobHasDesiredLiquidities(address _job) internal view returns (bool) {
    // search for desired liquidity > 0 on all job liquidities
    for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
      if (jobLiquidityDesiredAmount[_job][_jobLiquidities[_job].at(i)] > 0) {
        return true;
      }
    }
    return false;
  }

  function _getNextActionOnStep(
    address _escrow,
    Steps _escrowStep,
    Steps _otherEscrowStep,
    address _job
  ) internal view returns (Actions) {
    // after adding liquidity wait 3 days to apply
    if (_escrowStep == Steps.LiquidityAdded) {
      // The escrow with liquidityAmount is the one to call applyCreditToJob, the other should call unbondLiquidityFromJob
      if (block.timestamp > jobEscrowTimestamp[_job][_escrow].add(3 days)) {
        return Actions.ApplyCreditToJob;
      }
      return Actions.None;
    }

    // after applying credits wait 17 days to unbond (only happens when other escrow is on NotStarted [desired liquidity = 0])
    // makes sure otherEscrowStep is still notStarted (it can be liquidityAdded)
    if (_escrowStep == Steps.CreditApplied) {
      if (_otherEscrowStep == Steps.NotStarted && block.timestamp > jobEscrowTimestamp[_job][_escrow].add(17 days)) {
        return Actions.UnbondLiquidityFromJob;
      }
      return Actions.None;
    }

    // after unbonding liquidity wait 14 days to remove
    if (_escrowStep == Steps.UnbondingLiquidity) {
      if (block.timestamp > jobEscrowTimestamp[_job][_escrow].add(14 days)) {
        return Actions.RemoveLiquidityFromJob;
      }
      return Actions.None;
    }

    // for steps: NotStarted. return Actions.None
    return Actions.None;
  }

  function workable(address _job) public view override returns (bool) {
    (, Actions _action) = getNextAction(_job);
    return _workable(_action);
  }

  function _workable(Actions _action) internal pure returns (bool) {
    return (_action != Actions.None);
  }

  function _work(
    address _escrow,
    Actions _action,
    address _job
  ) internal {
    // AddLiquidityToJob
    if (_action == Actions.AddLiquidityToJob) {
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        address _liquidity = _jobLiquidities[_job].at(i);
        uint256 _escrowAmount = jobLiquidityDesiredAmount[_job][_liquidity].div(2);
        IERC20(_liquidity).approve(_escrow, _escrowAmount);
        IKeep3rEscrow(_escrow).deposit(_liquidity, _escrowAmount);
        _addLiquidityToJob(_escrow, _liquidity, _job, _escrowAmount);
        jobEscrowStep[_job][_escrow] = Steps.LiquidityAdded;
        jobEscrowTimestamp[_job][_escrow] = block.timestamp;
      }

      // ApplyCreditToJob (_unbondLiquidityFromJob, _removeLiquidityFromJob, _addLiquidityToJob)
    } else if (_action == Actions.ApplyCreditToJob) {
      address _otherEscrow = _escrow == escrow1 ? escrow2 : escrow1;

      // ALWAYS FIRST: Should try to unbondLiquidityFromJob from _otherEscrow
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        address _liquidity = _jobLiquidities[_job].at(i);
        uint256 _liquidityProvided = IKeep3rV1(keep3rV1).liquidityProvided(_otherEscrow, _liquidity, _job);
        if (_liquidityProvided > 0) {
          _unbondLiquidityFromJob(_otherEscrow, _liquidity, _job, _liquidityProvided);
          jobEscrowStep[_job][_otherEscrow] = Steps.UnbondingLiquidity;
          jobEscrowTimestamp[_job][_otherEscrow] = block.timestamp;
        }
      }
      // Run applyCreditToJob
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        _applyCreditToJob(_escrow, _jobLiquidities[_job].at(i), _job);
        jobEscrowStep[_job][_escrow] = Steps.CreditApplied;
        jobEscrowTimestamp[_job][_escrow] = block.timestamp;
      }

      // UnbondLiquidityFromJob
    } else if (_action == Actions.UnbondLiquidityFromJob) {
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        address _liquidity = _jobLiquidities[_job].at(i);

        uint256 _liquidityProvided = IKeep3rV1(keep3rV1).liquidityProvided(_escrow, _liquidity, _job);
        if (_liquidityProvided > 0) {
          _unbondLiquidityFromJob(_escrow, _liquidity, _job, _liquidityProvided);
          jobEscrowStep[_job][_escrow] = Steps.UnbondingLiquidity;
          jobEscrowTimestamp[_job][_escrow] = block.timestamp;
        }
      }

      // RemoveLiquidityFromJob
    } else if (_action == Actions.RemoveLiquidityFromJob) {
      // Clone _jobLiquidities so we can remove unused without breaking the loop
      address[] memory _jobLiquiditiesClone = new address[](_jobLiquidities[_job].length());
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        _jobLiquiditiesClone[i] = _jobLiquidities[_job].at(i);
      }

      for (uint256 i = 0; i < _jobLiquiditiesClone.length; i++) {
        address _liquidity = _jobLiquiditiesClone[i];
        // remove liquidity
        uint256 _amount = _removeLiquidityFromJob(_escrow, _liquidity, _job);
        jobEscrowStep[_job][_escrow] = Steps.NotStarted;
        jobEscrowTimestamp[_job][_escrow] = block.timestamp;

        // increase jobCycle
        jobCycle[_job] = jobCycle[_job].add(1);

        uint256 _escrowAmount = jobLiquidityDesiredAmount[_job][_liquidity].div(2);
        // check if a withdraw or deposit is needed
        if (_amount > _escrowAmount) {
          IKeep3rEscrow(_escrow).withdraw(_liquidity, _amount.sub(_escrowAmount));
        } else if (_amount < _escrowAmount) {
          IERC20(_liquidity).approve(_escrow, _escrowAmount.sub(_amount));
          IKeep3rEscrow(_escrow).deposit(_liquidity, _escrowAmount.sub(_amount));
        }

        // add liquidity
        if (_escrowAmount > 0) {
          _addLiquidityToJob(_escrow, _liquidity, _job, _escrowAmount);
          jobEscrowStep[_job][_escrow] = Steps.LiquidityAdded;
          jobEscrowTimestamp[_job][_escrow] = block.timestamp;
        }

        uint256 _liquidityInUse =
          IKeep3rEscrow(escrow1).liquidityTotalAmount(_liquidity).add(IKeep3rEscrow(escrow2).liquidityTotalAmount(_liquidity));
        if (_liquidityInUse == 0) _removeLPFromJob(_job, _liquidity);
      }
    }
  }
}