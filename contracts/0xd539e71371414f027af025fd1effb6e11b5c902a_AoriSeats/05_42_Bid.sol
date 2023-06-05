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

import "./OpenZeppelin/IERC20.sol";
import "./AoriSeats.sol";
import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/ReentrancyGuard.sol";
import "./Chainlink/AggregatorV3Interface.sol";

contract Bid is ReentrancyGuard {
    address public immutable factory;
    address public immutable factoryOwner;
    address public immutable maker;
    uint256 public immutable OPTIONPerUSDC;
    uint256 public immutable USDCSize;
    uint256 public immutable fee; // in bps, default is 30 bps
    uint256 public immutable feeMultiplier;
    uint256 public immutable duration;
    uint256 public endingTime;
    AoriSeats public immutable AORISEATSADD;
    bool public hasEnded = false;
    bool public hasBeenFunded = false;
    IERC20 public USDC;
    IERC20 public OPTION;
    uint256 public USDCDecimals = 6;
    uint256 public OPTIONDecimals = 18;
    uint256 public decimalDiff = (10**OPTIONDecimals) / (10**USDCDecimals);
    uint256 public immutable BPS_DIVISOR = 10000;


    event OfferFunded(address maker, uint256 USDCSize, uint256 duration);
    event Filled(address buyer, uint256 USDCAmount, uint256 AmountFilled, bool hasEnded);
    event OfferCanceled(address maker, uint256 USDCAmount);

    constructor(
        IERC20 _USDC,
        IERC20 _OPTION,
        AoriSeats _AORISEATSADD,
        address _maker,
        uint256 _OPTIONPerUSDC,
        uint256 _fee,
        uint256 _feeMultiplier,
        uint256 _duration, //in blocks
        uint256 _USDCSize
    ) {
        factory = msg.sender;
        factoryOwner = Ownable(factory).owner();
        USDC = _USDC;
        OPTION = _OPTION;
        AORISEATSADD = _AORISEATSADD;
        maker = _maker;
        OPTIONPerUSDC = _OPTIONPerUSDC;
        fee = _fee;
        feeMultiplier = _feeMultiplier;
        duration = _duration;
        USDCSize = _USDCSize;
    }
    

    
    // release trapped funds
    function withdrawTokens(address token) public {
        require(msg.sender == factoryOwner);
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(factoryOwner).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            safeTransfer(token, factoryOwner, balance);
        }
    }
    
    /**
        Fund the Ask with Aori option ERC20's
     */
    function fundContract() public nonReentrant {
        require(msg.sender == factory);
        //officially begin the countdown
        endingTime = endingTime + duration;
        hasBeenFunded = true;
        emit OfferFunded(maker, USDCSize, duration);
    }
    /**
        Partial or complete fill of the offer, with the requirement of trading through a seat
        regardless of whether the seat is owned or not.
        In the case of not owning the seat, a fee is charged in USDC.
    */
    function fill(uint256 amountOfOPTION, uint256 seatId) public nonReentrant {
        require(isFunded(), "no usdc balance");
        require(msg.sender != maker && msg.sender != factory, "Cannot take one's own order");
        require(!hasEnded, "offer has been previously been cancelled");
        require(block.timestamp <= endingTime, "This offer has expired");
        require(OPTION.balanceOf(msg.sender) >= amountOfOPTION, "Not enough USDC");
        require(AORISEATSADD.confirmExists(seatId) && AORISEATSADD.ownerOf(seatId) != address(0x0), "Seat does not exist");

        uint256 OPTIONAfterFee;
        uint256 USDCToReceive;
        uint256 refRate;

        if(msg.sender == AORISEATSADD.ownerOf(seatId)) {
            //Seat holders receive 0 fees for trading
            OPTIONAfterFee = amountOfOPTION;
            USDCToReceive = mulDiv(OPTIONAfterFee, 10**USDCDecimals, OPTIONPerUSDC); //1eY = (1eX * 1eY) / 1eX
            //Transfers
            OPTION.transferFrom(msg.sender, maker, OPTIONAfterFee);
            USDC.transfer(msg.sender, USDCToReceive);
        } else {
            //Deducts the fee from the options the taker will receive
            OPTIONAfterFee = amountOfOPTION;            
            USDCToReceive = mulDiv(amountOfOPTION, 10**USDCDecimals, OPTIONPerUSDC); //1eY = (1eX * 1eY) / 1eX
            //What the user will receive out of 100 percent in referral fees with a floor of 40
            refRate = (AORISEATSADD.getSeatScore(seatId) * 500) + 3500;
            //This means for Aori seat governance they should not allow more than 12 seats to be combined at once
            uint256 seatScoreFeeInBPS = mulDiv(fee, refRate, BPS_DIVISOR); //(10 * 4000) / 10000 (min)
            uint256 seatTxFee = mulDiv(USDCToReceive, seatScoreFeeInBPS, BPS_DIVISOR); //(10**6 * 10**6 / 10**4)
            uint256 ownerTxFee = mulDiv(USDCToReceive, fee - seatScoreFeeInBPS, BPS_DIVISOR);
            //Transfers from the msg.sender
            OPTION.transferFrom(msg.sender, maker, OPTIONAfterFee);
            //Fee transfers are all in USDC, so for Bids they're routed here
            //These are to the Factory, the Aori seatholder, then the buyer respectively.
            USDC.transfer(factoryOwner, ownerTxFee);
            USDC.transfer(AORISEATSADD.ownerOf(seatId), seatTxFee);
            USDC.transfer(msg.sender, USDCToReceive - (ownerTxFee + seatTxFee));
            //Tracking the volume in the NFT
            AORISEATSADD.addTakerVolume(USDCToReceive + ownerTxFee + seatTxFee, seatId, factory);
        }
        if(USDC.balanceOf(address(this)) == 0) {
            hasEnded = true;
        }
        emit Filled(msg.sender, OPTIONAfterFee, amountOfOPTION, hasEnded);
    }

    /**
        Cancel this order and refund all remaining tokens
    */
    function cancel() public nonReentrant {
        require(isFunded(), "no USDC balance");
        require(msg.sender == maker);
        uint256 balance = USDC.balanceOf(address(this));
        
        USDC.transfer(msg.sender, balance);
        hasEnded = true;
        emit OfferCanceled(maker, balance);
    }

    //Check if the contract is funded still.
    function isFunded() public view returns (bool) {
        if (USDC.balanceOf(address(this)) > 0 && hasBeenFunded) {
            return true;
        } else {
            return false;
        }
    }
    //View function to see if this offer still holds one USDC
    function isFundedOverOne() public view returns (bool) {
        if (USDC.balanceOf(address(this)) > (10 ** USDC.decimals())) {
            return true;
        } else {
            return false;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransfer: failed");
    }

    /**
        Additional view functions 
    */
    function getCurrentBalance() public view returns (uint256) {
        if (USDC.balanceOf(address(this)) >= 1) {
            return USDC.balanceOf(address(this));
        } else {
            return 0;
        }
    }

    function totalUSDCWanted() public view returns (uint256) {
        return (OPTIONPerUSDC * USDCSize) / 10**OPTIONDecimals;
    }
}