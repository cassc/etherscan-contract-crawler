// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "../openzeppelinupgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IStrategy {
    // function poolLength() external view returns (uint256);

    // function userInfo() external view returns (uint256);

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of SUSHI entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

     // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. dMagics to distribute per block.
        uint256 lastRewardBlockTime;  // Last block number that dMagics distribution occurs.
        uint256 accdMagicPerShare;   // Accumulated dMagics per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    function initialize(        
        address _dMagicFarmAddress,
        uint256 _dMagicVaultPoolid,
        address _wantAddress, // SLP token from token0 and token1 
        address _token0Address,
        address _token1Address,
        address _SUSHIVaultAddress, // Sushi Staking Contract
        uint256 _SUSHIPoolId, // Sushi Pool id of Vault
        address _earnedAddress // WMATIC token
    ) external;

    function userInfo(uint256 pid, address user) external view returns (UserInfo memory info);
    function poolInfo(uint256 pid) external view returns (PoolInfo memory pools);
    function sharesTotal() external view returns (uint256);
    function wantLockedTotal() external view returns (uint256);
    
    function wantAddress() external view returns (address);
    function token0Address() external view returns (address);
    function token1Address() external view returns (address);

    function deposit(address userAddress, uint256 _amount) external returns (uint256 sharesAdded);

    function withdraw(address userAddress, uint256 _amount) external returns (uint256 sharesRemoved);
    
    function upgradeTo(address implementation) external ;

}