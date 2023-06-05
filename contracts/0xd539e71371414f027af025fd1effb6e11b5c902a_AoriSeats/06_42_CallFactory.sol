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
import "./Interfaces/IAoriSeats.sol";
import "./AoriCall.sol";
import "./AoriSeats.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Margin/MarginManager.sol";

contract CallFactory is Ownable {

    mapping(address => bool) isListed;
    AoriCall[] callMarkets;
    address public keeper;
    uint256 public fee;
    AoriSeats public AORISEATSADD;
    MarginManager public manager;

    constructor(AoriSeats _AORISEATSADD, MarginManager _manager) {
        AORISEATSADD = _AORISEATSADD;
        manager = _manager;
    }

    event AoriCallCreated(
            address AoriCallAdd,
            uint256 strike, 
            uint256 duration, 
            IERC20 underlying, 
            IERC20 usdc,
            address oracle, 
            string name, 
            string symbol
        );

    /**
        Set the keeper of the Optiontroller.
        The keeper controls and deploys all new markets and orderbooks.
    */
    function setKeeper(address newKeeper) external onlyOwner returns(address) {
        keeper = newKeeper;
        return newKeeper;
    }

    function setAORISEATSADD(AoriSeats newAORISEATSADD) external onlyOwner returns(AoriSeats) {
        AORISEATSADD = newAORISEATSADD;
        return AORISEATSADD;
    }
    /**
        Deploys a new call option token at a designated strike and maturation block.
        Additionally deploys an orderbook to pair with the new ERC20 option token.
    */
    function createCallMarket(
            uint256 strikeInUSDC, 
            uint256 duration, 
            IERC20 UNDERLYING, 
            IERC20 USDC,
            address oracle,
            string memory name_, 
            string memory symbol_
            ) public returns (AoriCall) {

        require(msg.sender == keeper);

        AoriCall callMarket = new AoriCall(address(manager), AoriSeats(AORISEATSADD).getFeeMultiplier(), strikeInUSDC, duration, UNDERLYING, USDC, oracle, AoriSeats(AORISEATSADD), name_, symbol_);
        
        isListed[address(callMarket)] = true;
        callMarkets.push(callMarket);

        emit AoriCallCreated(address(callMarket), strikeInUSDC, duration, UNDERLYING, USDC, oracle, name_, symbol_);
        return (callMarket);
    }

    //Checks if an individual Call/Put is listed
    function checkIsListed(address market) external view returns(bool) {
        return isListed[market];
    }
    
    function getAORISEATSADD() external view returns(address) {
        return address(AORISEATSADD);
    }
    
    function getAllCallMarkets() external view returns(AoriCall[] memory) {
        return callMarkets;
    }
}