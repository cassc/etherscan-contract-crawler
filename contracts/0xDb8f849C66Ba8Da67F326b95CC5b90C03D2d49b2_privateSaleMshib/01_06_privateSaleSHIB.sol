//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";



contract privateSaleMshib is
    Ownable,
    Pausable
{
    uint256 public totalTokensSold = 0;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public constant usdtDecimals = 10**6;

    bool private _initialized;

    IERC20Upgradeable public constant usdtToken = IERC20Upgradeable(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    uint256 public constant token_price = 1672;    
       
    /**
     * @dev calculates USDT cost for the tokens
     * @param _amount No of tokens to buy
     * @return usdtAmount USDT cost for the tokens, output has 6 decimals
    */

    
    function calculatePrice(uint256 _amount) public pure returns (uint256 usdtAmount) {
        require(_amount >= 1_495_214, "Minimum amount is 1,495,214 tokens");

        // Calculate the total price with higher precision
        uint256 price = _amount * token_price;

        // Divide the totalPrice to convert it to 6 decimal precision (10^6)
        usdtAmount = price / 10**2; // Divide by 10^2 to adjust for 6 decimals

    }

    
    mapping(address => uint256) public usdtDeposits;
    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;

    event SaleTimeSet(
        uint256 indexed _start, 
        uint256 indexed _end, 
        uint256 timestamp);

    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        uint256 indexed amountPaid,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor

    /**
     * @dev Initializes the contract and sets key parameters
     * @param _startTime start time of the presale
     * @param _endTime end time of the presale
     */
    function initialize(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner{
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "Invalid time"
        );
        require(!_initialized, "Already initialized");
        _initialized = true;
          
        startTime = _startTime;
        endTime = _endTime;
        emit SaleTimeSet(startTime, endTime, block.timestamp);
    }

    /**
     * @dev To pause the presale
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev To unpause the presale
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    modifier checkSaleState(uint256 amount) {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid time for buying"
        );
        require(amount > 0 , "Invalid sale amount");
        _;
    }

    /**
     * @dev To buy tokens using USDT
     * @param amount No of tokens to buy
     * emits {TokensBought} event
     */

    function buyWithUSDT(uint256 amount)
        external
        checkSaleState(amount)
        whenNotPaused
        returns (bool){

        require(amount + totalTokensSold <= 1_477_272_727, "Exceeds private sale");
        require(amount + userDeposits[_msgSender()] <= 26_913_875 , "Exceeds max buy amount");
        uint256 usdtAmount = calculatePrice(amount);
        require(usdtAmount + usdtDeposits[_msgSender()] <= 450 * usdtDecimals, "Exceeds max buy amount"); //max 450 usdt per wallet
        uint256 ourAllowance = usdtToken.allowance(
            _msgSender(),
            address(this)
        );
        require(usdtAmount <= ourAllowance, "Make sure to add enough allowance");
        (bool success, ) = address(usdtToken).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                usdtAmount
            )
        );
        require(success, "Token payment failed");
        totalTokensSold += amount;
        usdtDeposits[_msgSender()] += usdtAmount;
        userDeposits[_msgSender()] += amount;

        emit TokensBought(
            _msgSender(),
            amount,
            usdtAmount,
            block.timestamp
        );

        return success;
        }     
     

    /**
     * @dev helper function for frontend to get remainng USDT amount for the user
     * @param _address address of the user
     * @return usdtAmount
    */

    function usdtAmountRemaining(address _address) external view returns(uint256 usdtAmount){
        usdtAmount = (450 * usdtDecimals) - usdtDeposits[_address];
    }

     /**
     * @dev helper function for frontend to get remaining token amount for the user
     * @param _address address of the user
     * @return tokenAmount
    */

    function tokensRemaining(address _address) external view returns(uint256 tokenAmount){
        tokenAmount = 26_913_875  - userDeposits[_address];
    }
}