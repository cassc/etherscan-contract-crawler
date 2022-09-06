// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ReduxAirdropVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event InvestorAdded(
        address indexed investor,
        address indexed caller,
        uint256 allocation
    );

    event InvestorRemoved(
        address indexed investor,
        address indexed caller,
        uint256 allocation
    );

    event WithdrawnTokens(address indexed investor, uint256 value);

    event DepositInvestment(address indexed investor, uint256 value);

    event TransferInvestment(address indexed owner, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    uint256 private totalAllocatedAmount;
    uint256 private initialTimestamp;
    IERC20 public REDUX;

    struct Investor {
        bool exists;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
    }

    mapping(address => Investor) public investorsInfo;

    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;

    /// @dev Checks that the contract is initialized.
    modifier initialized() {
        require(isInitialized, "not initialized");
        _;
    }

    /// @dev Checks that the contract is initialized.
    modifier notInitialized() {
        require(!isInitialized, "initialized");
        _;
    }

    modifier onlyInvestor() {
        require(investorsInfo[_msgSender()].exists, "Only investors allowed");
        _;
    }

    constructor(address _REDUX) {
        REDUX = IERC20(_REDUX);
    }

    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return initialTimestamp;
    }

    function updateVestingAmountForAirdrop(
        address[] memory beneficiary,
        uint256[] memory vestingAmount
    ) external onlyOwner {
        require(
            beneficiary.length == vestingAmount.length,
            "Input length invalid"
        );
        uint256 totalVestingAmountForAirdrop;
        for (uint256 i = 0; i < beneficiary.length; i++) {
            _addInvestor(beneficiary[i], vestingAmount[i]);
            totalVestingAmountForAirdrop = totalVestingAmountForAirdrop.add(
                vestingAmount[i]
            );
        }
        REDUX.safeTransferFrom(
            msg.sender,
            address(this),
            totalVestingAmountForAirdrop
        );
    }

    /// @dev Adds investor. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investor The addresses of new investors.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    function _addInvestor(address _investor, uint256 _tokensAllotment)
        internal
    {
        require(_investor != address(0), "Invalid address");
        require(
            _tokensAllotment > 0,
            "the investor allocation must be more than 0"
        );
        Investor storage investor = investorsInfo[_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.exists = true;
        totalAllocatedAmount = totalAllocatedAmount.add(_tokensAllotment);
        emit InvestorAdded(_investor, _msgSender(), _tokensAllotment);
    }

    function withdrawTokens() external onlyInvestor initialized {
        Investor storage investor = investorsInfo[_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_msgSender());

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        investor.withdrawnTokens = investor.withdrawnTokens.add(
            tokensAvailable
        );
        REDUX.safeTransfer(_msgSender(), tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    /// @dev The starting time of TGE
    /// @param _timestamp The initial timestamp, this timestap should be used for vesting
    function setInitialTimestamp(uint256 _timestamp)
        external
        onlyOwner
        notInitialized
    {
        isInitialized = true;
        initialTimestamp = _timestamp;
    }

    function withdrawableTokens(address _investor)
        public
        view
        returns (uint256 tokens)
    {
        Investor storage investor = investorsInfo[_investor];
        uint256 availablePercentage = _calculateAvailablePercentage();
        uint256 noOfTokens = _calculatePercentage(
            investor.tokensAllotment,
            availablePercentage
        );
        uint256 tokensAvailable = noOfTokens.sub(investor.withdrawnTokens);

        return tokensAvailable;
    }

    function _calculatePercentage(uint256 _amount, uint256 _percentage)
        private
        pure
        returns (uint256 percentage)
    {
        return _amount.mul(_percentage).div(100).div(1e18);
    }

    function _calculateAvailablePercentage()
        private
        view
        returns (uint256 availablePercentage)
    {
        // 0% on listing,after 45 days of cliffPeriod then linear vesting of 100 % for 5 months.

        // Redux assigned
        // 0% on TGE
        // 45 days cliffPeriod
        // remaining 100 % for 5 months
        // 100/5 = 20% every month released

        uint256 cliffPeriod = 45 days;
        uint256 fiveMonths = 150 days;

        uint256 remainingDistroPercentage = 100;
        uint256 noOfRemaingMonths = 5;
        uint256 everyMonthReleasePercentage = remainingDistroPercentage
            .mul(1e18)
            .div(noOfRemaingMonths);

        uint256 currentTimeStamp = block.timestamp;

        if (currentTimeStamp > initialTimestamp.add(cliffPeriod)) {
            if (
                currentTimeStamp <
                (initialTimestamp.add(cliffPeriod).add(fiveMonths))
            ) {
                // Date difference in days - (endDate - startDate) / 60 / 60 / 24 / 30;
                uint256 noOfMonths = (
                    currentTimeStamp.sub(initialTimestamp.add(cliffPeriod))
                ).div(2592000);

                uint256 currentUnlockedPercentage = noOfMonths.mul(
                    everyMonthReleasePercentage
                );

                return currentUnlockedPercentage;
            } else {
                return uint256(100).mul(1e18);
            }
        }
    }

    function recoverToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(token, amount);
    }
}