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

contract Ask is ReentrancyGuard {
    address public immutable factory;
    address public immutable factoryOwner;
    address public immutable maker;
    uint256 public immutable USDCPerOPTION;
    uint256 public immutable OPTIONSize;
    uint256 public immutable fee; // in bps, default is 30 bps
    uint256 public immutable feeMultiplier;
    uint256 public immutable duration;
    uint256 public endingTime;
    AoriSeats public immutable AORISEATSADD;
    bool public hasEnded = false;
    bool public hasBeenFunded = false;
    IERC20 public OPTION;
    IERC20 public USDC; 
    uint256 public OPTIONDecimals = 18;
    uint256 public USDCDecimals = 6;
    uint256 public decimalDiff = (10**OPTIONDecimals) / (10**USDCDecimals);
    uint256 public immutable BPS_DIVISOR = 10000;
    uint256 public USDCFilled;

    event OfferFunded(address maker, uint256 OPTIONSize, uint256 duration);
    event Filled(address buyer, uint256 OPTIONAmount, uint256 AmountFilled, bool hasEnded);
    event OfferCanceled(address maker, uint256 OPTIONAmount);

    constructor(
        IERC20 _OPTION,
        IERC20 _USDC,
        AoriSeats _AORISEATSADD,
        address _maker,
        uint256 _USDCPerOPTION,
        uint256 _fee,
        uint256 _feeMultiplier,
        uint256 _duration, //in blocks
        uint256 _OPTIONSize
    ) {
        factory = msg.sender;
        factoryOwner = Ownable(factory).owner();
        OPTION = _OPTION;
        USDC = _USDC;
        AORISEATSADD = _AORISEATSADD;
        maker = _maker;
        USDCPerOPTION = _USDCPerOPTION;
        fee = _fee;
        feeMultiplier = _feeMultiplier;
        duration = _duration;
        OPTIONSize = _OPTIONSize;
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
        hasBeenFunded = true;
        //officially begin the countdown
        endingTime = block.timestamp + duration;
        emit OfferFunded(maker, OPTIONSize, duration);
    }
    /**
        Partial or complete fill of the offer, with the requirement of trading through a seat
        regardless of whether the seat is owned or not.
        In the case of not owning the seat, a fee is charged in USDC.
     */
    function fill(uint256 amountOfUSDC, uint256 seatId) public nonReentrant {
        require(isFunded(), "no option balance");
        require(msg.sender != maker && msg.sender != factory, "Cannot take one's own order");
        require(!hasEnded, "offer has been previously been cancelled");
        require(block.timestamp <= endingTime, "This offer has expired");
        require(USDC.balanceOf(msg.sender) >= amountOfUSDC, "Not enough USDC");
        require(AORISEATSADD.confirmExists(seatId) && AORISEATSADD.ownerOf(seatId) != address(0x0), "Seat does not exist");
        uint256 USDCAfterFee;
        uint256 OPTIONToReceive;
        uint256 refRate;

        if(msg.sender == AORISEATSADD.ownerOf(seatId)) {
            //Seat holders receive 0 fees for trading
            USDCAfterFee = amountOfUSDC;
            OPTIONToReceive = mulDiv(USDCAfterFee, 10**OPTIONDecimals, USDCPerOPTION); //1eY = (1eX * 1eY) / 1eX
            //transfers To the msg.sender
            USDC.transferFrom(msg.sender, maker, USDCAfterFee);
            //transfer to the Msg.sender
            OPTION.transfer(msg.sender, OPTIONToReceive);
        } else {
            //What the user will receive out of 100 percent in referral fees with a floor of 40
            refRate = (AORISEATSADD.getSeatScore(seatId) * 500) + 3500;
            //This means for Aori seat governance they should not allow more than 12 seats to be combined at once
            uint256 seatScoreFeeInBPS = mulDiv(fee, refRate, BPS_DIVISOR);
            //calculating the fee breakdown 
            uint256 seatTxFee = mulDiv(amountOfUSDC, seatScoreFeeInBPS, BPS_DIVISOR);
            uint256 ownerTxFee = mulDiv(amountOfUSDC, fee - seatScoreFeeInBPS, BPS_DIVISOR);
            //Calcualting the base tokens to transfer after fees
            USDCAfterFee = (amountOfUSDC - (ownerTxFee + seatTxFee));
            //And the amount of the quote currency the msg.sender will receive
            OPTIONToReceive = mulDiv(USDCAfterFee, 10**OPTIONDecimals, USDCPerOPTION); //(1e6 * 1e18) / 1e6 = 1e18
            //Transfers from the msg.sender
            USDC.transferFrom(msg.sender, factoryOwner, ownerTxFee);
            USDC.transferFrom(msg.sender, AORISEATSADD.ownerOf(seatId), seatTxFee);
            USDC.transferFrom(msg.sender, maker, USDCAfterFee);
            //Transfers to the msg.sender
            OPTION.transfer(msg.sender, OPTIONToReceive);
            //Tracking the volume in the NFT
            AORISEATSADD.addTakerVolume(amountOfUSDC, seatId, factory);
        }
        //Storage
        USDCFilled += USDCAfterFee;
        if(OPTION.balanceOf(address(this)) == 0) {
            hasEnded = true;
        }
        emit Filled(msg.sender, USDCAfterFee, amountOfUSDC, hasEnded);
    }
    /**
        Cancel this order and refund all remaining tokens
    */
    function cancel() public nonReentrant {
        require(isFunded(), "no OPTION balance");
        require(msg.sender == maker);
        uint256 balance = OPTION.balanceOf(address(this));
        
        OPTION.transfer(msg.sender, balance);
        hasEnded = true;
        emit OfferCanceled(maker, balance);
    }
    
    //Check if the contract is funded still.
    function isFunded() public view returns (bool) {
        if (OPTION.balanceOf(address(this)) > 0 && hasBeenFunded) {
            return true;
        } else {
            return false;
        }
    }
    //View function to see if this offer still holds one USDC
    function isFundedOverOne() public view returns (bool) {
        if (OPTION.balanceOf(address(this)) > (10 ** OPTION.decimals())) {
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
        if (OPTION.balanceOf(address(this)) >= 1) {
            return OPTION.balanceOf(address(this));
        } else {
            return 0;
        }
    }
   function totalUSDCWanted() public view returns (uint256) {
        return (USDCPerOPTION * OPTIONSize) / 10**OPTIONDecimals;
    }
}