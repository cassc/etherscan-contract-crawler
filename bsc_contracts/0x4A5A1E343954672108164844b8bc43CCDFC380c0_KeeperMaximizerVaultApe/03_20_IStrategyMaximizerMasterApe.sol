// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libs/IMaximizerVaultApe.sol";

// For interacting with our own strategy
interface IStrategyMaximizerMasterApe {
    function STAKE_TOKEN_ADDRESS() external returns (address);

    function vaultApe() external returns (IMaximizerVaultApe);

    function accSharesPerStakedToken() external view returns (uint256);

    function totalStake() external view returns (uint256);

    function getExpectedOutputs()
        external
        view
        returns (
            uint256 platformOutput,
            uint256 keeperOutput,
            uint256 burnOutput,
            uint256 bananaOutput
        );

    function balanceOf(address)
        external
        view
        returns (
            uint256 stake,
            uint256 banana,
            uint256 autoBananaShares
        );

    function userInfo(address)
        external
        view
        returns (
            uint256 stake,
            uint256 autoBananaShares,
            uint256 rewardDebt,
            uint256 lastDepositedTime
        );

    // Main want token compounding function
    function earn(
        uint256 _minPlatformOutput,
        uint256 _minKeeperOutput,
        uint256 _minBurnOutput,
        uint256 _minBananaOutput,
        bool _takeKeeperFee
    ) external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _userAddress, uint256 _amount) external;

    // Transfer want tokens strategy -> vaultChef
    function withdraw(address _userAddress, uint256 _wantAmt) external;

    function claimRewards(address _userAddress, uint256 _shares) external;

    function emergencyVaultWithdraw() external;

    function emergencyBananaVaultWithdraw(address _to) external;
}