// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MV_SimpleETHRaise is Ownable {
    struct PledgeInfo {
        uint256 pledge;
        bool claimed;
    }

    uint256 public totalPledge;
    uint256 public tokensPerETH;
    IERC20 public rewardToken;

    bool public endSale;
    bool public success;
    uint256 public hardcap;

    mapping(address => PledgeInfo) public user;

    uint256 public minDeposit = 0.5 ether;
    uint256 public maxDeposit = 10 ether;

    event Pledge(address indexed user, uint256 amount);
    event ClaimToken(address indexed user, uint256 amount);
    event Claim(uint256 amount);
    event SaleEnded(bool status);

    constructor(uint256 hc) {
        hardcap = hc;
    }

    function pledge() external payable {
        require(!endSale, "Sale ended");
        uint256 amount = msg.value;
        PledgeInfo storage pi = user[msg.sender];
        if (pi.pledge == 0) require(amount >= minDeposit, "Not enough");
        pi.pledge += amount;
        totalPledge += amount;
        require(totalPledge <= hardcap, "Reached!");
        emit Pledge(msg.sender, amount);
    }

    function getRaiseFunds() external onlyOwner {
        require(success, "Not successful yet");
        uint256 current = address(this).balance;
        require(current > 0, "Not enough funds");
        (bool succ, ) = payable(owner()).call{value: current}("");
        require(succ, "Claim Failed");
        emit Claim(current);
    }

    function endTheSale(bool _success) external onlyOwner {
        require(!endSale, "ONCE");
        endSale = true;
        success = _success;
        emit SaleEnded(true);
    }

    function extractOtherFunds(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function claim() external {
        require(endSale && success && tokensPerETH > 0, "NOT YET");
        PledgeInfo storage pi = user[msg.sender];
        require(!pi.claimed && pi.pledge > 0, "DONE");
        pi.claimed = true;
        uint256 amountToClaim = tokensPerETH * pi.pledge;
        amountToClaim = amountToClaim / 1 ether;
        rewardToken.transfer(msg.sender, amountToClaim);
        emit ClaimToken(msg.sender, amountToClaim);
    }

    /// @notice set reward token info
    /// @param _token the new token address
    /// @param _tokensPerEth the amount of tokens to be given out to the user. This amount need to be in ether so it makes sense and mathwise wont fuck up anything.
    function setRewardToken(
        address _token,
        uint256 _tokensPerEth
    ) external onlyOwner {
        rewardToken = IERC20(_token);
        tokensPerETH = _tokensPerEth;
    }

    function getRefund() external {
        require(endSale && !success, "Not Done");
        PledgeInfo storage pi = user[msg.sender];
        require(!pi.claimed && pi.pledge > 0, "Already claimed");
        pi.claimed = true;
        (bool succ, ) = payable(msg.sender).call{value: pi.pledge}("");
        require(succ, "Failed TX");
    }
}