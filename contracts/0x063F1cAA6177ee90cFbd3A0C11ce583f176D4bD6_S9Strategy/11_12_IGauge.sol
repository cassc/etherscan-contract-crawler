pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IGauge {

    struct CalculateClaimableRbn{
        uint currentDate;
        uint periodTimestamp;
        uint integrateInvSupply;
        uint integrateFraction;
        uint integrateInvSupplyOf;
        uint futureEpochTime;
        uint inflationRate;
        uint rate;
        bool isKilled;
        uint workingSupply;
        uint workingBalance;
        uint mintedRbn;
        address gaugeContractAddress;
        address gaugeControllerContract;
    }

    function period() external view returns(uint128 period);

    function is_killed() external view returns(bool isKilled);

    function totalSupply() external view returns(uint totalSupply);

    function working_balances(address user) external view returns(uint externalBalances);

    function working_supply() external view returns(uint workingSupply);

    function period_timestamp(uint period) external view returns(uint periodTimestamp);    

    function integrate_inv_supply(uint period) external view returns(uint integrateInvSupply);

    function integrate_fraction(address user) external view returns(uint integrateFraction);

    function integrate_inv_supply_of(address user) external view returns(uint integrateSupplyOf);

    function future_epoch_time() external view returns(uint futureEpochTime);

    function inflation_rate() external view returns(uint inflationRate);

    function controller() external view returns(address controller);

    function claim() external;    

    function withdraw(uint amount) external;

}