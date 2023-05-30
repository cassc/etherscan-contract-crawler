// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../IStaking.sol";
import "./ISaleV3.sol";

contract VestingV3 is AccessControl {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    error ArraySizesDoesNotMatch();
    error WrongPercentage();
    error NoTokenToClaim();
    error ContractDoesNotHaveEnoughFunds();
    error ClaimTimeMustBeHigherThanLastClaimTime();
    error AddressBlacklisted();
    error AddressIsNotBeneficiary();
    error ContractStopped();

    /// 100% in basis points
    uint96 public constant PERCENTAGE = 10000;
    /// Role for blacklisting addresses
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
    /// Vesting token
    IERC20 public immutable token;
    /// Variable for keeping contract stopped state
    bool public contractStopped;
    /// Total token amount to claim
    uint256 public tokenAmountToClaim;
    /// Total claimed token amount
    uint256 public claimedTokenAmount;
    /// Total claimed markup amount
    uint256 public claimedMarkupAmount;
    /// Address to collect markups
    address public markupOwner;

    /// Sale contract
    ISaleV3 public sale;
    /// Staking contract
    IStaking public staking;

    /// Beneficiary list
    EnumerableSet.AddressSet private _beneficiaries;
    /// Blacklisted beneficiary list
    EnumerableSet.AddressSet private _blacklistedBeneficiaries;

    /**
     * @dev This struct holds information about vesting
     * @param claimTime Claim time for vesting
     * @param claimPercentage Percentage of total tokens to claim for the beneficiary
     */
    struct VestingStruct {
        uint128 claimTime;
        uint128 claimPercentage;
    }
    /// Arrays of vestings
    VestingStruct[] private _vestings;

    /// A mapping for storing beneficiaries total claim amount
    mapping(address => uint256) private _beneficiaryTotalClaimAmount;
    /// A mapping for storing beneficiaries total claimed amount (with markup)
    mapping(address => uint256) private _beneficiaryClaimedAmount;
    /// A mapping for storing total deducted markup amount from the beneficiary
    mapping(address => uint256) private _beneficiaryMarkupAmount;
    /// A mapping for storing addresses with deducted markup
    mapping(address => bool) private _beneficiaryMarkup;

    /**
     * @dev Emitted when beneficiary claimed vested tokens
     * @param claimer The beneficiary address
     * @param amountWithMarkup Claimed amount with markup
     * @param amountMarkup Total deducted markup amount
     */
    event Claim(address indexed claimer, uint256 amountWithMarkup, uint256 amountMarkup);
    /**
     * @dev Emitted when funds are withdrawn
     * @param tokenTransferAddress The withdrawn address
     * @param transferAmount The withdrawn amount
     */
    event EmergencyWithdraw(address tokenTransferAddress, uint256 transferAmount);

    constructor(
        address _token,
        address _sale,
        address _staking,
        address _markupOwner,
        uint128[] memory _claimTime,
        uint128[] memory _claimPercentage
    ) {
        if (_claimTime.length != _claimPercentage.length) revert ArraySizesDoesNotMatch();
        token = IERC20(_token);
        sale = ISaleV3(_sale);
        staking = IStaking(_staking);
        markupOwner = _markupOwner;

        uint96 tempPercentage;
        uint128 tempTime = 0;
        for (uint256 i = 0; i < _claimTime.length; i++) {
            uint128 claimTime = _claimTime[i];
            uint128 claimPercentage = _claimPercentage[i];

            if (tempTime >= claimTime) revert ClaimTimeMustBeHigherThanLastClaimTime();
            tempTime = claimTime;

            VestingStruct memory vesting = VestingStruct(claimTime, claimPercentage);
            _vestings.push(vesting);

            tempPercentage += uint96(claimPercentage);
        }

        if (tempPercentage != PERCENTAGE) revert WrongPercentage();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BLACKLISTER_ROLE, msg.sender);
    }

    modifier notStopped() {
        if (contractStopped) revert ContractStopped();
        _;
    }

    modifier notBlacklisted() {
        if (_blacklistedBeneficiaries.contains(msg.sender)) revert AddressBlacklisted();
        _;
    }

    function addBeneficiaries(address[] memory addresses, uint256[] memory amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (addresses.length != amounts.length) revert ArraySizesDoesNotMatch();

        uint256 tempAmountToClaim;
        for (uint256 i = 0; i < addresses.length; i++) {
            address beneficiary = addresses[i];
            uint256 amount = amounts[i];

            _beneficiaries.add(beneficiary);
            tempAmountToClaim += amount;

            _beneficiaryTotalClaimAmount[beneficiary] = amount;
        }

        tokenAmountToClaim += tempAmountToClaim;
    }

    function claim() external notStopped notBlacklisted {
        if (!_beneficiaries.contains(msg.sender)) revert AddressIsNotBeneficiary();

        // once beneficiary markup status set to true it can't be set false back
        if (!_beneficiaryMarkup[msg.sender] && _checkBeneficiaryMarkup(msg.sender))
            _beneficiaryMarkup[msg.sender] = true;

        (uint256 amountToClaimWithMarkup, uint256 amountMarkup) = getAvailableAmountToClaim(msg.sender);
        uint256 contractBalance = token.balanceOf(address(this));
        if (amountToClaimWithMarkup == 0) revert NoTokenToClaim();
        if (amountToClaimWithMarkup > contractBalance) revert ContractDoesNotHaveEnoughFunds();

        _beneficiaryClaimedAmount[msg.sender] += amountToClaimWithMarkup;
        claimedTokenAmount += amountToClaimWithMarkup;
        uint256 amountToSendBeneficiary = amountToClaimWithMarkup - amountMarkup;
        token.safeTransfer(msg.sender, amountToSendBeneficiary);

        if (amountMarkup > 0) {
            _beneficiaryMarkupAmount[msg.sender] += amountMarkup;
            claimedMarkupAmount += amountMarkup;

            token.safeTransfer(markupOwner, amountMarkup);
        }

        emit Claim(msg.sender, amountToClaimWithMarkup, amountMarkup);
    }

    function blacklist(address[] memory addresses) external onlyRole(BLACKLISTER_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            _blacklistedBeneficiaries.add(addresses[i]);
        }
    }

    function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);

        contractStopped = true;

        emit EmergencyWithdraw(msg.sender, balance);
    }

    function getBeneficiaryDetails(address beneficiary)
        external
        view
        returns (
            uint256 beneficiaryTotalClaimAmount,
            uint256 beneficiaryClaimedAmount,
            uint256 beneficiaryMarkupAmount,
            bool beneficiaryMarkup
        )
    {
        beneficiaryTotalClaimAmount = _beneficiaryTotalClaimAmount[beneficiary];
        beneficiaryClaimedAmount = _beneficiaryClaimedAmount[beneficiary];
        beneficiaryMarkupAmount = _beneficiaryMarkupAmount[beneficiary];
        beneficiaryMarkup = _beneficiaryMarkup[beneficiary];
    }

    function getVestings() external view returns (VestingStruct[] memory vestings) {
        vestings = _vestings;
    }

    function getAvailableAmountToClaim(address beneficiary) public view returns (uint256 amount, uint256 amountMarkup) {
        amount = _getAmountToClaim(beneficiary) - _beneficiaryClaimedAmount[beneficiary];
        amountMarkup = 0;
        // if (_checkBeneficiaryMarkup(beneficiary)) {
        //     uint96 markupFee = sale.getMarkupFee();
        //     amountMarkup = (amount * markupFee) / PERCENTAGE;
        // }
    }

    /**
     * @dev Checks beneficiary markup status
     * if beneficiary not marked up before checks staked amount and returns the markup result
     */
    function _checkBeneficiaryMarkup(address beneficiary) private view returns (bool markup) {
        markup = false;
        // if (_beneficiaryMarkup[beneficiary]) markup = true;
        // else {
        //     (, , , , , , bool participantMarkup) = sale.getParticipantDetails(beneficiary);
        //     (uint256 stakedAmount, , , , ) = staking.getStakerDetails(beneficiary);
        //     uint256 minStakedAmount = sale.getMinStakedAmount();
        //     if (!participantMarkup)
        //         if (stakedAmount < minStakedAmount) markup = true;
        // }
    }

    function _getAmountToClaim(address beneficiary) private view returns (uint256 amount) {
        uint256 beneficiaryTotalClaimAmount = _beneficiaryTotalClaimAmount[beneficiary];

        uint256 percentageToClaim;
        for (uint256 i = 0; i < _vestings.length; i++) {
            if (block.timestamp < _vestings[i].claimTime) break;

            percentageToClaim += _vestings[i].claimPercentage;
        }

        amount = _calculateAmount(beneficiaryTotalClaimAmount, percentageToClaim);
    }

    function _calculateAmount(uint256 amount, uint256 percentage) private pure returns (uint256 calculatedAmount) {
        calculatedAmount = (amount * percentage) / PERCENTAGE;
    }
}