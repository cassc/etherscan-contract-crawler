// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import "forge-std/console2.sol";

contract Ufc277 is Ownable {
    using Counters for Counters.Counter;
    using Address for address payable;

    struct Pick {
        string name; 
        int odds;
        uint256 position;
    }
    
    Pick private pickOne;
    Pick private pickTwo;
    Pick private winner;
    Pick private loser;

    mapping(address => uint256) _depositsPickOne;
    uint256 private pickOneDepositTotal;
    Counters.Counter private pickOneBetterCount;

    mapping(address => uint256) _depositsPickTwo;
    uint256 private pickTwoDepositTotal;
    Counters.Counter private pickTwoBetterCount;

    event Deposited(address indexed payee, uint256 weiAmount, string name);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    constructor(string memory _pickOneName, int _pickOneOdds, string memory _pickTwoName, int _pickTwoOdds) {
        pickOne = Pick(_pickOneName, _pickOneOdds, 1);
        pickTwo = Pick(_pickTwoName,_pickTwoOdds, 2);
    }

    function getPick(uint256 pick) public view returns (Pick memory) {
        return pick == 1 ? pickOne : pickTwo;
    }

    function depositsOfPickOne(address payee) public view returns (uint256) {
        return _depositsPickOne[payee];
    }

    function depositsOfPickTwo(address payee) public view returns (uint256) {
        return _depositsPickTwo[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     *
     * Emits a {Deposited} event.
     */
    function depositPickOne() public payable virtual {
        uint256 amount = msg.value;
        if (_depositsPickOne[msg.sender] == 0) {
            pickOneBetterCount.increment();
        }
        _depositsPickOne[msg.sender] += amount;
        pickOneDepositTotal += amount;
        emit Deposited(msg.sender, amount, pickOne.name);
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     *
     * Emits a {Deposited} event.
     */
    function depositPickTwo() public payable virtual {
        uint256 amount = msg.value;
        if (_depositsPickTwo[msg.sender] == 0) {
            pickOneBetterCount.increment();
        }
        _depositsPickTwo[msg.sender] += amount;
        pickTwoDepositTotal += amount;
        emit Deposited(msg.sender, amount, pickOne.name);
    }


    function withdrawalAllowed() public view virtual returns (bool) {
        return winner.position > 0 ? true : false;
    }

    function setWinner(uint256 _winner) public onlyOwner {
        if (_winner == 1) {
            winner = pickOne;
            loser = pickTwo;
        } else {
            winner = pickTwo;
            loser = pickOne;
        }
    }

    function getWinnings() internal view returns (uint256) {
        uint256 winnings;
        uint256 betterCount;
        if (loser.position == 1) {
            winnings = pickOneDepositTotal;
            betterCount = pickTwoBetterCount.current();
        } else  {
            winnings = pickTwoDepositTotal;
            betterCount = pickOneBetterCount.current();
        }

        return winnings / betterCount;
    }

    function withdraw() public virtual {
        require(withdrawalAllowed(), "No withdrawals until winner is set");
        _withdraw(payable(msg.sender));
    }

    function _withdraw(address payable payee) internal virtual {
        uint256 payment;
        if (winner.position == 1) {
            payment = _depositsPickOne[payee];
            _depositsPickOne[payee] = 0;
        } else {
            payment = _depositsPickTwo[payee];
            _depositsPickTwo[payee] = 0;
        }

        payment += getWinnings();

        payee.sendValue(payment);
        emit Withdrawn(payee, payment);
    }
    
}