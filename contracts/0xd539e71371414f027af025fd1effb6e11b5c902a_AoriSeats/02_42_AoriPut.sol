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

import "./OpenZeppelin/ERC20.sol";
import "./OpenZeppelin/Ownable.sol";
import "./Chainlink/AggregatorV3Interface.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/ReentrancyGuard.sol";
import "./AoriSeats.sol";
import "./Margin/MarginManager.sol";


contract AoriPut is ERC20, ReentrancyGuard {
    address public immutable factory;
    address public immutable manager;
    address public oracle; //Must be USD Denominated Chainlink Oracle with 8 decimals
    uint256 public immutable strikeInUSDC; //This is in 1e6 scale
    uint256 public immutable endingTime;
    uint256 public immutable duration; //duration in blocks
    uint256 public settlementPrice; //price to be set at expiration
    uint256 public immutable feeMultiplier;
    uint256 public immutable decimalDiff;
    uint256 immutable tolerance = 2 hours;
    bool public hasEnded = false;
    IERC20 public immutable USDC;
    IERC20 public immutable UNDERLYING;
    uint256 public immutable USDC_DECIMALS;
    AoriSeats public immutable AORISEATSADD;
    uint256 public immutable BPS_DIVISOR = 10000;

    mapping (address => uint256) optionSellers; 
    

    constructor(
        address _manager,
        uint256 _feeMultiplier,
        uint256 _strikeInUSDC,
        uint256 _duration, //in blocks
        IERC20 _USDC,
        IERC20 _UNDERLYING,
        address _oracle,
        AoriSeats _AORISEATSADD,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_, 18) {
        factory = msg.sender;
        manager = _manager;
        feeMultiplier = _feeMultiplier;
        strikeInUSDC = _strikeInUSDC; 
        duration = _duration; //in blocks
        USDC = _USDC;
        UNDERLYING = _UNDERLYING;
        USDC_DECIMALS = USDC.decimals();
        endingTime = block.timestamp + duration;
        oracle = _oracle;
        AORISEATSADD = _AORISEATSADD;
        decimalDiff = (10**decimals()) / (10**USDC_DECIMALS);
    }

    event PutMinted(uint256 optionsMinted, address minter);
    event PutBuyerITMSettled(uint256 optionsRedeemed, address settler);
    event PutSellerITMSettled(uint256 optionsRedeemed, address settler);
    event PutSellerOTMSettled(uint256 optionsRedeemed, address settler);
    event SellerRetrievedFunds(uint256 tokensRetrieved, address seller);


    function setOracle(address newOracle) public returns(address) {
        require(msg.sender == AORISEATSADD.owner());
        oracle = newOracle;
        return oracle;
    }

    /**
        Mints a Put option equivalent to the USDC being deposited divided by the strike price.
        Note that this does NOT sell the option for you.
        You must list the option in an OptionSwap orderbook to actually be paid for selling this option.
        The Receiver will receive the options ERC20's but the option seller will be stored as the msg.sender
     */
    function mintPut(uint256 quantityOfUSDC, address receiver, uint256 seatId) public nonReentrant returns (uint256) {
        //confirming the user has enough USDC
        require(block.timestamp < endingTime, "This option has already matured"); //safety check
        require(USDC.balanceOf(msg.sender) >= quantityOfUSDC, "Not enough USDC");
        require(AORISEATSADD.confirmExists(seatId) && AORISEATSADD.ownerOf(seatId) != address(0x0), "Seat does not exist");
        
        uint256 mintingFee;
        uint256 refRate;
        uint256 feeToSeat;
        uint256 optionsToMint;
        uint256 optionsToMintScaled;
        if (receiver == AORISEATSADD.ownerOf(seatId)) {
            //If the owner of the seat IS the caller, fees are 0
            mintingFee = 0;
            feeToSeat = 0;
            optionsToMint = (quantityOfUSDC * 1e6) / strikeInUSDC;
            optionsToMintScaled = optionsToMint * decimalDiff; //convert the USDC to 1e18 scale to mint LP tokens
            //transfer the USDC
            USDC.transferFrom(msg.sender, address(this), quantityOfUSDC);
            _mint(receiver, optionsToMintScaled);
        } else {
            //If the owner of the seat is not the caller, calculate and transfer the fees
            mintingFee = putUSDCFeeCalculator(quantityOfUSDC, AORISEATSADD.getOptionMintingFee());
            refRate = (AORISEATSADD.getSeatScore(seatId) * 500) + 3500;
            feeToSeat = (refRate * mintingFee) / BPS_DIVISOR; 
            optionsToMint = ((quantityOfUSDC - mintingFee) * 10**USDC_DECIMALS) / strikeInUSDC; //(1e6*1e6) / 1e6
            optionsToMintScaled = optionsToMint * decimalDiff;

            //transfer the USDC and route fees
            USDC.transferFrom(msg.sender, address(this), quantityOfUSDC - mintingFee);
            USDC.transferFrom(msg.sender, Ownable(factory).owner(), mintingFee - feeToSeat);
            USDC.transferFrom(msg.sender, AORISEATSADD.ownerOf(seatId), feeToSeat);
            //mint the user LP tokens
            _mint(receiver, optionsToMintScaled);
        }

        //storing this option seller's information for future settlement
        uint256 currentOptionsSold = optionSellers[msg.sender];
        uint256 newOptionsSold = currentOptionsSold + optionsToMintScaled;
        optionSellers[msg.sender] = newOptionsSold;

        emit PutMinted(optionsToMintScaled, msg.sender);

        return (optionsToMintScaled);
    }

    /**
        Sets the settlement price immediately upon the maturation
        of this option. Anyone can set the settlement into motion.
        Note the settlement price is converted to USDC Scale via getPrice();
     */
    function _setSettlementPrice() internal returns (uint256) {
        require(block.timestamp >= endingTime, "Option has not matured");
        if(hasEnded == false) {
            settlementPrice = uint256(getPrice());
            hasEnded = true;
        }
        return settlementPrice;
    }

    /**
        Essentially a MulDiv functio but for calculating BPS conversions
     */
    function putUSDCFeeCalculator(uint256 quantityOfUSDC, uint256 fee) internal pure returns (uint256) {
        uint256 txFee = (quantityOfUSDC * fee) / BPS_DIVISOR;
        return txFee;
    }
     /**
     * IN THE MONEY SETTLEMENT PROCEDURES
     * FOR IN THE MONEY OPTIONS SETTLEMENT
     * 
     */

    //Buyer Settlement ITM
    function buyerSettlementITM(uint256 optionsToSettle) public nonReentrant returns (uint256) {
        _setSettlementPrice();
        require(balanceOf(msg.sender) >= 0, "You have not purchased any options");
        require(balanceOf(msg.sender) >= optionsToSettle, "You are attempting to settle more options than you have purhased");
        require(strikeInUSDC > settlementPrice && settlementPrice != 0, "Option did not expire ITM");
        require(optionsToSettle <= totalSupply() && optionsToSettle != 0);

        uint256 profitPerOption = strikeInUSDC - settlementPrice;
        //Normalize the optionsToSettle to USDC scale then multiply by profit per option to get USDC Owed to the settler.
        uint256 USDCOwed = ((optionsToSettle / decimalDiff) * profitPerOption) / 10**USDC_DECIMALS; //((1e18 / 1e12) * 1e6) / 1e6
        //transfers
        _burn(msg.sender, optionsToSettle);
        USDC.transfer(msg.sender, USDCOwed);

        emit PutBuyerITMSettled(optionsToSettle, msg.sender);
        return (optionsToSettle);
    }


    /**
        Settlement procedures for an option sold that expired in of the money.
        The seller receives a portion of their underlying assets back relative to the
        strike price and settlement price. 
     */

    function sellerSettlementITM() public nonReentrant returns (uint256) {
        _setSettlementPrice();
        uint256 optionsToSettle = optionSellers[msg.sender];
        require(optionsToSettle >= 0);
        require(strikeInUSDC > settlementPrice && hasEnded == true, "Option did not expire OTM");

        //Calculating the USDC to receive ()
        uint256 USDCToReceive = ((optionsToSettle * settlementPrice) / decimalDiff) / 10**USDC_DECIMALS; //((1e18 / 1e12) * 1e6) / 1e6
        //store the settlement
        optionSellers[msg.sender] = 0;
    
        //settle
        USDC.transfer(msg.sender, USDCToReceive);
        
        emit PutSellerITMSettled(optionsToSettle, msg.sender);

        return optionsToSettle;
    }   

    /**
        Settlement procedures for an option sold that expired out of the money.
        The seller receives all of their underlying assets back while retaining the premium from selling.
     */
    function sellerSettlementOTM() public nonReentrant returns (uint256) {
        _setSettlementPrice();
        require(optionSellers[msg.sender] > 0 && settlementPrice >= strikeInUSDC, "Option did not expire OTM");
        uint256 optionsSold = optionSellers[msg.sender];

        //store the settlement
        optionSellers[msg.sender] = 0;

        //settle
        uint256 USDCOwed = ((optionsSold / decimalDiff) * strikeInUSDC) / 10**USDC_DECIMALS; //((1e18 / 1e12) * 1e6) / 1e6
        USDC.transfer(msg.sender, USDCOwed);

        emit PutSellerOTMSettled(optionsSold, msg.sender);

        return optionsSold;
    }

    /**
        Early settlement exclusively for liquidations via the margin manager
     */
    function liquidationSettlement(uint256 optionsToSettle) public nonReentrant returns (uint256) {
        require(msg.sender == MarginManager(manager).vaultAdd(ERC20(address(USDC))));
        
        _burn(msg.sender, optionsToSettle);
        optionSellers[manager] -= optionsToSettle;
        uint256 USDCToReceive = (optionsToSettle * strikeInUSDC) / 10**USDC_DECIMALS;
        USDC.transferFrom(address(this), manager, USDCToReceive);
        return USDCToReceive;
    }

    /**
     *  VIEW FUNCTIONS
    */

    /** 
        Get the price of the underlying converted from Chainlink format to USDC.
    */
    function getPrice() public view returns (uint256) {
        (, int256 price,  ,uint256 updatedAt,  ) = AggregatorV3Interface(oracle).latestRoundData();
        require(price >= 0, "Negative Prices are not allowed");
        require(block.timestamp <= updatedAt + tolerance, "Price is too stale to be trustworthy"); // also works if updatedAt is 0
        if (price == 0) {
            return strikeInUSDC;
        } else {
            //8 is the decimals() of chainlink oracles
            return (uint256(price) / (10**(8 - USDC_DECIMALS)));
        }
    }

    /** 
        For frontend ease. If a uint then the option is ITM, if 0 then it is OTM. 
    */
    function getITM() public view returns (uint256) {
        if (getPrice() <= strikeInUSDC) {
            return strikeInUSDC - getPrice();
        } else {
            return 0;
        }
    }
    
    function getOptionsSold(address seller_) public view returns (uint256) {
        return optionSellers[seller_];
    }
}