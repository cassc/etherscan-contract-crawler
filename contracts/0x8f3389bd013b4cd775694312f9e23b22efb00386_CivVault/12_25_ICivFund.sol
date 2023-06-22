// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '../libraries/FixedPoint.sol';

struct PoolInfo {
    // Info on each pool
    IERC20 lpToken; // Address of asset token (Staking Token) e.g. USDT
    ICivFundRT fundRepresentToken; // Fund Represent tokens for deposit in the strategy
    IERC20 guaranteeToken;  // Guarantee Token address e.g. xStone
    uint256 NAV;            // Pool NAV
    uint256 totalShares;    // Pool Total Share Amount
    uint256 valuePerShare;  // Share Value
    uint256 watermark;      // Pool WaterMark
    uint256 unpaidFee;      // Pool Unpaid Amount
    uint256 fee;            // Pool Fee Amount
    address[] withdrawAddress;  // Pool Withdraw Address
    uint256 burnShareAmount;    // Share amount to burn
    uint256 currentDepositEpoch;       // Pool Current Deposit Epoch
    uint256 currentWithdrawEpoch; // Pool Current Withdraw Epoch
}

struct VaultInfo {
    // Info on each pool
    // We Split Pool Struct into 2 struct cause of solidity deep
    bool paused;    // Flag that deposit is paused or not
    uint256 currentDeposit; // Pool Current Pending Deposit Amount
    uint256 currentWithdraw;    // Pool Current Pending Withdraw Amount
    uint256 lockPeriod;          // Pool Guarantee Token Lock Period
    uint256 maxDeposit;         // Pool Max Deposit Amount
    uint256 maxUser;            // Pool Max User Count
    uint256 collectFeeDuration; // Pool Collecting Duration for Fee
    uint256 depositDuration;    // Pool Deposit pending fund to strategy duration
    uint256 withdrawDuration;   // Pool Withdraw fund to user duration
    uint256 lastCollectFee;     // Pool last collect fee timestamp
    uint256 lastDeposit;        // Pool Last deposit pending fund to strategy timestamp
    uint256 lastWithdraw;       // Pool Last Withdraw fund to users timestamp
    uint256 curDepositUser;     // Pool current epoch deposit users length
    uint256 curWithdrawUser;    // Pool current epoch withdraw users length
}

interface ICivVault {

    function getPoolInfo(uint) external view returns(PoolInfo memory, VaultInfo memory);
}

interface ICivFundRT is IERC20, IAccessControl {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface ICivVaultGetter {
    function addUniPair(uint,address,address) external;
    function getPrice(uint,uint) external view returns(uint);
    function getReversePrice(uint,uint) external view returns(uint);
    function getBalanceOfUser(uint,address) external view returns(uint,uint);
    function updateAll(uint) external;
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint256);
    function symbol() external view returns (string memory);
}