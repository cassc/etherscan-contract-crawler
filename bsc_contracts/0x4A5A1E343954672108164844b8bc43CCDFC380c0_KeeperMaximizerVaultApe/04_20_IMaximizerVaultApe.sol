// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMaximizerVaultApe {
    function KEEPER_FEE_UL() external view returns (uint256);

    function PLATFORM_FEE_UL() external view returns (uint256);

    function BUYBACK_RATE_UL() external view returns (uint256);

    function WITHDRAW_FEE_UL() external view returns (uint256);

    function WITHDRAW_REWARDS_FEE_UL() external view returns (uint256);

    function WITHDRAW_FEE_PERIOD_UL() external view returns (uint256);

    struct Settings {
        address treasury;
        uint256 keeperFee;
        address platform;
        uint256 platformFee;
        uint256 buyBackRate;
        uint256 withdrawFee;
        uint256 withdrawFeePeriod;
        uint256 withdrawRewardsFee;
    }

    function getSettings() external view returns (Settings memory);

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 stake,
            uint256 autoBananaShares,
            uint256 rewardDebt,
            uint256 lastDepositedTime
        );

    function vaults(uint256 _pid) external view returns (address);

    function vaultsLength() external view returns (uint256);

    function addVault(address _strat) external;

    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function depositTo(
        uint256 _pid,
        address _to,
        uint256 _wantAmt
    ) external;

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function withdrawAll(uint256 _pid) external;

    function earnAll() external;

    function earnSome(uint256[] memory pids) external;

    function harvest(uint256 _pid, uint256 _wantAmt) external;

    function harvestAll(uint256 _pid) external;
}