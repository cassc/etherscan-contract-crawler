// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "../openzeppelinupgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IPiStakingVaults {
    // function poolLength() external view returns (uint256);

    // function userInfo() external view returns (uint256);

    // Info of each userInfo[_pid][msg.sender].
    struct UserInfo {
        uint256 amount;         // How many LP tokens/ WANT tokens the user has staked.
        uint256 shares; 
        uint256[] AllNFTIds;
    }
    
  
    // Info of each pool.
    struct PoolInfo {
        uint256 PiTokenAmtPerNFT;  // this amount of Pi will be given to user for each NFT staked       
        address nativeToken;           // Address of native token
        address nativeNFTtoken;           // Address of native NFT token
        uint256 ERC1155NFTid;
        bool isERC1155;
        address wantToken;           // Address of LP token / want contract
        uint256 allocPoint;       // How many allocation points assigned to this pool. Pis to distribute per block.
        uint16 depositFeeNative;      // Deposit fee in basis points 100000 = 100%
        uint256 NFTperDepositFee;
        address strat;             // Strategy address that will auto compound want tokens
        uint256 rewardPerLPTokenStored;
        uint256 lastUpdateTime;  // Last block number that Pis distribution occurs.
        uint256 MAX_SLOTS; // active stakes cannot be more than MAX_SLOTS
        uint256 MAX_PER_USER; // 1 user cannot stake NFTs more than MAX_PER_USER
    }

    function userInfo(uint256 pid, address user) external view returns (UserInfo memory info);
    function poolInfo(uint256 pid) external view returns (PoolInfo memory pools);

    function NFTIdsDeposits(uint256 pid, address user, uint256 NFTid) external view returns (uint256 quantity);
  
    // View function to see your initial deposit
    function balanceOf(uint256 _pid, address _user)        
        external
        view
        returns (uint256);

    // View function to see your updated deposit
    function getusercompounds(uint256 _pid, address _useraddress) 
        external
        view
        returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}