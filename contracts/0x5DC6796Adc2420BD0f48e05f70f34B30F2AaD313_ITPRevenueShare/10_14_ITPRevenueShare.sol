// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './RevenueShareBase.sol';
import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

contract ITPRevenueShare is RevenueShareBase {
    /**
     * @dev Locker account list
     */
    address[] public lockerList;

    /**
     * @dev Locker account indices
     */
    mapping(address /*account*/ => DataStructures.OptionalValue /*lockerIndex*/)
        public lockerIndexMap;

    /**
     * @notice Emitted when the locker status for the account is updated
     * @param account The account address
     * @param value The locker status flag
     */
    event SetLocker(address indexed account, bool indexed value);

    constructor(address _lockToken, uint256 _lockDuration) RevenueShareBase(_lockDuration) {
        lockToken = IERC20(_lockToken);
        rewardTokens.push(_lockToken);
        rewardData[_lockToken].lastUpdateTime = block.timestamp;
        rewardData[_lockToken].periodFinish = block.timestamp;
    }

    /**
     * @dev Modifier to check if the caller is a registered locker
     */
    modifier onlyLocker() {
        require(isLocker(msg.sender), 'Not a locker');
        _;
    }

    /**
     * @dev Add rewards token to the list
     * @param _rewardsToken is the reward token address
     */
    function addReward(address _rewardsToken) external override onlyOwner {
        require(
            rewardData[_rewardsToken].lastUpdateTime == 0,
            'This token already exists as a reward token'
        );

        require(
            rewardTokens.length < Constants.LIST_SIZE_LIMIT_DEFAULT,
            'Reward token list: size limit exceeded'
        );

        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp;
    }

    /**
     * @dev lock `lockToken` tokens to receive rewards in USDC and USDT
     * 50% can be from a farm or just a simple lock from the user
     * @param _amount is the number of `lockToken` tokens
     */
    function lock(uint256 _amount) external whenNotPaused {
        _lock(_amount, msg.sender);
    }

    /**
     * @dev lock `lockToken` tokens to receive rewards in USDC and USDT
     * 50% can be from a farm or just a simple lock from the user
     * @param _amount is the number of `lockToken` tokens
     * @param _onBehalfOf is the address who sent the _amount of tokens for locking
     */
    function lock(uint256 _amount, address _onBehalfOf) external whenNotPaused onlyLocker {
        _lock(_amount, _onBehalfOf);
    }

    /**
     * @notice Updates the locker status for the account
     * @param _account The account address
     * @param _value The locker status flag
     */
    function setLocker(address _account, bool _value) external onlyOwner {
        DataStructures.uniqueAddressListUpdate(
            lockerList,
            lockerIndexMap,
            _account,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetLocker(_account, _value);
    }

    /**
     * @notice Getter of registered locker count
     * @return Registered locker count
     */
    function lockerCount() external view returns (uint256) {
        return lockerList.length;
    }

    /**
     * @notice Getter of the complete list of registered lockers
     * @return The complete list of registered lockers
     */
    function fullLockerList() external view returns (address[] memory) {
        return lockerList;
    }

    /**
     * @notice Getter of the locker status by the account address
     * @param _account The account address
     * @return The locker status
     */
    function isLocker(address _account) public view returns (bool) {
        return lockerIndexMap[_account].isSet;
    }

    /**
     * @dev return unseen amount of tokens
     * @param _token is the provided token address
     * @param _balance is the provided current balance for the token
     */
    function _unseen(
        address _token,
        uint256 _balance
    ) internal view override returns (uint256 unseen) {
        unseen = IERC20(_token).balanceOf(address(this)) - _balance;
        if (_token == address(lockToken)) {
            unseen -= lockedSupply;
        }
    }
}