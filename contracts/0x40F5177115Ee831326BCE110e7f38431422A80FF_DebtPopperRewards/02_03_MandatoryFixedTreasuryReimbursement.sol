pragma solidity 0.6.7;

import "../../math/GebMath.sol";

abstract contract StabilityFeeTreasuryLike {
    function getAllowance(address) virtual external view returns (uint, uint);
    function systemCoin() virtual external view returns (address);
    function pullFunds(address, address, uint) virtual external;
}

contract MandatoryFixedTreasuryReimbursement is GebMath {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "MandatoryFixedTreasuryReimbursement/account-not-authorized");
        _;
    }

    // --- Variables ---
    // The fixed reward sent by the treasury to a fee receiver
    uint256 public fixedReward;               // [wad]
    // SF treasury
    StabilityFeeTreasuryLike public treasury;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );
    event RewardCaller(address indexed finalFeeReceiver, uint256 fixedReward);

    constructor(address treasury_, uint256 fixedReward_) public {
        require(fixedReward_ > 0, "MandatoryFixedTreasuryReimbursement/null-reward");
        require(treasury_ != address(0), "MandatoryFixedTreasuryReimbursement/null-treasury");

        authorizedAccounts[msg.sender] = 1;

        treasury    = StabilityFeeTreasuryLike(treasury_);
        fixedReward = fixedReward_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("treasury", treasury_);
        emit ModifyParameters("fixedReward", fixedReward);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Treasury Utils ---
    /*
    * @notify Return the amount of SF that the treasury can transfer in one transaction when called by this contract
    */
    function treasuryAllowance() public view returns (uint256) {
        (uint total, uint perBlock) = treasury.getAllowance(address(this));
        return minimum(total, perBlock);
    }
    /*
    * @notify Get the actual reward to be sent by taking the minimum between the fixed reward and the amount that can be sent by the treasury
    */
    function getCallerReward() public view returns (uint256 reward) {
        reward = minimum(fixedReward, treasuryAllowance() / RAY);
    }
    /*
    * @notice Send a SF reward to a fee receiver by calling the treasury
    * @param proposedFeeReceiver The address that will receive the reward (unless null in which case msg.sender will receive it)
    */
    function rewardCaller(address proposedFeeReceiver) internal {
        // If the receiver is the treasury itself or if the treasury is null or if the reward is zero, revert
        require(address(treasury) != proposedFeeReceiver, "MandatoryFixedTreasuryReimbursement/reward-receiver-cannot-be-treasury");
        require(both(address(treasury) != address(0), fixedReward > 0), "MandatoryFixedTreasuryReimbursement/invalid-treasury-or-reward");

        // Determine the actual fee receiver and reward them
        address finalFeeReceiver = (proposedFeeReceiver == address(0)) ? msg.sender : proposedFeeReceiver;
        uint256 finalReward      = getCallerReward();
        treasury.pullFunds(finalFeeReceiver, treasury.systemCoin(), finalReward);

        emit RewardCaller(finalFeeReceiver, finalReward);
    }
}