// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyStorage {
    /**
    * @notice Active brains of VeTokenProxy
    */
    address public veTokenImplementation;

    /**
    * @notice Pending brains of VeTokenProxy
    */
    address public pendingVeTokenImplementation;
}

contract VeTokenStorage is  ProxyStorage {
    address public token;  // token
    uint256 public supply; // veToken

    // veToken related
    string public name;
    string public symbol;
    string public version;
    uint256 constant decimals = 18;

    // score related
    uint256 public scorePerBlk;
    uint256 public totalStaked;

    mapping (address => UserInfo) internal userInfo;
    PoolInfo public poolInfo;
    uint256 public startBlk;  // start Blk
    uint256 public clearBlk;  // set annually
    
    // User variables
    struct UserInfo {
        uint256 amount;        // How many tokens the user has provided.
        uint256 score;         // score exclude pending amount
        uint256 scoreDebt;     // score debt
        uint256 lastUpdateBlk; // last user's tx Blk
    }

    // Pool variables
    struct PoolInfo {      
        uint256 lastUpdateBlk;     // Last block number that score distribution occurs.
        uint256 accScorePerToken;   // Accumulated socres per token, times 1e12. 
    }

    address public smartWalletChecker;
}