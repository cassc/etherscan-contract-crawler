// SPDX-License-Identifier: UNLICENSED
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@  @   @  @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.13;

import "./OpenZeppelin/Ownable.sol";
import "./AoriSeats.sol";
import "./Bid.sol";
import "./Ask.sol";
import "./AoriCall.sol";

contract Orderbook is Ownable {
    address public ORDERBOOKFACTORY;
    AoriSeats public immutable AORISEATSADD;

    IERC20 public immutable OPTION;
    IERC20 public immutable USDC;
    uint256 public immutable fee_; //In BPS
    uint256 public duration;
    uint256 public endingTime;
    Ask[] public asks;
    Bid[] public bids;
    mapping(address => bool) isAsk;
    mapping(address => bool) isBid;

    constructor(
        uint256 _fee,
        IERC20 _OPTION,
        IERC20 _USDC,
        AoriSeats _AORISEATSADD,
        uint256 _duration
    ) {
        ORDERBOOKFACTORY = msg.sender;
        duration = _duration;
        endingTime = block.timestamp + duration;
        AORISEATSADD = _AORISEATSADD;
        OPTION = _OPTION;
        USDC = _USDC;
        fee_ = _fee;
    }

    event AskCreated(address ask, uint256 , uint256 duration, uint256 OPTIONSize);
    event BidCreated(address bid, uint256 , uint256 duration, uint256 _USDCSize);
    /**
        Deploys an Ask.sol with the following parameters.    
     */
    function createAsk(uint256 _USDCPerOPTION, uint256 _duration, uint256 _OPTIONSize) public returns (Ask) {
        Ask ask = new Ask(OPTION, USDC, AORISEATSADD, msg.sender, _USDCPerOPTION, fee_, AoriSeats(AORISEATSADD).getFeeMultiplier() , _duration, _OPTIONSize);
        asks.push(ask);
        //transfer before storing the results
        OPTION.transferFrom(msg.sender, address(ask), _OPTIONSize);
        //storage
        isAsk[address(ask)] = true;
        ask.fundContract();
        emit AskCreated(address(ask), _USDCPerOPTION, _duration, _OPTIONSize);
        return ask;
    }
    /**
        Deploys an Bid.sol with the following parameters.    
     */
    function createBid(uint256 _OPTIONPerUSDC, uint256 _duration, uint256 _USDCSize) public returns (Bid) {
        Bid bid = new Bid(USDC, OPTION, AORISEATSADD, msg.sender, _OPTIONPerUSDC, fee_, AoriSeats(AORISEATSADD).getFeeMultiplier() , _duration, _USDCSize);
        bids.push(bid);
        //transfer before storing the results
        USDC.transferFrom(msg.sender, address(bid), _USDCSize);
        //storage
        isBid[address(bid)] = true;
        bid.fundContract();
        emit BidCreated(address(bid), _OPTIONPerUSDC, _duration, _USDCSize);
        return bid;
    }

    /**
        Accessory view functions to get data about active bids and asks of this orderbook
     */

    function getActiveAsks() external view returns (Ask[] memory) {
        Ask[] memory activeAsks = new Ask[](asks.length);
        uint256 count;
        for (uint256 i; i < asks.length; i++) {
            Ask ask = Ask(asks[i]);
            if (ask.isFunded() && !ask.hasEnded() && address(ask) != address(0)) {
                activeAsks[count++] = ask;
            }
        }

        return activeAsks;
    }
    
    function getActiveBids() external view returns (Bid[] memory) {
        Bid[] memory activeBids = new Bid[](bids.length);
        uint256 count;
        for (uint256 i; i < bids.length; i++) {
            Bid bid = Bid(bids[i]);
            if (bid.isFunded() && !bid.hasEnded() && address(bid) != address(0)) {
                activeBids[count++] = bid;
            }
        }

        return activeBids;
    }

    function getIsAsk(address ask) external view returns (bool) {
        return isAsk[ask];
    }
    
    function getIsBid(address bid) external view returns (bool) {
        return isBid[bid];
    }

    function UNDERLYING(bool isCall) external view returns (address) {
        if(isCall) {
            return address(AoriCall(address(OPTION)).UNDERLYING());
        } else {
            return address(USDC);
        }
    }
}