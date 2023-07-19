// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IETHStaking.sol";

contract ETHStaking is IETHStaking, Ownable, ReentrancyGuard {
    /*********** VARIABLES ***********/
    uint256 public override totalValueLocked;

    uint256 public override apy;

    uint256 public override correctionFactor;

    /*********** MAPPING ***********/
    // User info
    // user address -> stakeNum -> UserInfo struct
    mapping(address => mapping(uint256 => UserInfo)) public override userInfo;

    // Stake Nums - How many stakes a user has
    mapping(address => uint256) public override stakeNums;
    mapping(address => uint256) private __stakeNums;

    /*********** CONSTRUCTOR ***********/
    constructor(uint256 _apy, uint256 _correctionFactor) {
        apy = _apy; // 0.6% apy -> 0.6 * 1e18
        correctionFactor = _correctionFactor; // 0.6% apy -> 1e21
    }

    /*********** FALLBACK FUNCTIONS ***********/
    receive() external payable {}

    /*********** GETTERS ***********/
    function balanceOf(address _account, uint256 _stakeNum)
        public
        view
        override
        returns (uint256)
    {
        return userInfo[_account][_stakeNum].amount;
    }

    function stakeExists(address _beneficiary, uint256 _stakeNum)
        public
        view
        override
        returns (bool)
    {
        return balanceOf(_beneficiary, _stakeNum) != 0 ? true : false;
    }

    function calculateReward(address _beneficiary, uint256 _stakeNum)
        public
        view
        override
        returns (uint256 _reward)
    {
        UserInfo memory _user = userInfo[_beneficiary][_stakeNum];
        _stakeExists(_beneficiary, _stakeNum);

        if (totalValueLocked == 0) return 0;

        uint256 _secs = _calculateSecs(block.timestamp, _user.lastUpdated);
        _reward = (_secs * _user.amount * apy) / (3153600 * correctionFactor);
    }

    function contractBalance() public view override returns (uint256) {
        return address(this).balance;
    }

    /*********** ACTIONS ***********/

    function changeAPY(uint256 _apy, uint256 _correctionFactor)
        public
        override
        onlyOwner
    {
        require(_apy != 0, "apy cannot be zero");
        apy = _apy; // 0.6% apy -> 0.6 * 1e18
        correctionFactor = _correctionFactor; // 0.6% apy -> 1e21
        emit APYChanged(_apy, _correctionFactor);
    }

    function withdrawContractFunds(uint256 _amount) public override onlyOwner {
        require(
            _amount <= address(this).balance,
            "amount exceeds contract balance"
        );
        _handleETHTransfer(owner(), _amount);
        emit OwnerWithdrawFunds(owner(), _amount);
    }

    function destructContract() public override onlyOwner {
        selfdestruct(payable(owner()));
    }

    function stake() public payable override {
        uint256 _amount = msg.value;
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

        emit Staked(_msgSender(), _amount, _stakeNum);
    }

    function unstake(uint256 _stakeNum) public override {
        _stakeExists(_msgSender(), _stakeNum);

        uint256 _amount = balanceOf(_msgSender(), _stakeNum);
        uint256 _reward = calculateReward(_msgSender(), _stakeNum);

        _updateUserInfo(
            ActionType.Unstake,
            _msgSender(),
            _stakeNum,
            _amount,
            _reward
        );

        _handleETHTransfer(_msgSender(), (_amount + _reward));

        emit Unstaked(_msgSender(), _amount, _reward, _stakeNum);
    }

    /*********** INTERNAL FUNCTIONS ***********/
    function _calculateSecs(uint256 _to, uint256 _from)
        internal
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    function _stakeExists(address _beneficiary, uint256 _stakeNum)
        internal
        view
    {
        UserInfo memory _user = userInfo[_beneficiary][_stakeNum];
        require(_stakeNum != 0, "StakeNum does not exist");
        require(stakeNums[_beneficiary] != 0, "User does not have any stake");
        require(_user.amount > 0, "User staked amount cannot be 0");
    }

    function _handleETHTransfer(address _beneficiary, uint256 _amount)
        internal
    {
        payable(_beneficiary).transfer(_amount);
        emit ETHTransferred(_beneficiary, _amount);
    }

    function _updateUserInfo(
        ActionType _actionType,
        address _beneficiary,
        uint256 _stakeNum,
        uint256 _amount,
        uint256 _reward
    ) internal nonReentrant {
        UserInfo storage user = userInfo[_beneficiary][_stakeNum];

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