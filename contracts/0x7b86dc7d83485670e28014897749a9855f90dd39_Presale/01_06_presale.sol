// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Presale is Ownable {
    using SafeMath for uint256;
    IERC20 public token;

    uint256 public exchangeRate = 367982000; // Number of tokens per 1 ETH
    bool public initialized = false;
    uint256 public raisedAmount = 0;

    event Purchased(address indexed to, uint256 value);

    /**
     * @dev ensures that the contract is still active
     **/
    modifier whenInitialized() {
        // Check if sale is active
        require(initialized, "sale is not active");
        _;
    }

    /**
     * initialize
     * @dev Initialize the contract
     **/
    function initialize() public onlyOwner {
        require(initialized == false); // Can only be initialized once
        initialized = true;
    }

    /**
     * buyTokens
     * @dev function that sells available tokens
     **/
    function buyTokens() public payable whenInitialized {
        uint256 weiAmount = msg.value; // Calculate tokens to sell
        require(weiAmount > 0, "Enter a Non-Zero amount.");

        uint256 tokens = weiAmount.mul(exchangeRate);

        raisedAmount = raisedAmount.add(weiAmount); // Increment raised amount
        bool success = token.transfer(_msgSender(), tokens); // Send tokens to buyer
        require(success, "Tokens Transfer failed");

        (success, ) = payable(owner()).call{value: weiAmount}(""); // Send money to owner
        require(success, "ETH transfer failed");

        emit Purchased(_msgSender(), tokens);
    }

    function setExchangeRate(uint256 _exchangeRate) external onlyOwner {
        exchangeRate = _exchangeRate;
    }

    function setERC20Address(address _address) external onlyOwner {
        token = IERC20(_address);
    }

    /**
     * tokensAvailable
     * @dev returns the number of tokens allocated to this contract
     **/
    function balaceOfContract() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdrawERC20Tokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(_msgSender(), balance); // Send tokens to buyer
        require(success, "Tokens Transfer failed");
    }

    /**
     * @dev Fallback function if ETH is sent to address insted of buyTokens function
     **/
    receive() external payable {
        buyTokens();
    }

    /**
     * @dev constructor
     * @param _address is the ERC20 token address
     **/
    constructor(address _address) {
        require(_address != address(0), "ERC20 address is null");
        token = IERC20(_address);
    }
}