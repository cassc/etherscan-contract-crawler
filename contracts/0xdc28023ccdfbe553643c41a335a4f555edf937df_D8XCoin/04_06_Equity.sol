// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC677Receiver } from "./IERC677Receiver.sol";
import { ID8XCoin } from "./ID8XCoin.sol";
import { ConcreteERC20 } from "./ConcreteERC20.sol";

/**
 * @title Equity contract manages the voting power
 * The voting power system is an adoption of Frankencoin
 */
abstract contract Equity is ID8XCoin, ConcreteERC20 {
    uint64 private totalVotesAnchorTime;
    uint192 private totalVotesAtAnchor;
    uint256 public immutable epochDurationSec; //604_800=7*24*60*60 = 7 days
    uint256 internal _totalLeftThroughPortal; //amount locked that left to other chains

    mapping(address => address) public delegates;
    mapping(address => uint64) private voteAnchor;

    event Delegation(address indexed from, address indexed to);

    /**
     * Constructor
     * @param _epochDurationInSeconds epoch duration in seconds
     */
    constructor(uint256 _epochDurationInSeconds) ConcreteERC20(18) {
        epochDurationSec = _epochDurationInSeconds;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (amount > 0) {
            uint256 roundingLoss = _adjustRecipientVoteAnchor(to, amount);
            _adjustTotalVotes(from, amount, roundingLoss);
        }
    }

    function universalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() external view override returns (uint256) {
        return _onChainTotalSupply();
    }

    function _onChainTotalSupply() internal view returns (uint256) {
        return _totalSupply - _totalLeftThroughPortal;
    }

    /**
     * External: Get the current epoch (block timestamp / epochDuration)
     */
    function epoch() external view returns (uint64) {
        return _epoch();
    }

    /**
     * Get the current epoch (block timestamp / epochDuration)
     */
    function _epoch() internal view returns (uint64) {
        return uint64(block.timestamp / epochDurationSec);
    }

    /**
     * @notice Decrease the total votes anchor when tokens lose their voting power due to being moved
     * @param from  sender
     * @param amount    amount to be sent
     * @param roundingLoss  amount of votes lost due to rounding errors
     */
    function _adjustTotalVotes(address from, uint256 amount, uint256 roundingLoss) internal {
        uint256 lostVotes = from == address(0x0) ? 0 : (_epoch() - voteAnchor[from]) * amount;
        totalVotesAtAnchor = uint192(totalVotes() - roundingLoss - lostVotes);
        totalVotesAnchorTime = _epoch();
    }

    /**
     * @notice the vote anchor of the recipient is moved forward such that the number of calculated
     * votes does not change despite the higher balance.
     * @notice slither warning disabled weak-prng
     * @param to        receiver address
     * @param amount    amount to be received
     * @return the number of votes lost due to rounding errors
     */
    function _adjustRecipientVoteAnchor(address to, uint256 amount) internal returns (uint256) {
        if (to != address(0x0)) {
            uint256 recipientVotes = votes(to); // for example 21 if 7 shares were held for 3 epochs
            uint256 newbalance = balanceOf(to) + amount; // for example 11 if 4 shares are added
            voteAnchor[to] = _epoch() - uint64(recipientVotes / newbalance); // new example anchor is only 21 / 11 = 1 epochs in the past
            // slither-disable-next-line weak-prng
            return recipientVotes % newbalance; // we have lost 21 % 11 = 10 votes
        } else {
            // optimization for burn, vote anchor of null address does not matter
            return 0;
        }
    }

    /**
     * Get the votes of an address (address voting power)
     * @param holder address for which number of votes are returned
     */
    function votes(address holder) public view returns (uint256) {
        return balanceOf(holder) * (_epoch() - voteAnchor[holder]);
    }

    /**
     * @notice Get total votes
     */
    function totalVotes() public view returns (uint256) {
        return totalVotesAtAnchor + _onChainTotalSupply() * (_epoch() - totalVotesAnchorTime);
    }

    /**
     * @notice Get whether the sender plus potential delegates have sufficient voting power
     * to propose an initiative that requires a minimum amount of votes to be proposed
     * @param sender address of sender
     * @param _percentageBps minimum amount of votes required (in basis points)
     * @param helpers addresses of delegates
     */
    function isQualified(
        address sender,
        uint16 _percentageBps,
        address[] calldata helpers
    ) external view returns (bool) {
        uint256 _votes = votes(sender);
        for (uint i = 0; i < helpers.length; i++) {
            address current = helpers[i];
            require(current != sender, "dlgt is sndr");
            require(_canVoteFor(sender, current), "wrong dlgt");
            for (uint j = i + 1; j < helpers.length; j++) {
                require(current != helpers[j], "dlgt added twice");
            }
            _votes += votes(current);
        }
        return _votes * 10000 >= _percentageBps * totalVotes();
    }

    /**
     * @notice Delegate votes to a delegate
     * @param delegate address of delegate
     */
    function delegateVoteTo(address delegate) external override {
        delegates[msg.sender] = delegate;
        if (delegate == msg.sender) {
            delete delegates[msg.sender];
        }
        emit Delegation(msg.sender, delegate);
    }

    /**
     * Check if an address is the delegate of another address
     * @param delegate address to which votes have been delegated to
     * @param owner address that delegated the votes
     */
    function canVoteFor(address delegate, address owner) external view override returns (bool) {
        return _canVoteFor(delegate, owner);
    }

    function _canVoteFor(address delegate, address owner) internal view returns (bool) {
        if (owner == delegate) {
            return true;
        } else if (owner == address(0x0)) {
            return false;
        } else {
            return _canVoteFor(delegate, delegates[owner]);
        }
    }
}