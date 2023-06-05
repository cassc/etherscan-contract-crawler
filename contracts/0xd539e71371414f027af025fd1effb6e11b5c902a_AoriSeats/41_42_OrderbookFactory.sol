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
pragma solidity ^0.8.19;

import "./OpenZeppelin/Ownable.sol";
import "./AoriSeats.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Orderbook.sol";

contract OrderbookFactory is Ownable {

    mapping(address => bool) isListedOrderbook;
    Orderbook[] public orderbookAdds;
    address public keeper;
    AoriSeats public AORISEATSADD;
    
    constructor(AoriSeats _AORISEATSADD) {
        AORISEATSADD = _AORISEATSADD;
    }

    event AoriOrderbookCreated(
        address AoriCallMarketAdd,
        uint256 fee,
        IERC20 underlyingAsset
    );

    /**
        Set the keeper of the Optiontroller.
        The keeper controls and deploys all new markets and orderbooks.
    */
    function setKeeper(address newKeeper) external onlyOwner returns(address) {
        keeper = newKeeper;
        return keeper;
    }
    
    function setAORISEATSADD(AoriSeats newAORISEATSADD) external onlyOwner returns(AoriSeats) {
        AORISEATSADD = newAORISEATSADD;
        return AORISEATSADD;
    }
    /**
        Gets the trading fee for the protocol.
     */
    function getTradingFee() internal view returns(uint256) {
        return AORISEATSADD.getTradingFee();
    }
    
    /**
        Deploys a new call option token at a designated strike and maturation block.
        Additionally deploys an orderbook to pair with the new ERC20 option token.
    */
    function createOrderbook(
            IERC20 OPTION_,
            IERC20 USDC,
            uint256 _duration
            ) public returns (Orderbook) {

        require(msg.sender == keeper);

        Orderbook orderbook =  new Orderbook(getTradingFee(), OPTION_, USDC, AORISEATSADD, _duration); 
        
        isListedOrderbook[address(orderbook)] = true;
        orderbookAdds.push(orderbook);

        emit AoriOrderbookCreated(address(orderbook), getTradingFee(), OPTION_);
        return (orderbook);
    }

    //Checks if an individual Orderbook is listed
    function checkIsListedOrderbook(address Orderbook_) public view returns(bool) {
        return isListedOrderbook[Orderbook_];
    }
    //Confirms for points that the Orderbook is a listed orderbook, THEN that the order is a listed order.
    function checkIsOrder(address Orderbook_, address order_) public view returns(bool) {
        require(checkIsListedOrderbook(Orderbook_), "Orderbook is not listed"); 
        require(Orderbook(Orderbook_).getIsBid(order_) == true || Orderbook(Orderbook_).getIsAsk(order_) == true, "Is not a confirmed order");

        return true;
    }

    function withdrawFees(IERC20 token, uint256 amount_) external onlyOwner returns(uint256) {
            IERC20(token).transfer(owner(), amount_);
            return amount_;
    }
    
    function getAllOrderbooks() external view returns(Orderbook[] memory) {
        return orderbookAdds;
    }
}