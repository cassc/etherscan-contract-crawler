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
import "./OpenZeppelin/SafeERC20.sol";
import "./Margin/MarginManager.sol";

contract AoriCall is ERC20, ReentrancyGuard {
    address public immutable factory;
    address public immutable manager;
    address public oracle; //Must be USD Denominated Chainlink Oracle with 8 decimals
    uint256 public immutable strikeInUSDC;
    uint256 public immutable endingTime;
    uint256 public immutable duration; //duration in blocks
    IERC20 public immutable UNDERLYING;
    uint256 public immutable UNDERLYING_DECIMALS;
    IERC20 public immutable USDC;
    uint256 public immutable USDC_DECIMALS;
    uint256 public settlementPrice;
    uint256 public immutable feeMultiplier;
    uint256 public immutable decimalDiff;
    uint256 immutable tolerance = 2 hours;
    bool public hasEnded = false;
    AoriSeats public immutable AORISEATSADD;
    mapping (address => uint256) public optionSellers;
    uint256 public immutable BPS_DIVISOR = 10000;


    constructor(
        address _manager,
        uint256 _feeMultiplier,
        uint256 _strikeInUSDC,
        uint256 _duration, //in blocks
        IERC20 _UNDERLYING,
        IERC20 _USDC,
        address _oracle,
        AoriSeats _AORISEATSADD,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_, 18) {
        factory = msg.sender;
        manager = _manager;
        feeMultiplier = _feeMultiplier;
        strikeInUSDC = _strikeInUSDC; 
        duration = _duration; //in seconds
        endingTime = block.timestamp + duration;
        UNDERLYING = _UNDERLYING;
        UNDERLYING_DECIMALS = UNDERLYING.decimals();
        USDC = _USDC;
        USDC_DECIMALS = USDC.decimals();
        decimalDiff = (10**UNDERLYING_DECIMALS) / (10**USDC_DECIMALS); //The underlying decimals must be greater than or equal to USDC's decimals.
        oracle = _oracle;
        AORISEATSADD = _AORISEATSADD;
    }

    event CallMinted(uint256 optionsMinted, address minter);
    event CallBuyerITMSettled(uint256 optionsRedeemed, address settler);
    event CallSellerITMSettled(uint256 optionsRedeemed, address settler);
    event CallSellerOTMSettled(uint256 optionsRedeemed, address settler);
    event SellerRetrievedFunds(uint256 tokensRetrieved, address seller);

    function setOracle(address newOracle) public returns(address) {
        require(msg.sender == AORISEATSADD.owner());
        oracle = newOracle;
        return oracle;
    }
    /**
        Mints a call option equivalent to the quantity of the underlying asset divided by
        the strike price as quoted in USDC. 
        Note that this does NOT sell the option for you.
        You must list the option in an OptionSwap orderbook to actually be paid for selling this option.
        The Receiver will receive the options ERC20's but the option seller will be stored as the msg.sender
     */
    function mintCall(uint256 quantityOfUNDERLYING, address receiver, uint256 seatId) public nonReentrant returns (uint256) {
        //confirming the user has enough of the UNDERLYING
        require(UNDERLYING_DECIMALS == UNDERLYING.decimals(), "Decimal disagreement");
        require(block.timestamp < endingTime, "This option has already matured"); //safety check
        require(UNDERLYING.balanceOf(msg.sender) >= quantityOfUNDERLYING, "Not enough of the underlying");
        require(AORISEATSADD.confirmExists(seatId) && AORISEATSADD.ownerOf(seatId) != address(0x0), "Seat does not exist");

        uint256 mintingFee;
        uint256 refRate;
        uint256 feeToSeat;
        uint256 optionsToMint;
        //Checks seat ownership, and assigns fees and transfers accordingly
        if (receiver == AORISEATSADD.ownerOf(seatId)) {
            //If the owner of the seat IS the caller, fees are 0
            mintingFee = 0;
            refRate = 0;
            feeToSeat = 0;
            optionsToMint = (quantityOfUNDERLYING * (10**6)) / strikeInUSDC;
            //transfer the UNDERLYING
            SafeERC20.safeTransferFrom(UNDERLYING, msg.sender, address(this), quantityOfUNDERLYING);
            _mint(receiver, optionsToMint);
        } else {
            //If the owner of the seat is not the caller, calculate and transfer the fees
            mintingFee = callUNDERLYINGFeeCalculator(quantityOfUNDERLYING, AORISEATSADD.getOptionMintingFee());
            // Calculating the fees to go to the seat owner
            refRate = (AORISEATSADD.getSeatScore(seatId) * 500) + 3500;
            feeToSeat = (refRate * mintingFee) / BPS_DIVISOR; 
            optionsToMint = ((quantityOfUNDERLYING - mintingFee) * (10**6)) / strikeInUSDC;

            //transfer the UNDERLYING and route fees
            SafeERC20.safeTransferFrom(UNDERLYING, msg.sender, address(this), quantityOfUNDERLYING - mintingFee);
            SafeERC20.safeTransferFrom(UNDERLYING, msg.sender, Ownable(factory).owner(), mintingFee - feeToSeat);
            SafeERC20.safeTransferFrom(UNDERLYING, msg.sender, AORISEATSADD.ownerOf(seatId), feeToSeat);
            //mint the user LP tokens
            _mint(receiver, optionsToMint);
        }

        //storing this option seller's information for future settlement
        uint256 currentOptionsSold = optionSellers[msg.sender];
        uint256 newOptionsSold = currentOptionsSold + optionsToMint;
        optionSellers[msg.sender] = newOptionsSold;

        emit CallMinted(optionsToMint, msg.sender);

        return (optionsToMint);
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
        Gets the option minting fee from AoriSeats and
        Calculates the minting fee in BPS of the underlying token
     */
    function callUNDERLYINGFeeCalculator(uint256 optionsToSettle, uint256 fee) internal view returns (uint256) {
        require(UNDERLYING_DECIMALS == UNDERLYING.decimals());
        uint256 txFee = (optionsToSettle * fee) / BPS_DIVISOR;
        return txFee;
    }

    /**
        Takes the quantity of options the user wishes to settle then
        calculates the quantity of USDC the user must pay the contract
        Note this calculation only occurs for in the money options.
     */
    function scaleToUSDCAtStrike(uint256 optionsToSettle) internal view returns (uint256) {
        uint256 tokenDecimals = 10**UNDERLYING_DECIMALS;
        uint256 scaledVal = (optionsToSettle * strikeInUSDC) / tokenDecimals; //(1e18 * 1e6) / 1e18
        return scaledVal;
    }

    /**
        In the money settlement procedures for an option purchaser.
        The settlement price must exceed the strike price for this function to be callable
        Then the user must transfer USDC according to the following calculation: (USDC * strikeprice) * optionsToSettle;
        Then the user receives the underlying ERC20 at the strike price.
     */
    function buyerSettlementITM(uint256 optionsToSettle) public nonReentrant returns (uint256) {
        _setSettlementPrice();
        require(balanceOf(msg.sender) >= optionsToSettle, "You are attempting to settle more options than you have purhased");
        require(balanceOf(msg.sender) >= 0, "You have not purchased any options");
        require(settlementPrice > strikeInUSDC  && settlementPrice != 0, "Option did not expire ITM");
        require(optionsToSettle <= totalSupply() && optionsToSettle != 0);
        
        //Calculating the profit using a ratio of settlement price
        //minus the strikeInUSDC, then dividing by the settlement price.
        //This gives us the total number of underlying tokens to give the settler.
        uint256 profitPerOption = ((settlementPrice - strikeInUSDC) * 10**6) / settlementPrice; // (1e6 * 1e6) / 1e6
        uint256 UNDERLYINGOwed = (profitPerOption * optionsToSettle) / 10**6; //1e6 * 1e18 / 1e6 
        
        _burn(msg.sender, optionsToSettle);
        SafeERC20.safeTransfer(UNDERLYING, msg.sender, UNDERLYINGOwed); //sending 1e18 scale tokens to user
        emit CallBuyerITMSettled(optionsToSettle, msg.sender);

        return (optionsToSettle);
    }

    /**
        In the money settlement procedures for an option seller.
        The option seller receives USDC equivalent to the strike price * the number of options they sold.
     */
    function sellerSettlementITM() public nonReentrant returns (uint256) {
        _setSettlementPrice();
        uint256 optionsToSettle = optionSellers[msg.sender];
        require(optionsToSettle > 0);
        require(settlementPrice > strikeInUSDC && hasEnded == true, "Option did not settle ITM");

        uint256 UNDERLYINGToReceive = ((strikeInUSDC * 10**6) / settlementPrice) * optionsToSettle; // (1e6*1e6/1e6) * 1e18
        //store the settlement
        optionSellers[msg.sender] = 0;
    
        //settle
        SafeERC20.safeTransfer(UNDERLYING, msg.sender, UNDERLYINGToReceive / 10**6);
        emit CallSellerITMSettled(optionsToSettle, msg.sender);

        return optionsToSettle;
    }   

    /**
        Settlement procedures for an option sold that expired out of the money.
        The seller receives all of their underlying assets back while retaining the premium from selling.
     */
    function sellerSettlementOTM() public nonReentrant returns (uint256) {
        _setSettlementPrice();
        require(optionSellers[msg.sender] > 0 && settlementPrice <= strikeInUSDC, "Option did not settle OTM or you did not sell any");
        uint256 optionsSold = optionSellers[msg.sender];

        //store the settlement
        optionSellers[msg.sender] = 0;

        //settle
        SafeERC20.safeTransfer(UNDERLYING, msg.sender, optionsSold);

        emit CallSellerOTMSettled(optionsSold, msg.sender);

        return optionsSold;
    }

    /**
        Early settlement exclusively for liquidations via the margin manager
     */
    function liquidationSettlement(uint256 optionsToSettle) public nonReentrant returns (uint256) {
        require(msg.sender == MarginManager(manager).vaultAdd(ERC20(address(UNDERLYING))));

        _burn(msg.sender, optionsToSettle);
        optionSellers[manager] -= optionsToSettle;
        uint256 UNDERLYINGToReceive = (optionsToSettle * strikeInUSDC) / 10**UNDERLYING_DECIMALS;
        UNDERLYING.transferFrom(address(this), manager, UNDERLYINGToReceive);
        return UNDERLYINGToReceive;
    }

    /**
     *  VIEW FUNCTIONS
    */

    /** 
        Get the price converted from Chainlink format to USDC
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
        if (getPrice() >= strikeInUSDC) {
            return getPrice() - strikeInUSDC;
        } else {
            return 0;
        }
    }

    function getOptionsSold(address seller_) public view returns (uint256) {
        return optionSellers[seller_];
    }
}