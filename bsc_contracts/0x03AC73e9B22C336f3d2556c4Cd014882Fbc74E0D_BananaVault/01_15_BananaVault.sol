// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         

 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../libs/IMasterApeV2.sol";

/// @title Banana Vault V2
/// @author ApeSwapFinance
/// @notice Banana vault without fees. Usage only for ApeSwap maximizer vaults
/// @dev This contract is used to interface with the MasterApeV2 contract
contract BananaVault is AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 bananaAtLastUserAction; // keeps track of banana deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 public constant DEPOSIT_ROLE = keccak256("DEPOSIT");

    IERC20 public immutable bananaToken;
    IMasterApeV2 public immutable masterApeV2;

    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;

    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 shares,
        uint256 lastDepositedTime
    );
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Earn(address indexed sender);

    /**
     * @notice Constructor
     * @param _bananaToken: Banana token contract
     * @param _masterApeV2: Master Ape V2 contract
     * @param _admin: address of the owner
     */
    constructor(
        IERC20 _bananaToken,
        address _masterApeV2,
        address _admin
    ) {
        bananaToken = _bananaToken;
        masterApeV2 = IMasterApeV2(_masterApeV2);

        // Setup access control
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MANAGER_ROLE, _admin);
        // A manager can be a vault contract which can add sub strategies to the deposit role
        _setRoleAdmin(MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        // Allow managers to grant/revoke deposit roles
        _setRoleAdmin(DEPOSIT_ROLE, MANAGER_ROLE);
    }

    /**
     * @notice Deposits funds into the Banana Vault
     * @param _amount: number of tokens to deposit (in BANANA)
     */
    function deposit(uint256 _amount)
        external
        nonReentrant
        onlyRole(DEPOSIT_ROLE)
    {
        if(_amount == 0){
            // Depositing zero is a way for external contracts to know that an _earn was performed 
            _earn();
            return;
        }

        uint256 totalBananaTokens = underlyingTokenBalance();
        bananaToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount * totalShares) / totalBananaTokens;
        } else {
            currentShares = _amount;
        }
        require(currentShares > 0, "BananaVault:: Adding 0 shares");

        UserInfo storage user = userInfo[msg.sender];
        user.shares += currentShares;
        user.lastDepositedTime = block.timestamp;

        totalShares += currentShares;

        user.bananaAtLastUserAction = (user.shares * underlyingTokenBalance()) / totalShares;
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() external {
        withdraw(userInfo[msg.sender].shares);
    }

    /**
     * @notice Reinvests BANANA tokens into MasterApe
     */
    function earn() external {
        masterApeV2.deposit(0, 0);

        _earn();

        emit Earn(msg.sender);
    }

    /**
     * @notice Calculates the total pending rewards that can be restaked
     * @return Returns total pending Banana rewards
     */
    function calculateTotalPendingBananaRewards()
        external
        view
        returns (uint256)
    {
        uint256 amount = masterApeV2.pendingBanana(0, address(this));
        return amount + available();
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : (underlyingTokenBalance() * 1e18) / totalShares;
    }

    /**
     * @notice Withdraws from funds from the Banana Vault
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(_shares > 0, "BananaVault: Must withdraw more than 0");
        uint256 currentShares = user.shares < _shares ? user.shares : _shares;

        uint256 bananaTokensToWithdraw = (underlyingTokenBalance() * currentShares) / totalShares;
        user.shares -= currentShares;
        totalShares -= currentShares;

        uint256 bal = available();
        if (bal < bananaTokensToWithdraw) {
            uint256 balWithdraw = bananaTokensToWithdraw - bal;
            masterApeV2.withdraw(0, balWithdraw);
            // Check if the withdraw deposited enough tokens into this contract
            uint256 balAfter = available();
            if (balAfter < bananaTokensToWithdraw) {
                bananaTokensToWithdraw = balAfter;
            }
        }

        if (user.shares > 0) {
            user.bananaAtLastUserAction = (user.shares * underlyingTokenBalance()) / totalShares;
        } else {
            user.bananaAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;
        bananaToken.safeTransfer(msg.sender, bananaTokensToWithdraw);
        emit Withdraw(msg.sender, bananaTokensToWithdraw, _shares);
    }

    /**
     * @notice Custom logic for how much the vault allows to be borrowed
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return bananaToken.balanceOf(address(this));
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in MasterApe
     */
    function underlyingTokenBalance() public view returns (uint256) {
        (uint256 amount, ) = masterApeV2.userInfo(0, address(this));

        return bananaToken.balanceOf(address(this)) + amount;
    }

    /**
     * @notice Deposits tokens into MasterApe to earn staking rewards
     */
    function _earn() internal {
        uint256 balance = available();

        if (balance > 0) {
            if (
                bananaToken.allowance(address(this), address(masterApeV2)) <
                balance
            ) {
                bananaToken.safeApprove(address(masterApeV2), type(uint256).max);
            }

            masterApeV2.deposit(0, balance);
        }
    }
}