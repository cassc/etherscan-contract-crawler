// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
  This contract is one of 3 vesting contracts for the JustCarbon Foundation

  Here, we cover the case of >= 1 beneficiaries in receipt of a single set of funds.
  Each beneficiary has funds made available on a periodic basis, and can withdraw any time.

  @author jordaniza ([email protected])
 */

contract MultipleVesting is Ownable, ReentrancyGuard {
    /**
        @dev Covers all details about the address' vesting schedule
    */
    struct Beneficiary {
        // token value transferred to the account at start date
        uint256 initialTransfer;
        // total value already withdrawn by the account
        uint256 withdrawn;
        // The total number of tokens that can be transferred to the beneficiary
        uint256 total;
        // used for checking whitelisted accounts in method guards
        bool exists;
    }
    /* ==== Constants and immutables ==== */

    // the JCG token
    IERC20 private immutable token;

    // the number of seconds in a vesting period
    uint256 public immutable periodLength;

    // when the vesting period starts for all beneficiaries
    uint256 public immutable startTimestamp;

    // when the vesting period ends for all beneficiaries
    uint256 public immutable endTimestamp;

    /* ==== Mutable variables ==== */

    // amount currently withdrawn from the contract
    uint256 public contractWithdrawn = 0;

    // amount of tokens currently available across all beneficiaries
    uint256 public contractBalance = 0;

    // As more beneficiaries are added, the amount outstanding needs to be incremented
    uint256 public contractOwedTotal = 0;

    // full details of each beneficiary
    mapping(address => Beneficiary) public beneficiaryDetails;

    // Lifecycle flag to prevent adding beneficiaries after tokens have been deposited
    bool public tokensDeposited = false;

    // Lifecycle method to prevent withdraw calls after the emergency withdraw called
    bool public closed = false;

    /* ===== Events ===== */
    event AddBeneficiary(address beneficiary);
    event DepositTokens(uint256 qty);
    event WithdrawSuccess(address beneficiary, uint256 qty);
    event WithdrawFail(address beneficiary);
    event EmergencyWithdraw();

    /* ===== Constructor ===== */
    constructor(
        address _tokenAddress,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _periodLength
    ) {
        require(_periodLength > 0, "Period length invalid");
        require(
            (_startTimestamp >= block.timestamp) &&
                (_endTimestamp >= block.timestamp),
            "Cannot pass a timestamp in the past"
        );
        require(_startTimestamp < _endTimestamp, "Start is after end");
        periodLength = _periodLength;
        token = IERC20(_tokenAddress);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    /* ===== Modifiers ==== */
    modifier beforeDeposit() {
        require(!tokensDeposited, "Cannot call after deposit");
        _;
    }

    modifier afterDeposit() {
        require(tokensDeposited, "Cannot call before deposited");
        _;
    }

    modifier notClosed() {
        require(!closed, "Contract closed");
        _;
    }

    /* ===== Getters ===== */

    /**
      @dev public getter to access the balance of an address using an address
      @param _beneficiaryAddress the address to check - will revert if not a valid address
      @return the total amount vested for the provided address, minus withdrawals
     */
    function calculateAvailable(address _beneficiaryAddress)
        public
        view
        returns (uint256)
    {
        Beneficiary storage beneficiary = beneficiaryDetails[
            _beneficiaryAddress
        ];
        return _calculateAvailable(beneficiary);
    }

    /**
      @dev private method that accepts the beneficiary struct to avoid multiple SLOAD operations
      @param beneficiary the address to check - will revert if not a valid address
      @return the total amount vested for the provided address, minus withdrawals
    */
    function _calculateAvailable(Beneficiary memory beneficiary)
        private
        view
        notClosed
        returns (uint256)
    {
        require(beneficiary.exists, "Beneficiary does not exist");
        if (block.timestamp >= endTimestamp) {
            return beneficiary.total - beneficiary.withdrawn;
        }
        uint256 initialTransfer = beneficiary.initialTransfer;

        // allow a claim of the initial quantities before the vesting period starts
        if (block.timestamp < startTimestamp) {
            return initialTransfer - beneficiary.withdrawn;
        }

        uint256 elapsedSeconds = block.timestamp - startTimestamp;
        uint256 elapsedWholePeriods = elapsedSeconds / periodLength;
        // convert only whole periods to seconds for vesting (no partial vesting)
        uint256 vestingSeconds = elapsedWholePeriods * periodLength;
        uint256 quantityToBeVested = beneficiary.total - initialTransfer;
        uint256 vestingDuration = (endTimestamp - startTimestamp);
        uint256 totalVestedOverTime = (quantityToBeVested * vestingSeconds) /
            vestingDuration;
        uint256 totalVested = initialTransfer + totalVestedOverTime;
        return totalVested - beneficiary.withdrawn;
    }

    /* ===== State changing functions ===== */

    /**
      @dev Adds a new beneficiary to the whitelisted accounts.
      This whitelists the account to be able to access the withdraw function
      Also adds to the running total of how much is required to be deposited
     */
    function addBeneficiary(
        address _beneficiary,
        uint256 _initialTransfer,
        uint256 _total
    ) public onlyOwner beforeDeposit returns (bool) {
        require(
            _initialTransfer <= _total,
            "Initial transfer quantity exceeds the total value"
        );
        require(
            !beneficiaryDetails[_beneficiary].exists,
            "Beneficiary already exists"
        );
        // Add the amount owed to each beneficiary to the total for the contract
        contractOwedTotal += _total;

        beneficiaryDetails[_beneficiary] = Beneficiary({
            initialTransfer: _initialTransfer,
            withdrawn: 0,
            total: _total,
            exists: true
        });

        emit AddBeneficiary(_beneficiary);
        return true;
    }

    /**
      @dev Adds multiple beneficiaries in a single loop
      OOG risks mean we can't rely on this function, but it's useful as 
      an option to reduce gas costs
     */
    function addBeneficiaries(
        address[] memory _beneficiaryList,
        uint256[] memory _initialTransferList,
        uint256[] memory _totalList
    ) public virtual onlyOwner beforeDeposit returns (bool) {
        require(
            _beneficiaryList.length == _initialTransferList.length &&
                _initialTransferList.length == _totalList.length,
            "Arrays not the same length"
        );

        for (uint256 i; i < _beneficiaryList.length; i++) {
            addBeneficiary(
                _beneficiaryList[i],
                _initialTransferList[i],
                _totalList[i]
            );
        }
        return true;
    }

    /**
      @dev Deposit tokens into the contract, that can then be withdrawn by the beneficiaries
     */
    function deposit(uint256 amount)
        public
        onlyOwner
        beforeDeposit
        returns (bool)
    {
        require(amount > 0, "Invalid amount");
        require(
            amount == contractOwedTotal,
            "Amount deposited is not equal to the amount outstanding"
        );

        contractBalance += amount;
        tokensDeposited = true;

        require(token.transferFrom(msg.sender, address(this), amount));
        emit DepositTokens(amount);
        return true;
    }

    /**
      @dev Transfer all tokens currently vested (for a given account) to the whitelisted account.  
     */
    function withdraw()
        public
        afterDeposit
        notClosed
        nonReentrant
        returns (bool)
    {
        address sender = msg.sender;
        Beneficiary storage beneficiary = beneficiaryDetails[sender];
        require(beneficiary.exists, "Only beneficiaries");

        uint256 amount = _calculateAvailable(beneficiary);

        require(amount > 0, "Nothing to withdraw");
        // prevent locked tokens due to rounding errors
        if (amount > contractBalance) {
            amount = contractBalance;
        }

        beneficiary.withdrawn += amount;
        contractWithdrawn += amount;
        contractBalance -= amount;

        require(token.transfer(sender, amount));
        emit WithdrawSuccess(sender, amount);
        return true;
    }

    /**
      @dev Withdraw the full token balance of the contract to a fallback account
      Used in the case of a discovered vulnerability.
      @return success
     */
    function emergencyWithdraw() public onlyOwner returns (bool) {
        require(contractBalance > 0, "No funds to withdraw");
        contractWithdrawn += contractBalance;
        contractBalance = 0;
        closed = true;

        require(token.transfer(msg.sender, token.balanceOf(address(this))));
        emit EmergencyWithdraw();

        return true;
    }
}