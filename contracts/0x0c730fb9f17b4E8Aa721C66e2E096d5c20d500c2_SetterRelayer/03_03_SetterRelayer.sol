pragma solidity 0.6.7;

import "geb-treasury-reimbursement/reimbursement/single/IncreasingTreasuryReimbursement.sol";

abstract contract OracleRelayerLike {
    function redemptionPrice() virtual external returns (uint256);
    function modifyParameters(bytes32,uint256) virtual external;
}

contract SetterRelayer is IncreasingTreasuryReimbursement {
    // --- Events ---
    event RelayRate(address setter, uint256 redemptionRate);

    // --- Variables ---
    // When the rate has last been relayed
    uint256           public lastUpdateTime;                      // [timestamp]
    // Enforced gap between relays
    uint256           public relayDelay;                          // [seconds]
    // The address that's allowed to pass new redemption rates
    address           public setter;
    // The oracle relayer contract
    OracleRelayerLike public oracleRelayer;

    constructor(
      address oracleRelayer_,
      address treasury_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_,
      uint256 relayDelay_
    ) public IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_) {
        relayDelay    = relayDelay_;
        oracleRelayer = OracleRelayerLike(oracleRelayer_);

        emit ModifyParameters("relayDelay", relayDelay_);
    }

    // --- Administration ---
    /*
    * @notice Change the addresses of contracts that this relayer is connected to
    * @param parameter The contract whose address is changed
    * @param addr The new contract address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "SetterRelayer/null-addr");
        if (parameter == "setter") {
          setter = addr;
        }
        else if (parameter == "treasury") {
          require(StabilityFeeTreasuryLike(addr).systemCoin() != address(0), "SetterRelayer/treasury-coin-not-set");
          treasury = StabilityFeeTreasuryLike(addr);
        }
        else revert("SetterRelayer/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          addr
        );
    }
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The parameter name
    * @param val The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "baseUpdateCallerReward") {
          require(val <= maxUpdateCallerReward, "SetterRelayer/invalid-base-caller-reward");
          baseUpdateCallerReward = val;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(val >= baseUpdateCallerReward, "SetterRelayer/invalid-max-caller-reward");
          maxUpdateCallerReward = val;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(val >= RAY, "SetterRelayer/invalid-caller-reward-increase");
          perSecondCallerRewardIncrease = val;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(val > 0, "SetterRelayer/invalid-max-increase-delay");
          maxRewardIncreaseDelay = val;
        }
        else if (parameter == "relayDelay") {
          relayDelay = val;
        }
        else revert("SetterRelayer/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          val
        );
    }

    // --- Core Logic ---
    /*
    * @notice Relay a new redemption rate to the OracleRelayer
    * @param redemptionRate The new redemption rate to relay
    */
    function relayRate(uint256 redemptionRate, address feeReceiver) external {
        // Perform checks
        require(setter == msg.sender, "SetterRelayer/invalid-caller");
        require(feeReceiver != address(0), "SetterRelayer/null-fee-receiver");
        require(feeReceiver != setter, "SetterRelayer/setter-cannot-receive-fees");
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= relayDelay, lastUpdateTime == 0), "SetterRelayer/wait-more");
        // Get the caller's reward
        uint256 callerReward = getCallerReward(lastUpdateTime, relayDelay);
        // Store the timestamp of the update
        lastUpdateTime = now;
        // Update the redemption price and then set the rate
        oracleRelayer.redemptionPrice();
        oracleRelayer.modifyParameters("redemptionRate", redemptionRate);
        // Emit an event
        emit RelayRate(setter, redemptionRate);
        // Pay the caller for relaying the rate
        rewardCaller(feeReceiver, callerReward);
    }
}