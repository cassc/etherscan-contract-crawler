// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Tuesday is Context, AccessControl {
    using SafeMath for uint256;
    using Address for address;

    bytes32 public constant SETTLEMENT_ROLE = keccak256("SETTLEMENT_ROLE");
    bytes32 public constant SET_ENV_ROLE = keccak256("SET_ENV_ROLE");
    address public USDT;

    struct accountInfo {
        uint256 currentReward;
        uint256 currentDepositAmount;
        uint256 totalAccumulationReward;
        uint256 totalRecommenderReward;
        uint256 lastRoundsTime;
        bool inList;
    }

    uint256[10] public recommenderRewardRates = [4e7, 2e7, 1e7, 1e7, 1e7, 1e7, 1e7, 1e7, 1e7, 1e7];
    uint256 public rate = 1e8;
    uint256 private oneDay = 1 days;
    uint256 private perSettle;

    uint256 public fee = 1e18;
    uint256 public feeRate = 1e6;
    uint256 public rewardRate = 8e5;
    uint256 public minDeposit = 1e18;
    uint256 public minRewardDeposit = 5e20;

    address[] public accountList;
    mapping(address => accountInfo) public accountInfos;
    mapping(address => address) public recommender;
    mapping(address => uint256) public recommenderNumber;
    mapping(address => address[]) public recommenderAddress;


    constructor (address _usdt) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, 0x5e5a5169769637B88249Fae59D4d5ef60c78370b);
        _grantRole(SETTLEMENT_ROLE, 0x8C61f6CFf48EF259373347880EC48f54618637bD);

        USDT = _usdt;
        perSettle = 200;
    }

    function newRecommender(address _recommender) public {
        require(recommender[_msgSender()] == address(0), "already have recommender");
        require(_msgSender() != _recommender, "recommender not be yourself");
        require(recommender[_recommender] != _msgSender(), "recommender is recommender");
        require(!_recommender.isContract() && !_msgSender().isContract(), "address contract");
        addAccountInList(_recommender);
        addAccountInList(_msgSender());
        recommender[_msgSender()] = _recommender;
        recommenderNumber[_recommender]++;
        recommenderAddress[_recommender].push(_msgSender());
    }

    function deposit(uint256 amount) public {
        require(amount >= minDeposit, "token allowance insufficient");
        require(amount >= IERC20(USDT).allowance(_msgSender(), address(this)), "token allowance insufficient");
        addAccountInList(_msgSender());
        IERC20(USDT).transferFrom(_msgSender(), address(this), amount);
        accountInfos[_msgSender()].currentDepositAmount = accountInfos[_msgSender()].currentDepositAmount.add(amount);
    }

    function withdraw(address account, uint256 amount) public onlyRole(SETTLEMENT_ROLE) {
        require(accountInfos[account].currentDepositAmount >= amount, "deposit amount insufficient");
        accountInfos[account].currentDepositAmount = accountInfos[account].currentDepositAmount.sub(amount);

        uint256 withdrawAmount = 0;
        if (amount > fee) {
            withdrawAmount = amount.sub(amount.mul(feeRate).div(rate)).sub(fee);
        }
        require(IERC20(USDT).balanceOf(address(this)) >= withdrawAmount, "contract balance insufficient");

        if (withdrawAmount > 0) {
            IERC20(USDT).transfer(account, withdrawAmount);
        }
    }

    function reward(address account) public onlyRole(SETTLEMENT_ROLE) {
        require(accountInfos[account].currentReward > 0, "account no reward");
        uint256 totalReward = accountInfos[account].currentReward;
        accountInfos[account].currentReward = 0;

        uint256 withdrawAmount = 0;
        if (totalReward > fee) {
            withdrawAmount = totalReward.sub(totalReward.mul(feeRate).div(rate)).sub(fee);
        }
        require(IERC20(USDT).balanceOf(address(this)) >= withdrawAmount, "contract balance insufficient");

        if (withdrawAmount > 0) {
            IERC20(USDT).transfer(account, withdrawAmount);
        }
    }

    function settlementReward() public onlyRole(SETTLEMENT_ROLE) {
        uint256 number = 0;
        for (uint256 i = 0; i < accountList.length; i++) {
            if (accountInfos[accountList[i]].currentDepositAmount == 0 || block.timestamp.sub(accountInfos[accountList[i]].lastRoundsTime) < oneDay) {
                continue;
            }

            uint256 thisReward = accountInfos[accountList[i]].currentDepositAmount.mul(rewardRate).div(rate);
            accountInfos[accountList[i]].currentReward = accountInfos[accountList[i]].currentReward.add(thisReward);
            accountInfos[accountList[i]].totalAccumulationReward = accountInfos[accountList[i]].totalAccumulationReward.add(thisReward);
            accountInfos[accountList[i]].lastRoundsTime = block.timestamp;

            if (accountInfos[accountList[i]].currentDepositAmount >= minRewardDeposit) {
                address recommenderAddress = recommender[accountList[i]];
                for (uint256 j = 0; j < recommenderRewardRates.length; j++) {
                    if (recommenderAddress == address(0)) {
                        break;
                    }
                    if (accountInfos[recommenderAddress].currentDepositAmount >= minRewardDeposit && checkAccount(recommenderAddress, j)) {
                        uint256 recommenderReward = thisReward.mul(recommenderRewardRates[j]).div(rate);
                        accountInfos[recommenderAddress].currentReward = accountInfos[recommenderAddress].currentReward.add(recommenderReward);
                        accountInfos[recommenderAddress].totalAccumulationReward = accountInfos[recommenderAddress].totalAccumulationReward.add(recommenderReward);
                        accountInfos[recommenderAddress].totalRecommenderReward = accountInfos[recommenderAddress].totalRecommenderReward.add(recommenderReward);
                    }
                    recommenderAddress = recommender[recommenderAddress];
                }
            }
            number++;
            if (number == perSettle) {
                break;
            }
        }
    }

    function exchange(address account, uint256 amount) external onlyRole(SETTLEMENT_ROLE) {
        require(accountInfos[account].currentDepositAmount >= amount, "deposit amount insufficient");
        accountInfos[account].currentDepositAmount = accountInfos[account].currentDepositAmount.sub(amount);
    }

    function checkAccount(address account, uint256 num) internal returns (bool) {
        uint256 newNum = 0;
        for (uint256 j = 0; j < recommenderAddress[account].length; j++) {
            if (accountInfos[recommenderAddress[account][j]].currentDepositAmount >= minRewardDeposit) {
                newNum ++;
            }
            if (newNum > num) {
                return true;
            }
        }
        return false;
    }

    function addAccountInList(address account) internal {
        if (!accountInfos[account].inList) {
            accountList.push(account);
            accountInfos[account].inList = true;
        }
    }

    function setFee(uint256 _fee) external onlyRole(SET_ENV_ROLE) {
        fee = _fee;
    }

    function setFeeRate(uint256 _feeRate) external onlyRole(SET_ENV_ROLE) {
        feeRate = _feeRate;
    }

    function setPerSettle(uint256 _newPerSettle) external onlyRole(SET_ENV_ROLE) {
        perSettle = _newPerSettle;
    }

    function setMinRewardDeposit(uint256 _minRewardDeposit) external onlyRole(SET_ENV_ROLE) {
        minRewardDeposit = _minRewardDeposit;
    }

    function removeLiquidity(address account, address token, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IERC20(token).balanceOf(address(this)) >= amount, "token balance not enough");
        IERC20(token).transfer(account, amount);
    }

    function removeLiquidityBNB(address payable account, uint256 amount) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance >= amount, "BNB balance not enough");
        account.transfer(amount);
    }

    receive() external payable {}
}