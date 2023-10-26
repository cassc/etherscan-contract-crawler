// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Vester is a contract to convert esToken to token.
 *
 */
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IesToken.sol";
import "./interfaces/IBoost.sol";

contract Vester is OwnableUpgradeable {
    IesToken public esToken;
    IesToken public token;
    IBoost public boost;

    uint256 public constant EXIT_CYCLE = 60 days;
    mapping(address => uint256) public time2fullRedemption;
    mapping(address => uint256) public unstakeRate;
    mapping(address => uint256) public lastWithdrawTime;

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event Restake(address indexed user, uint256 amount, uint256 time);
    event StakeToken(address indexed user, uint256 amount, uint256 time);
    event UnstakeToken(address indexed user, uint256 amount, uint256 time);
    event WithdrawToken(address indexed user, uint256 amount, uint256 time);

    function initialize() public initializer {
        __Ownable_init();
    }

    /*******************************************/
    /****************** VIEWS ******************/
    /*******************************************/

    function getClaimAbleToken(address user) public view returns (uint256 amount) {
        if (time2fullRedemption[user] > lastWithdrawTime[user]) {
            amount = block.timestamp > time2fullRedemption[user]
                ? unstakeRate[user] * (time2fullRedemption[user] - lastWithdrawTime[user])
                : unstakeRate[user] * (block.timestamp - lastWithdrawTime[user]);
        }
    }

    function getReservedTokenForVesting(address user) public view returns (uint256 amount) {
        if (time2fullRedemption[user] > block.timestamp) {
            amount = unstakeRate[user] * (time2fullRedemption[user] - block.timestamp);
        }
    }

    /****************************************************************/
    /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
    /****************************************************************/

    function stake(uint256 amount) external {
        token.burn(msg.sender, amount);
        esToken.mint(msg.sender, amount);
        emit StakeToken(msg.sender, amount, block.timestamp);
    }

    function unstake(uint256 amount) external {
        (uint256 lockedAmount, uint256 unLockTime, , ) = boost.userLockStatus(msg.sender);

        if (block.timestamp < unLockTime) {
            // VT_IVA: insufficient vest amount
            require(esToken.balanceOf(msg.sender) >= lockedAmount + amount, "VT_IVA");
        }

        esToken.burn(msg.sender, amount);
        withdraw(msg.sender);
        uint256 total = amount;
        if (time2fullRedemption[msg.sender] > block.timestamp) {
            total += unstakeRate[msg.sender] * (time2fullRedemption[msg.sender] - block.timestamp);
        }
        unstakeRate[msg.sender] = total / EXIT_CYCLE;
        time2fullRedemption[msg.sender] = block.timestamp + EXIT_CYCLE;

        emit UnstakeToken(msg.sender, amount, block.timestamp);
    }

    function withdraw(address user) public {
        uint256 amount = getClaimAbleToken(user);
        if (amount > 0) {
            token.mint(user, amount);
        }
        lastWithdrawTime[user] = block.timestamp;

        emit WithdrawToken(user, amount, block.timestamp);
    }

    function reStake() external {
        uint256 amount = getReservedTokenForVesting(msg.sender) + getClaimAbleToken(msg.sender);
        esToken.mint(msg.sender, amount);
        unstakeRate[msg.sender] = 0;
        time2fullRedemption[msg.sender] = 0;

        emit Restake(msg.sender, amount, block.timestamp);
    }

    /****************************************************************/
    /*********************** OWNABLE FUNCTIONS  *********************/
    /****************************************************************/

    function setTokenAddress(address _esToken, address _token, address _boost) external onlyOwner {
        esToken = IesToken(_esToken);
        token = IesToken(_token);
        boost = IBoost(_boost);
    }
}