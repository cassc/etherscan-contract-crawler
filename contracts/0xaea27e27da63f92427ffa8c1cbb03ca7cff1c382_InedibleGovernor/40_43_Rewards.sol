// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "./interfaces/IERC20.sol";

contract Rewards {
    // Allowed to withdraw leftover tokens after 3 months.
    address public dao;
    // The inedible token.
    IVotes private inedible;

    struct Payment {
        uint128 timePoint;
        uint128 amount;
    }

    mapping(address => Payment) public launches;
    mapping(address => mapping(address => bool)) public claimed;

    event NewRewards(address token, uint256 amount, uint256 timestamp);
    event ClaimedReward(address indexed user, address token, uint256 amount);

    // Just used for setting DAO to manage funds within here.
    constructor(address _dao, address _inedible) {
        dao = _dao;
        inedible = IVotes(_inedible);
    }

    /**
     * @dev Called by a Uni V2 pair when launching a token to pay fees.
     * @param _token The address of the token being launched.
     * @param _amount The amount of tokens being paid as fees.
     **/
    function payFee(address _token, uint256 _amount) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        launches[_token] = Payment(uint128(block.timestamp), uint128(_amount));
        emit NewRewards(_token, _amount, block.timestamp);
    }

    /**
     * @dev User calls here to claim rewards from a token launch. Sends a user their share of rewards.
     * @param _user Address of the user to claim rewards for.
     * @param _tokens An array of tokens to claim rewards from.
     **/
    function claimRewards(address _user, address[] memory _tokens) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(!claimed[_user][_tokens[i]], "Reward already claimed.");
            claimed[_user][_tokens[i]] = true;

            Payment memory payment = launches[_tokens[i]];
            uint256 launchTime = uint256(payment.timePoint);

            (uint256 balance, uint256 supply) = inedibleCheck(
                _user,
                launchTime
            );
            uint256 owed = (uint256(payment.amount) * balance) / supply; // todo: I feel like this can overflow

            IERC20(_tokens[i]).transfer(_user, owed);
            emit ClaimedReward(_user, _tokens[i], owed);
        }
    }

    /**
     * @dev Used by the frontend to check on rewards for the user. May need multiple calls.
     * @param _user The address to check rewards for.
     * @param _tokens An array of tokens to check user rewards for.
     **/
    function viewRewards(
        address _user,
        address[] memory _tokens
    ) external view returns (uint256[] memory owed) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (claimed[_user][_tokens[i]]) {
                continue;
            }

            Payment memory payment = launches[_tokens[i]];
            uint256 timePoint = uint256(payment.timePoint);

            (uint256 balance, uint256 supply) = inedibleCheck(_user, timePoint);
            uint256 tokenOwed = (uint256(payment.amount) * balance) / supply; // todo: I feel like this can overflow
            owed[i] = tokenOwed;
        }
    }

    /**
     * @dev Check user balance and total supply at a block. Subtracts address(0) and burn address from total supply.
     * @param _user Address of the user to check the balance of.
     * @param _timePoint The timestamp we're checking balance for.
     **/
    function inedibleCheck(
        address _user,
        uint256 _timePoint
    ) public view returns (uint256 _balance, uint256 _totalSupply) {
        _balance = inedible.getPastVotes(_user, _timePoint);
        uint256 burntOne = inedible.getPastVotes(address(0), _timePoint);
        uint256 burntTwo = inedible.getPastVotes(
            0x000000000000000000000000000000000000dEaD,
            _timePoint
        );
        _totalSupply =
            inedible.getPastTotalSupply(_timePoint) -
            burntOne -
            burntTwo;
    }

    /**
     * @dev Allow the DAO to withdraw tokens if it's been over 90 days since launch.
     *      Tokens may be stuck if they're given to an LP, or not worth the gas to withdraw for small holders,
     *      so we need a way to make sure they're not lost without quite letting the DAO take whatever.
     * @param _token The token to withdraw from the rewards contract.
     * @param _to The address to send tokens to.
     * @param _amount The amount of tokens to send.
     **/
    function daoWithdraw(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        require(msg.sender == dao, "Only DAO may call this function.");

        Payment memory payment = launches[_token];
        uint256 timePoint = uint256(payment.timePoint);

        // 7776000 is hardcoded to result in ~90 days in seconds. Don't want the DAO to be able to withdraw immediately.
        require(
            block.timestamp >= timePoint + 7776000,
            "Too early to withdraw fees"
        );
        IERC20(_token).transfer(_to, _amount);
    }
}