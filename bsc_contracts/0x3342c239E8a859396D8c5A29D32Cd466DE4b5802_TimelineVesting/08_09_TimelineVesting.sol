// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IVesting.sol";
import "hardhat/console.sol";

contract TimelineVesting is Ownable, ReentrancyGuard, IVesting {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256[] public policies;
    uint256 public denom;
    uint256[] public timelines;

    mapping(address => uint256) allocatedBalance;
    mapping(address => uint256) public override claimed;
    mapping(address => bool) public refundRequested;

    event Released(
        address indexed beneficiary,
        uint256 currentTime,
        uint256 amount
    );

    modifier zeroAddr(address _addr) {
        require(_addr != address(0), "Set zero address");
        _;
    }

    constructor(address _token) Ownable() {
        require(_token != address(0), "Set zero address");
        token = IERC20(_token);
    }

    /**
        @notice Set policy and vesting timeline
        @param _timelines list of time to return corresponding to `_policy`
            `_timeline` length must be `_policy` length + 1 
            as last vesting time will return remaining of allocated amount
        @param _policies list of vesting return in `_denom` of total allocated amount
        @param _denom denominator of `_policy`
     */
    function setPolicy(
        uint256[] calldata _timelines,
        uint256[] calldata _policies,
        uint256 _denom
    ) external onlyOwner {
        require(
            _policies.length > 0 && _timelines.length == _policies.length + 1,
            "Policy and timeline length mismatch"
        );

        for (uint256 i = 1; i < timelines.length; i++) {
            require(
                timelines[i] > timelines[i - 1],
                "Timeline must be increasing"
            );
        }

        uint256 policiesSum = 0;
        for (uint256 i = 0; i < _policies.length; i++) {
            policiesSum += _policies[i];
        }
        require(policiesSum < _denom, "Policies must not exceeed denominator");

        policies = _policies;
        timelines = _timelines;
        denom = _denom;
    }

    function getTotalAllocated(
        address _beneficiary
    ) external view override returns (uint256) {
        return allocatedBalance[_beneficiary];
    }

    /**
        @notice add beneficiary
        @dev Caller must be Owner
        Not allow Owner to alter the vesting policy
        @param _beneficiary `_beneficiary` address
        @param _beneficiary Amount that `_beneficiary` can claim in total
    */
    function addBeneficiary(
        address _beneficiary,
        uint256 _totalAmt
    ) external onlyOwner zeroAddr(_beneficiary) {
        require(allocatedBalance[_beneficiary] == 0, "Already added");
        allocatedBalance[_beneficiary] = _totalAmt;
    }

    /**
        @notice add multiple beneficiaries
        @dev Caller must be Owner
        Not allow Owner to alter the vesting policy
        @param _beneficiaries all `_beneficiaries` address
        @param _totalAmt Amount that corresponding `_beneficiary` can claim in total 
    */
    function addBeneficiaries(
        address[] calldata _beneficiaries,
        uint256[] calldata _totalAmt
    ) external onlyOwner {
        require(
            _beneficiaries.length == _totalAmt.length,
            "Invalid array length"
        );
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            require(
                _beneficiaries[i] != address(0),
                "beneficiary must not be address zero"
            );
            require(allocatedBalance[_beneficiaries[i]] == 0, "Already added");
            allocatedBalance[_beneficiaries[i]] = _totalAmt[i];
        }
    }

    /**
        @notice Query available amount that `_beneficiary` is able to claim at the moment
        @dev Caller can be ANY
    */
    function getAvailAmt(
        address _beneficiary
    ) public view override returns (uint256 _amount) {
        for (uint256 i = 0; i < timelines.length; i++) {
            if (timelines[i] > block.timestamp) {
                break;
            }
            if (i == timelines.length - 1) {
                _amount = allocatedBalance[_beneficiary];
            } else {
                _amount +=
                    (allocatedBalance[_beneficiary] * policies[i]) /
                    denom;
            }
        }
        _amount -= claimed[_beneficiary];
    }

    /**
        @notice Beneficiaries use this method to claim vesting tokens
        @dev Caller can be ANY
        Note: 
        - Only Beneficiaries, who were added into the list, are able to claim tokens
        - If `_policy`, that binds to msg.sender, is not found -> revert
        - Previously unclaimed amounts will be accumulated
    */
    function claim() external override nonReentrant {
        address _beneficiary = _msgSender();
        require(allocatedBalance[_beneficiary] != 0, "Beneficiary not existed");
        require(!refundRequested[_beneficiary], "Already refunded");

        uint256 _amount = getAvailAmt(_beneficiary);
        require(
            _amount != 0,
            "Zero vesting amount. Please check your policy again"
        );

        claimed[_beneficiary] += _amount;
        _releaseTokenTo(_beneficiary, block.timestamp, _amount);
    }

    /**
       	@notice Owner uses this method to transfer remaining tokens
       	@dev Caller must be Owner
	   		Note: 
			- This method should be used ONLY in the case that
			tokens are distributed wrongly by mistaken settings
    */
    function collect() external onlyOwner {
        uint256 _balance = token.balanceOf(address(this));
        require(_balance != 0, "Allocations completely vested");

        _releaseTokenTo(_msgSender(), block.timestamp, _balance);
    }

    function _releaseTokenTo(
        address _beneficiary,
        uint256 _now,
        uint256 _amount
    ) private {
        token.safeTransfer(_beneficiary, _amount);

        emit Released(_beneficiary, _now, _amount);
    }

    /**
        @notice Request a refunds 
        @dev Caller should be a beneficiary
            Note: 
            - If this method is call, beneficiary can no longer claim token
            - Beneficiary must not call after already claim
    */
    function refundRequest() external {
        refundRequested[_msgSender()] = true;

        emit RefundRequested(_msgSender());
    }

    /**
        @notice Cancel refund request
        @dev Caller should be a owner
    */
    function cancelRefund(address _beneficiary) external onlyOwner {
        require(refundRequested[_beneficiary], "No refund requested");
        delete refundRequested[_beneficiary];
    }

    /**
        @notice remove a beneficiary
        @dev Caller should be a owner
            Note: 
            - If this method is call, beneficiary can no longer claim token
    */
    function removeBeneficiary(address _beneficiary) external onlyOwner {
        allocatedBalance[_beneficiary] = 0;
    }

    function isRefundRequested(
        address _beneficiary
    ) external view override returns (bool) {
        return refundRequested[_beneficiary];
    }
}