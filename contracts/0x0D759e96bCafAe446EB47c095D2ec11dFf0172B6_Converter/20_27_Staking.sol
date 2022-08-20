// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";

import "./Controller.sol";
import "./helpers/Util.sol";
import "./StakingStorage.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Logic contract
 */

contract Staking is IStaking, Util, PermissionControl, Pausable {
    using SafeERC20 for IERC20;

    bool private _initialized = false;

    uint256 public constant ASTO_TOKEN_ID = 0;
    uint256 public constant LP_TOKEN_ID = 1;

    /**
     * `_token`:  tokenId => token contract address
     * `_token`:  tokenId => token name
     * `_storage`:  tokenId => storage contract address
     * `totalStakedAmount`:  tokenId => total staked amount for that tokenId
     *
     * IDs: 0 for ASTO, 1 for LP tokens, see `init()` below
     */
    mapping(uint256 => IERC20) private _token;
    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => StakingStorage) private _storage;
    mapping(uint256 => uint256) public totalStakedAmount;

    constructor(address controller) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        _grantRole(CONTROLLER_ROLE, controller);
        _pause();
    }

    /** ----------------------------------
     * ! Administration          | dao
     * ----------------------------------- */

    /**
     * @notice Withdraw tokens left in the contract to specified address
     * @param tokenId - ID of token to stake
     * @param recipient recipient of the transfer
     * @param amount Token amount to withdraw
     */
    function withdraw(
        uint256 tokenId,
        address recipient,
        uint256 amount
    ) external onlyRole(DAO_ROLE) {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (address(recipient) == address(0)) revert InvalidInput(WRONG_ADDRESS);
        if (_token[tokenId].balanceOf(address(this)) < amount) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransfer(recipient, amount);
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only DAO contract is allowed to call admin functions
     * @dev only controller is allowed to update permissions - to reduce amount of DAO votings
     *
     * @param astoToken ASTO Token contract address
     * @param lpToken LP Token contract address
     * @param astoStorage ASTO staking storage contract address
     * @param lpStorage LP staking storage contract address
     */
    function init(
        address dao,
        IERC20 astoToken,
        address astoStorage,
        IERC20 lpToken,
        address lpStorage,
        uint256 totalStakedAsto,
        uint256 totalStakedLp
    ) external onlyRole(CONTROLLER_ROLE) {
        if (!_initialized) {
            _token[0] = astoToken;
            _storage[0] = StakingStorage(astoStorage);
            _tokenName[0] = "ASTO";

            _token[1] = lpToken;
            _storage[1] = StakingStorage(lpStorage);
            _tokenName[1] = "ASTO/USDC Uniswap V2 LP";

            _clearRole(DAO_ROLE);
            _grantRole(DAO_ROLE, dao);

            totalStakedAmount[ASTO_TOKEN_ID] = totalStakedAsto;
            totalStakedAmount[LP_TOKEN_ID] = totalStakedLp;

            _initialized = true;
        }
    }

    /**
     * @dev Update the DAO contract address
     * @dev only controller is allowed to set new DAO contract
     */
    function setDao(address newDao) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(DAO_ROLE);
        _grantRole(DAO_ROLE, newDao);
    }

    /**
     * @dev Update the Controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(CONTROLLER_ROLE);
        _grantRole(CONTROLLER_ROLE, newController);
    }

    /**
     * @dev Pause the contract
     * @dev only controller is allowed to call this function
     */
    function pause() external onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @dev only controller is allowed to call this function
     */
    function unpause() external onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @notice Save user's stake
     *
     * @notice Staking is a process of locking your tokens in this contract.
     * @notice Details of the stake are to be stored and used for calculations
     * @notice what time your tokens are stay staked.
     *
     * @dev Prerequisite:
     * @dev - amount of tokens to stake should be approved by user.
     * @dev - this contract should have a `CONSUMER_ROLE` to call
     * @dev   the storage's `updateHistory()` function.
     *
     * @dev Depending on tokenId passed, it:
     * @dev 1. transfers tokens from user to this contract
     * @dev 2. calls an appropriate token storage and saves time and amount of stake.
     *
     * @dev Emit `UnStaked` event on success: with token name, user address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function stake(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (tokenId > 1) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);
        address user = msg.sender;
        uint256 tokenBalance = _token[tokenId].balanceOf(user);
        if (amount > tokenBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        _token[tokenId].safeTransferFrom(user, address(this), amount);

        uint256 lastStakeId = _storage[tokenId].getUserLastStakeId(user);
        uint256 stakeBalance = (_storage[tokenId].getStake(user, lastStakeId)).amount;
        uint256 newAmount = stakeBalance + amount;
        _storage[tokenId].updateHistory(user, newAmount);
        totalStakedAmount[tokenId] += amount;

        emit Staked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice Unstake user's stake
     *
     * @notice Unstaking is a process of getting back previously staked tokens.
     * @notice Users can unlock their tokens any time.
     *
     * @dev No prerequisites
     * @dev Users can unstake only their own, previously staked  tokens
     * @dev Emit `UnStaked` event on success: with token name, user address, timestamp, amount
     *
     * @param tokenId - ID of token to stake
     * @param amount - amount of tokens to stake
     */
    function unstake(uint256 tokenId, uint256 amount) external whenNotPaused {
        if (!_isContract(address(_token[tokenId]))) revert InvalidInput(WRONG_TOKEN);
        if (amount == 0) revert InvalidInput(WRONG_AMOUNT);

        address user = msg.sender;
        uint256 id = _storage[tokenId].getUserLastStakeId(user);
        if (id == 0) revert InvalidInput(NO_STAKES);
        uint256 userBalance = (_storage[tokenId].getStake(user, id)).amount;
        if (amount > userBalance) revert InvalidInput(INSUFFICIENT_BALANCE);

        uint256 newAmount = userBalance - amount;
        _storage[tokenId].updateHistory(user, newAmount);
        totalStakedAmount[tokenId] -= amount;

        _token[tokenId].safeTransfer(user, amount);

        emit UnStaked(_tokenName[tokenId], user, block.timestamp, amount);
    }

    /**
     * @notice Returns the total amount of tokens staked by all users
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return amount of tokens staked in the contract, uint256
     */
    function getTotalValueLocked(uint256 tokenId) external view returns (uint256) {
        return totalStakedAmount[tokenId];
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    /**
     * @notice Returns address of the token storage contract
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return address of the token storage contract
     */
    function getStorageAddress(uint256 tokenId) external view returns (address) {
        return address(_storage[tokenId]);
    }

    /**
     * @notice Returns address of the token contract
     *
     * @param tokenId ASTO - 0, LP - 1
     * @return address of the token contract
     */
    function getTokenAddress(uint256 tokenId) external view returns (address) {
        return address(_token[tokenId]);
    }

    /**
     * @notice Returns the staking history of user
     *
     * @param tokenId ASTO - 0, LP - 1
     * @param addr user wallet address
     * @param endTime until what time tokens were staked
     * @return sorted list of stakes, for each stake: { time, amount },
     *         starting with earliest
     */
    function getHistory(
        uint256 tokenId,
        address addr,
        uint256 endTime
    ) external view returns (Stake[] memory) {
        return _storage[tokenId].getHistory(addr, endTime);
    }
}