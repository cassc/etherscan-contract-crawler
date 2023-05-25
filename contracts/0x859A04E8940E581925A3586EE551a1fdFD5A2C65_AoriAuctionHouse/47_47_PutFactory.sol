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
pragma solidity 0.8.19;

import "./OpenZeppelin/Ownable.sol";
import "./AoriSeats.sol";
import "./AoriPut.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Margin/MarginManager.sol";

contract PutFactory is Ownable {

    mapping(address => bool) isListed;
    AoriPut[] putMarkets;
    address public keeper;
    uint256 public fee;
    AoriSeats public AORISEATSADD;
    MarginManager public manager;
    
    constructor(AoriSeats _AORISEATSADD, MarginManager _manager) {
        AORISEATSADD = _AORISEATSADD;
        manager = _manager;
    }

    event AoriPutCreated(
            IERC20 AoriPutAdd,
            uint256 strike, 
            uint256 duration, 
            IERC20 USDC,
            address oracle, 
            string name, 
            string symbol
        );

    /**
        Set the keeper of the Optiontroller.
        The keeper controls and deploys all new markets and orderbooks.
    */
    function setKeeper(address newKeeper) public onlyOwner returns(address) {
        keeper = newKeeper;
        return newKeeper;
    }

    function setAORISEATSADD(AoriSeats newAORISEATSADD) external onlyOwner returns(AoriSeats) {
        AORISEATSADD = newAORISEATSADD;
        return AORISEATSADD;
    }

    /**
        Deploys a new put option token at a designated strike and maturation block.
        Additionally deploys an orderbook to pair with the new ERC20 option token.
    */
    
    function createPutMarket(
            uint256 strikeInUSDC, 
            uint256 duration, 
            IERC20 USDC,
            IERC20 UNDERLYING,
            address oracle,
            string memory name_, 
            string memory symbol_
            ) public returns (AoriPut) {

        require(msg.sender == keeper);

        AoriPut putMarket = new AoriPut(address(manager), AoriSeats(AORISEATSADD).getFeeMultiplier(), strikeInUSDC, duration, USDC, UNDERLYING, oracle, AoriSeats(AORISEATSADD), name_, symbol_);

        isListed[address(putMarket)] = true;
        putMarkets.push(putMarket);

        emit AoriPutCreated(IERC20(address(putMarket)), strikeInUSDC, duration, USDC, oracle, name_, symbol_);
        return (putMarket);
    }

    //Checks if an individual Call/Put is listed
    function checkIsListed(address market) public view returns(bool) {
        return isListed[market];
    }
    
    function getAORISEATSADD() external view returns(AoriSeats) {
        return AORISEATSADD;
    }
    
    function getAllPutMarkets() external view returns(AoriPut[] memory) {
        return putMarkets;
    }
}