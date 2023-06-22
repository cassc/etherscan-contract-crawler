/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;
contract Reward  {
    // power by cash team https://t.me/ferc_cash
    uint256 periodNumber; //


    mapping(address => uint256) private newstId; //
    uint256 private profit; //
    mapping(address => uint256[]) private personHistory;//
    mapping(uint256 => uint256) private rewardHistoryTime;//
        mapping(uint256 => uint256[]) private rewardHistory;                     //
    mapping(address => mapping(uint256 => uint256[])) private SeveralIssues; //
    constructor () {
    }

    function doNext() public {

        for (uint i = 0; i < 5; i++) {
            rewardHistory[1].push(i);
        }
        rewardHistoryTime[1] = block.timestamp;
        periodNumber += 1;
    }

    //
    function doPer(uint256 aType, uint256 aAmount, uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) public {
        SeveralIssues[msg.sender][1] = [aType, aAmount, a, b, c, d, e, 0];
        newstId[msg.sender] = periodNumber;
        personHistory[msg.sender].push(periodNumber);
    }
    function doClaim() public {
        profit += 1 * 1 * 10 ** 18 / 100;
        SeveralIssues[msg.sender][1][7] = 1;
    }
}