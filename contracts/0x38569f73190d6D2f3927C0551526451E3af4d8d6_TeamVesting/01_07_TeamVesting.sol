// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract TeamVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // DPX Token
  IERC20 public dpx;

  // Structure of each vest
  struct Vest {
    uint256 amount; // the amount of DPX the beneficiary will recieve
    uint256 released; // the amount of DPX released to the beneficiary
    uint256 initialReleaseAmount; // the amount of DPX released to the beneficiary at the start of the vesting period
    bool terminated; // whether the vesting has been terminated
  }

  // The mapping of vested beneficiary (beneficiary address => Vest)
  mapping(address => Vest) public vestedBeneficiaries;

  // No. of beneficiaries
  uint256 public noOfBeneficiaries;

  // Whether the contract has been bootstrapped with the DPX
  bool public bootstrapped;

  // Start time of the the vesting
  uint256 public startTime;

  // The duration of the vesting
  uint256 public duration;

  // Total amount of DPX required to fulfil the vesting of beneficiaries
  uint256 public totalDpxRequired;

  // Total released DPX
  uint256 public totalDpxReleased;

  constructor() {
    addBeneficiary(
      0x60aD50E7D5dBb92da6E01f933a4f913e4D9A4535,
      uint256(46500).mul(1e18),
      uint256(9300).mul(1e18)
    );

    addBeneficiary(
      0x47B456269E9AD24e12643c09A5d602748dE1d26D,
      uint256(9500).mul(1e18),
      uint256(1900).mul(1e18)
    );

    addBeneficiary(
      0x2fEcFb2ebE995C9Dea38A6235c807A58Ede7FE7f,
      uint256(1000).mul(1e18),
      uint256(100).mul(1e18)
    );

    addBeneficiary(
      0x41c7b26Ad4873930Aa0362a23Cdf06F7769288Bf,
      uint256(1000).mul(1e18),
      uint256(100).mul(1e18)
    );

    addBeneficiary(
      0xc6f6c2a05A12Ef54533069778853A16FC7fc07E5,
      uint256(1000).mul(1e18),
      uint256(100).mul(1e18)
    );

    addBeneficiary(
      0xE73dc9aC321461E4e2A970eECF3b0C5845c93Cd1,
      uint256(500).mul(1e18),
      uint256(50).mul(1e18)
    );

    addBeneficiary(
      0xC0a717EbCd88e013b9bB8cECF060d5191296f61f,
      uint256(500).mul(1e18),
      uint256(50).mul(1e18)
    );
  }

  /*---- EXTERNAL FUNCTIONS FOR OWNER ----*/

  /**
   * @notice Bootstraps the contract
   * @param _startTime the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _dpxAddress address of dpx erc20 token
   */
  function bootstrap(
    uint256 _startTime,
    uint256 _duration,
    address _dpxAddress
  ) external onlyOwner returns (bool) {
    require(_dpxAddress != address(0), 'DPX address is 0');
    require(_duration > 0, 'Duration passed cannot be 0');
    require(_startTime > block.timestamp, 'Start time cannot be before current time');

    startTime = _startTime;
    duration = _duration;
    dpx = IERC20(_dpxAddress);

    require(totalDpxRequired > 0, 'Total DPX required cannot be 0');

    dpx.safeTransferFrom(msg.sender, address(this), totalDpxRequired);

    bootstrapped = true;

    emit Bootstrap(totalDpxRequired);

    return bootstrapped;
  }

  /**
   * @notice Adds a beneficiary to the contract. Only owner can call this.
   * @param _beneficiary the address of the beneficiary
   * @param _amount amount of DPX to be vested for the beneficiary
   * @param _initialReleaseAmount amount of DPX released to the beneficiary at the start of the vesting period
   */
  function addBeneficiary(
    address _beneficiary,
    uint256 _amount,
    uint256 _initialReleaseAmount
  ) public onlyOwner returns (bool) {
    require(_beneficiary != address(0), 'Beneficiary cannot be a 0 address');
    require(_amount > 0, 'Amount should be larger than 0');
    require(_amount > _initialReleaseAmount, 'Amount should be larger than initial release amount');
    require(!bootstrapped, 'Cannot add beneficiary as contract has been bootstrapped');
    require(vestedBeneficiaries[_beneficiary].amount == 0, 'Cannot add the same beneficiary again');

    vestedBeneficiaries[_beneficiary].amount = _amount;
    vestedBeneficiaries[_beneficiary].initialReleaseAmount = _initialReleaseAmount;

    totalDpxRequired = totalDpxRequired.add(_amount);

    noOfBeneficiaries = noOfBeneficiaries.add(1);

    emit AddBeneficiary(_beneficiary, _amount, _initialReleaseAmount);

    return true;
  }

  /**
   * @notice Updates beneficiary amount. Only owner can call this.
   * @param _beneficiary the address of the beneficiary
   * @param _amount amount of DPX to be vested for the beneficiary
   * @param _initialReleaseAmount amount of DPX released to the beneficiary at the start of the vesting period
   */
  function updateBeneficiary(
    address _beneficiary,
    uint256 _amount,
    uint256 _initialReleaseAmount
  ) external onlyOwner {
    require(_beneficiary != address(0), 'Beneficiary cannot be a 0 address');
    require(!bootstrapped, 'Cannot update beneficiary as contract has been bootstrapped');
    require(
      vestedBeneficiaries[_beneficiary].amount != _amount ||
        vestedBeneficiaries[_beneficiary].initialReleaseAmount != _initialReleaseAmount,
      'New amount or new initialReleaseAmount should be different from the older'
    );
    require(_amount > 0, 'Amount cannot be smaller or equal to 0');
    require(_amount > _initialReleaseAmount, 'Amount should be larger than initial release amount');
    require(vestedBeneficiaries[_beneficiary].amount != 0, 'Beneficiary has not been added');

    totalDpxRequired = totalDpxRequired.sub(vestedBeneficiaries[_beneficiary].amount).add(_amount);

    vestedBeneficiaries[_beneficiary].amount = _amount;
    vestedBeneficiaries[_beneficiary].initialReleaseAmount = _initialReleaseAmount;

    emit UpdateBeneficiary(_beneficiary, _amount, _initialReleaseAmount);
  }

  /**
   * @notice Removes a beneficiary from the contract. Only owner can call this.
   * @param _beneficiary the address of the beneficiary
   * @return whether beneficiary was deleted
   */
  function removeBeneficiary(address _beneficiary) external onlyOwner returns (bool) {
    require(_beneficiary != address(0), 'Beneficiary cannot be a 0 address');
    require(!bootstrapped, 'Cannot remove beneficiary as contract has been bootstrapped');
    require(
      vestedBeneficiaries[_beneficiary].amount != 0,
      'Cannot remove a beneficiary that has not been added'
    );

    totalDpxRequired = totalDpxRequired.sub(vestedBeneficiaries[_beneficiary].amount);

    vestedBeneficiaries[_beneficiary].amount = 0;

    noOfBeneficiaries = noOfBeneficiaries.sub(1);

    emit RemoveBeneficiary(_beneficiary);

    return true;
  }

  /**
   * @notice Terminates a beneficiary from the contract hence ending their vesting. Only owner can call this.
   * @dev This allows for the remaining of DPX to be withdrawn by the owner that would be otherwise
   * released to the concernced beneficiary
   * @param _beneficiary the address of the beneficiary
   * @return whether beneficiary was terminated
   */
  function terminateBeneficiary(address _beneficiary) external onlyOwner returns (bool) {
    require(_beneficiary != address(0), 'Beneficiary cannot be a 0 address');

    if (releasableAmount(_beneficiary) > 0) {
      release(_beneficiary);
    }

    vestedBeneficiaries[_beneficiary].terminated = true;

    totalDpxRequired = totalDpxRequired.add(vestedBeneficiaries[_beneficiary].released).sub(
      vestedBeneficiaries[_beneficiary].amount
    );

    emit TerminateBeneficiary(_beneficiary, 0);

    return true;
  }

  /**
   * @notice Withdraws terminated beneficiary's DPX deposited into the contract. Only owner can call this.
   */
  function withdrawTerminatedDpx() external onlyOwner {
    require(bootstrapped, 'Contract has not been bootstrapped');

    uint256 withdrawableAmount = dpx.balanceOf(address(this)).sub(
      totalDpxRequired.sub(totalDpxReleased)
    );

    require(withdrawableAmount > 0, 'Cannot withdraw 0 DPX');

    dpx.safeTransfer(msg.sender, withdrawableAmount);

    emit WithdrawTerminatedDpx(withdrawableAmount);
  }

  /*---- EXTERNAL/PUBLIC FUNCTIONS ----*/

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param beneficiary the beneficiary to release the DPX too
   */
  function release(address beneficiary) public returns (uint256 unreleased) {
    require(bootstrapped, 'Contract has not been bootstrapped');
    require(!vestedBeneficiaries[beneficiary].terminated, 'Beneficiary must not be terminated');

    unreleased = releasableAmount(beneficiary);

    require(unreleased > 0, 'No releasable amount');

    vestedBeneficiaries[beneficiary].released = vestedBeneficiaries[beneficiary].released.add(
      unreleased
    );

    totalDpxReleased = totalDpxReleased.add(unreleased);

    dpx.safeTransfer(beneficiary, unreleased);

    emit TokensReleased(beneficiary, unreleased);
  }

  /*---- VIEWS ----*/

  /**
   * @notice Calculates the amount that has already vested but hasn't been released yet.
   * @param beneficiary address of the beneficiary
   */
  function releasableAmount(address beneficiary) public view returns (uint256) {
    return vestedAmount(beneficiary).sub(vestedBeneficiaries[beneficiary].released);
  }

  /**
   * @notice Calculates the amount that has already vested.
   * @param beneficiary address of the beneficiary
   */
  function vestedAmount(address beneficiary) public view returns (uint256) {
    uint256 totalBalance = vestedBeneficiaries[beneficiary].amount;

    if (block.timestamp < startTime) {
      return 0;
    } else if (block.timestamp >= startTime.add(duration)) {
      return totalBalance;
    } else {
      uint256 balanceAmount = totalBalance.sub(
        vestedBeneficiaries[beneficiary].initialReleaseAmount
      );
      return
        balanceAmount.mul(block.timestamp.sub(startTime)).div(duration).add(
          vestedBeneficiaries[beneficiary].initialReleaseAmount
        );
    }
  }

  /*---- EVENTS ----*/

  event TokensReleased(address beneficiary, uint256 amount);

  event AddBeneficiary(address beneficiary, uint256 amount, uint256 initialReleaseAmount);

  event RemoveBeneficiary(address beneficiary);

  event TerminateBeneficiary(address beneficiary, uint256 remainingAmount);

  event UpdateBeneficiary(address beneficiary, uint256 amount, uint256 initialReleaseAmount);

  event WithdrawTerminatedDpx(uint256 amount);

  event Bootstrap(uint256 totalDpxRequired);
}