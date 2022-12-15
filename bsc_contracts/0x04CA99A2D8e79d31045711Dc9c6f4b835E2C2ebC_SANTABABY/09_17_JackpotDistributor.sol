pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeMathInt.sol";
import "./SafeMathUint.sol";

contract JackpotDistributor is Ownable{
    using SafeMath for uint256;
	using SafeMathUint for uint256;
	using SafeMathInt for int256;

    address public rewardToken;

    address public SBABY;

    bool public minBuyEnforced=false;
    uint256 public minBuy;
    address[] public buyersList;
    mapping(address=>bool) buyerExists;

    bool public jackpotStarted = false;
    uint public jackpotStartTime;
    uint public timeInterval = 24 hours;
    uint public minHoldTime = 12 hours;

    event JackpotStarted(uint JackpotStartTime);
    event JackpotSent(address to, uint256 amount);


    constructor(address _SBABY, address _rewardToken)public{
        SBABY=_SBABY;
        rewardToken = _rewardToken;
    }

    function startJackpot()external onlyOwner{
        require(!jackpotStarted,"Jackpot already started");
        jackpotStarted = true;
        jackpotStartTime = now;
    }

    function shouldDistributeReward()private view returns(bool){
        require(jackpotStarted,"Jackpot has not started");
        return now-jackpotStartTime>=timeInterval;
    }

    function addBuyer(address _buyer,uint256 amount)external{
        require(msg.sender == SBABY,"Only $SBABY contract can do this");
        if(minBuyEnforced){
            if(amount >= minBuy && (now - jackpotStartTime) >= minHoldTime && !buyerExists[_buyer]){
                buyersList.push(_buyer);
            }else{
                return;
            }
        }else if(now - jackpotStartTime >= minHoldTime){
            buyersList.push(_buyer);
        }
    }

    function triggerJackpot()external{
        require(shouldDistributeReward(),"Jackpot cannot be triggered yet");
        payoutRewards();
        removeBuyers();
        jackpotStartTime = jackpotStartTime + 24 hours;
    }

    function removeBuyers()private{
        for(uint i = 0; i < buyersList.length ; i++){
            buyerExists[buyersList[i]]=false;
        }
        delete buyersList;  
    }

    function payoutRewards() private {
        // get a pseudo random winner
        uint256 randomNum = random(
            1,
            buyersList.length,
            IERC20(rewardToken).balanceOf(address(this)) +
                IERC20(rewardToken).balanceOf(address(0xdead))+
                IERC20(rewardToken).balanceOf(address(msg.sender))
        );
        address winner = buyersList[buyersList.length - randomNum];
        uint256 winnings = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).transfer(winner, winnings);
        emit JackpotSent(winner, winnings);
    }

    function random(
        uint256 from,
        uint256 to,
        uint256 salty
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        salty
                )
            )
        );
        return (seed % (to - from)) + from;
    }

    function setMinHoldTime(uint256 _minHoldTime)external onlyOwner{
        minHoldTime = _minHoldTime;
    }
    
    function setMinBuy(uint256 _minBuy)external onlyOwner{
        minBuy = _minBuy;
    }

    function setTimeInterval() external onlyOwner{
        timeInterval= 1 seconds;
    }

    function getBuyers()public view returns(address[]memory){
        return buyersList;
    }
}