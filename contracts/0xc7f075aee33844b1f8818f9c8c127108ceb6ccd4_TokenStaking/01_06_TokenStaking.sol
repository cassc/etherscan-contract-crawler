// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITokenStaking.sol";

/**
 * @dev Implementation of the {ITokenStaking} interface.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 *
 * Note: Deployer will be the {owner}.
 */
contract TokenStaking is ITokenStaking, Ownable, ReentrancyGuard {
    /**
     * @dev See {ITokenStaking-totalValueLocked}.
     */
    uint256 public override totalValueLocked;

    /**
     * @dev See {ITokenStaking-apy}.
     */
    uint256 public override apy;

    // Token Instance
    IERC20 public token;

    /**
     * @dev See {ITokenStaking-userInfos}.
     *
     * user address -> stakeNum -> UserInfo struct
     *
     */
    mapping(address => mapping(uint256 => UserInfo)) public override userInfos;

    /**
     * @dev See {ITokenStaking-stakeNums}.
     *
     * user address -> stakeNum
     *
     */
    mapping(address => uint256) public override stakeNums;

    // private stakeNum to manage multiple stakes of a person.
    mapping(address => uint256) private __stakeNums;

    /**
     * @dev Sets the values for {token} and {apy}.
     *
     * {apy} changes with {changeAPY}.
     *
     */
    constructor(address _tokenAddress, uint256 _apy) {
        token = IERC20(_tokenAddress);
        apy = _apy; // 12% apy -> 12 * 1e18
    }

    /**
     * @dev Fallback function.
     */
    receive() external payable {
        emit RecieveTriggered(_msgSender(), msg.value);
    }

    /**
     * @dev See {ITokenStaking-balanceOf}.
     */
    function balanceOf(address _account, uint256 _stakeNum)
        public
        view
        override
        returns (uint256)
    {
        return userInfos[_account][_stakeNum].amount;
    }

    /**
     * @dev See {ITokenStaking-stakeExists}.
     */
    function stakeExists(address _beneficiary, uint256 _stakeNum)
        public
        view
        override
        returns (bool)
    {
        return balanceOf(_beneficiary, _stakeNum) != 0 ? true : false;
    }

    /**
     * @dev See {ITokenStaking-calculateReward}.
     */
    function calculateReward(address _beneficiary, uint256 _stakeNum)
        public
        view
        override
        returns (uint256 _reward)
    {
        UserInfo memory _user = userInfos[_beneficiary][_stakeNum];
        if (totalValueLocked == 0) return 0;

        uint256 _secs = _calculateSecs(block.timestamp, _user.lastUpdated);
        _reward = (_secs * _user.amount * apy) / (31536000 * 1e20);
    }

    /**
     * @dev See {ITokenStaking-contractTokenBalance}.
     */
    function contractTokenBalance() public view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev See {ITokenStaking-stake}.
     *
     * Emits a {Staked} event indicating the stake details.
     *
     * Requirements:
     *
     * - `_amount` should be zero.
     * - stake should not already exist.
     *
     */
    function stake(uint256 _amount) public override {
        require(_amount > 0, "stake amount not valid");

        uint256 _stakeNums = __stakeNums[_msgSender()];
        uint256 _stakeNum;

        if (_stakeNums == 0) {
            // user is coming for first time
            _stakeNum = 1;
        } else {
            // add 1 in his previous stake
            _stakeNum = _stakeNums + 1;
        }

        require(!stakeExists(_msgSender(), _stakeNum), "stake already exists");

        _updateUserInfo(ActionType.Stake, _msgSender(), _stakeNum, _amount, 0);

        // Transfer the tokens to this contract
        token.transferFrom(address(_msgSender()), address(this), _amount);

        emit Staked(_msgSender(), _amount, _stakeNum);
    }

    /**
     * @dev See {ITokenStaking-unstake}.
     *
     * Emits a {Unstaked} event indicating the unstake details.
     *
     * Requirements:
     *
     * - `_stakeNum` should be valid.
     * - reward should exist for the `_stakeNum`.
     *
     */
    function unstake(uint256 _stakeNum) public override {
        _stakeExists(_msgSender(), _stakeNum);

        uint256 _amount = balanceOf(_msgSender(), _stakeNum);
        uint256 _reward = calculateReward(_msgSender(), _stakeNum);

        require(_reward != 0, "reward cannot be zero");

        _updateUserInfo(
            ActionType.Unstake,
            _msgSender(),
            _stakeNum,
            _amount,
            _reward
        );

        // Transfer staked amount and reward to user
        token.transfer(_msgSender(), _amount + _reward);

        emit Unstaked(_msgSender(), _amount, _reward, _stakeNum);
    }

    /**
     * @dev See {ITokenStaking-changeAPY}.
     *
     * Emits a {APYChanged} event indicating the {apy} is changed.
     *
     * Requirements:
     *
     * - `_apy` should not be zero.
     * - caller must be {owner}.
     *
     */
    function changeAPY(uint256 _apy) public override onlyOwner {
        require(_apy != 0, "apy cannot be zero");
        apy = _apy; // 12% apy -> 12 * 1e18
        emit APYChanged(_apy);
    }

    /**
     * @dev See {ITokenStaking-withdrawContractFunds}.
     *
     * Emits a {OwnerWithdrawFunds} event indicating the withdrawal of all funds.
     *
     * Requirements:
     *
     * - `_amount` should be less than or equal to contract balance.
     * - caller must be {owner}.
     *
     */
    function withdrawContractFunds(uint256 _amount) public override onlyOwner {
        require(
            _amount <= contractTokenBalance(),
            "amount exceeds contract balance"
        );
        token.transfer(_msgSender(), _amount);
        emit OwnerWithdrawFunds(_msgSender(), _amount);
    }

    /**
     * @dev See {ITokenStaking-destructContract}.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     *
     */
    function destructContract() public override onlyOwner {
        token.transfer(_msgSender(), token.balanceOf(address(this)));
        selfdestruct(payable(_msgSender()));
    }

    /**
     * @dev Internal function to calculate number of seconds.
     */
    function _calculateSecs(uint256 _to, uint256 _from)
        internal
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    /**
     * @dev Internal function to determine if stake exists.
     *
     * Requirements:
     *
     * - `_stakeNum` cannot be zero.
     * - user must have a stake.
     * - user amount cannot be zero.
     *
     */
    function _stakeExists(address _beneficiary, uint256 _stakeNum)
        internal
        view
    {
        UserInfo memory _user = userInfos[_beneficiary][_stakeNum];
        require(_stakeNum != 0, "StakeNum does not exist");
        require(stakeNums[_beneficiary] != 0, "User does not have any stake");
        require(_user.amount > 0, "User staked amount cannot be 0");
    }

    /**
     * @dev Internal function to update user info.
     *
     * Requirements:
     *
     * - caller cannot re-enter a transaction.
     *
     */
    function _updateUserInfo(
        ActionType _actionType,
        address _beneficiary,
        uint256 _stakeNum,
        uint256 _amount,
        uint256 _reward
    ) internal nonReentrant {
        UserInfo storage user = userInfos[_beneficiary][_stakeNum];

        user.lastUpdated = block.timestamp;

        if (_actionType == ActionType.Stake) {
            stakeNums[_beneficiary] = _stakeNum;
            __stakeNums[_beneficiary] = _stakeNum;
            totalValueLocked = totalValueLocked + _amount;
            user.amount = _amount;
            user.rewardPaid = 0;
        }

        if (_actionType == ActionType.Unstake) {
            stakeNums[_beneficiary] = stakeNums[_beneficiary] - 1;
            totalValueLocked = totalValueLocked - _amount;
            user.amount = 0;
            user.rewardPaid = _reward;
        }
    }
}