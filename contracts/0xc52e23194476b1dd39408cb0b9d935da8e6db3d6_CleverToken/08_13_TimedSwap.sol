pragma solidity ^0.5.0;

import "hardhat/console.sol";

import "./CleverToken.sol";
import "./CleverProtocol.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TimedSwap
 * @dev Extension of Crowdsale contract that increases the price of tokens
 * Note that what should be provided to the constructor is the address for the token and policy
 * established the amount of tokens per wei contributed. 
 */
contract TimedSwap is Context, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for CleverToken;

    //events
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // Rates
    uint256 private _firstRate;
    uint256 private _secondRate;
    uint256 private _thirdRate;
    uint256 private _fourthRate;
    uint256 private _finalRate;
    
    // Windows
    uint256 private _firstWindow;
    uint256 private _secondWindow;
    uint256 private _thirdWindow;
    uint256 private _fourthWindow;
    uint256 private _finalWindow;

    // Times
    uint256 private _openingTime;
    uint256 private _closingTime;
    uint256 private _interval;

    // The token being sold
    CleverToken private _token;
    
    // Protocol to forward the funds
    address payable internal _protocol;

    // Amount of wei raised
    uint256 private _weiRaised;

    //modifiers
    modifier onlyWhileOpen {
        require(isOpen(), "TimedSwap is not open");
        _;
    }

    /*Fall back*/
    function () external payable {
        buyTokens(_msgSender());
    }

    /**
     * @dev Constructor, sets the rates of tokens received per wei contributed.
     */
    constructor  (address payable protocol, address token, uint256 open, bool daysFlag) public {

        //1e18 wei = 1 ETH, therefore 0.002 ETH = 2e15 or 20e14
        // Refer to _getTokenAmount() to clarify _Xrate usage

        // interval type set
        if(daysFlag) {
            _interval = (1 days);
        }else{ //mock minutes instead of days -- testing
            _interval = (1 minutes);    
        }
        
        // Set rates
        _firstRate = 500; //1e18 CLVA = 2e15 * _firstRate
        _secondRate = 476; //5% penalty
        _thirdRate = 455; //10% penalty
        _fourthRate = 435; //15% penalty
        _finalRate = 417; //20% penalty

        // Windows for time frames
        _firstWindow = uint(1).mul(_interval); //Day 1
        _secondWindow = uint(2).mul(_interval); //Day 2-3
        _thirdWindow = uint(4).mul(_interval); //Day 4-7
        _fourthWindow = uint(3).mul(_interval); //Day  8-10
        _finalWindow = uint(20).mul(_interval); //Day 11-30

        // Set times
        _openingTime = open; // unix time
        _closingTime = _openingTime + uint(30).mul(_interval);//30 days; //TODO: set the correct days
        require(_closingTime > _openingTime, "Opening time is not before closing time");

        // Setup the external contracts
        require(protocol != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");
        
        _protocol = protocol;
        _token = CleverToken(token);
    }

    /**
     * @dev low level token purchase
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant onlyWhileOpen payable {
        uint256 weiAmount = msg.value;

        //makes sure sale is open from valid address with value sent
        _preValidatePurchase(beneficiary, weiAmount); 

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount); 

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        //call internal deliver -- delivers tokens
        _processPurchase(beneficiary, tokens);

        //forward funds to the protocol address
        _forwardFunds();
        
        //emit purchase event
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }


    /**
     * @dev Returns the rate of tokens per wei at the present time.
     * @return The number of tokens a buyer gets per wei at a given time
     */
    function getCurrentRate() public view returns (uint256) {
        require(now > openingTime(), "Swapping has not begun");
        require(isOpen(), "The initial swapping has ended");
        // solhint-disable-next-line not-rely-on-time
        uint256 elapsedTime = getElapsedTime();
        uint256 numberOfDaysElapsed = uint(elapsedTime).div(_interval);
        require (numberOfDaysElapsed < 30, "The number of days passed exceeds the initial swap");
        
        //find the window for the swap
        if (numberOfDaysElapsed < 1){
            require(elapsedTime < _firstWindow);
            //in the first window
            return _firstRate;
        } else if (numberOfDaysElapsed < 3) {
            require(elapsedTime < (_firstWindow + _secondWindow));
            //in second window
            return _secondRate;
        } else if (numberOfDaysElapsed < 7) {
            require(elapsedTime < (_firstWindow + _secondWindow + _thirdWindow));
            //in third window
            return _thirdRate;
        } else if (numberOfDaysElapsed < 10) {
            require(elapsedTime < (_firstWindow + _secondWindow + _thirdWindow + _fourthWindow));
            //in fourth window
            return _fourthRate;
        } else if (numberOfDaysElapsed < 30) {
            require(elapsedTime < (_firstWindow + _secondWindow + _thirdWindow + _fourthWindow + _finalWindow));
            //in final window
            return _finalRate;
        }
        revert("error with getting current rate; swap is not open");
    }



    /*********************
    * INTERNAL FUNCTIONS *
    **********************/

    /**
     * @dev Overrides parent method taking into account variable rate.
     * @param weiAmount The value in wei to be converted into tokens
     * @return The number of tokens _weiAmount wei will buy at present time
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return currentRate.mul(weiAmount);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        //send funds to the protocol
        _protocol.transfer(msg.value);
        
    }

    /**
     * @dev Overrides delivery by minting tokens upon purchase.
     * @param beneficiary Token purchaser
     * @param tokenAmount Number of tokens to be minted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        // Potentially dangerous assumption about the type of the token.
        require(
            CleverToken(address(token())).mint(beneficiary, tokenAmount),
                "MintedCrowdsale: minting failed"
        );
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /***************
    * PUBLIC UTILS *
    ****************/

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    function interval() public view returns(uint256){
        return _interval;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }
    
    function getElapsedTime() public view returns (uint256){
        require(now > openingTime());
        return block.timestamp.sub(openingTime());
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        //renounce minting if 
        if(block.timestamp > _closingTime){
            if(token().isMinter(address(this))){

                //renounce minter role if this contract is still a minter and it has closed
                token().renounceMinter();

            }
            //and return true
            return true;
        }else{
            return false;
        }
        
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (CleverToken) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _protocol;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the initial rate of the swap
     */
    function initialRate() public view returns (uint256) {
        return _firstRate;
    }



}