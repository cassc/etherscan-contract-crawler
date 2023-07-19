// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Rewards {
    using SafeERC20 for IERC20;
    // Allowed to withdraw leftover tokens after 3 months.
    address public dao;
    // The inedible token.
    IVotes private inedible;

    // token => timePoint => amount. TimePoint required because one token may do multiple airdrops.
    mapping(address => mapping(uint256 => uint256)) public launches;
    // user => token => timePoint => claimed
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public claimed;

    event NewRewards(address token, uint256 amount, uint256 timePoint);
    event ClaimedReward(
        address indexed user,
        address token,
        uint256 timePoint,
        uint256 amount
    );

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
        // fix for backrun in a same block
        require(launches[_token][block.number] == 0, "Already set");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        launches[_token][block.number] = _amount;
        emit NewRewards(_token, _amount, block.number);
    }

    /**
     * @dev User calls here to claim rewards from a token launch. Sends a user their share of rewards.
     * @param _user Address of the user to claim rewards for.
     * @param _tokens An array of tokens to claim rewards from.
     * @param _timePoints An array of timepoints the rewards were launched at.
     **/
    function claimRewards(
        address _user,
        address[] memory _tokens,
        uint[] memory _timePoints
    ) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(
                !claimed[_user][_tokens[i]][_timePoints[i]],
                "Reward already claimed."
            );

            // Vesting for airdrops is 30 days and 216000 in blocks.
            require(
                _timePoints[i] + 216000 < block.number,
                "Too early to claim rewards."
            );
            claimed[_user][_tokens[i]][_timePoints[i]] = true;

            uint256 amount = launches[_tokens[i]][_timePoints[i]];
            (uint256 balance, uint256 supply) = inedibleCheck(
                _user,
                _timePoints[i]
            );

            uint256 owed = (amount * balance) / supply;
            if (owed != 0) {
                IERC20(_tokens[i]).safeTransfer(_user, owed);
                emit ClaimedReward(_user, _tokens[i], _timePoints[i], owed);
            }
        }
    }

    /**
     * @dev Used by the frontend to check on rewards for the user. May need multiple calls.
     * @param _user The address to check rewards for.
     * @param _tokens An array of tokens to check user rewards for.
     **/
    function viewRewards(
        address _user,
        address[] memory _tokens,
        uint256[] memory _timePoints
    ) external view returns (uint256[] memory owed) {
        owed = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 amount = launches[_tokens[i]][_timePoints[i]];
            (uint256 balance, uint256 supply) = inedibleCheck(
                _user,
                _timePoints[i]
            );
            uint256 tokensOwed = (amount * balance) / supply;
            owed[i] = tokensOwed;
        }
    }

    /**
     * @dev Check user balance and total supply at a block. Subtracts address(0) and burn address from total supply.
     * @param _user Address of the user to check the balance of.
     * @param _timePoint The block number we're checking balance for.
     **/
    function inedibleCheck(
        address _user,
        uint256 _timePoint
    ) public view returns (uint256 _balance, uint256 _totalSupply) {
        _balance = inedible.getPastVotes(_user, _timePoint);
        _totalSupply = 888_888_888_888_888 ether;
    }

    /**
     * @dev Allow the DAO to withdraw tokens if it's been over 90 days since launch.
     *      Tokens may be stuck if they're given to an LP, or not worth the gas to withdraw for small holders,
     *      so we need a way to make sure they're not lost without quite letting the DAO take whatever.
     * @param _token The token to withdraw from the rewards contract.
     * @param _to The address to send tokens to.
     **/
    function daoWithdraw(
        address _token,
        uint _blockNumber,
        address _to
    ) external {
        require(msg.sender == dao, "Only DAO may call this function.");
        require(
            launches[_token][_blockNumber] > 0,
            "Incorrect launch details."
        );

        // 648000 is hardcoded to result in ~90 days in blocks. Don't want the DAO to be able to withdraw immediately.
        require(
            block.number >= _blockNumber + 648000,
            "Too early to withdraw fees"
        );
        // dao should not be able to withdraw same airdrop twice if there's a 2nd airdrop
        launches[_token][_blockNumber] = 0;
        IERC20 token = IERC20(_token);
        token.transfer(_to, token.balanceOf(address(this)));
    }
}