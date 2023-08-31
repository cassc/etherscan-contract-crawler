/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PublicSale {
    uint256 public constant TOTAL_SALE_AMOUNT = 141_305_000_000 * 10 ** 18;
    uint256 public constant PRICE = HARD_CAP * 1e18 / TOTAL_SALE_AMOUNT;
    uint256 public constant HARD_CAP = 30 ether;
    

    /**
     * @notice The address of the recipient, which will receive the raised ETH.
     */
    address public immutable recipient = 0x6D78B2C8C77BeD61d9ee79D32cDc1845D923BC35;


 

    /**
     * @notice Whether the sale has ended.
     */
    bool public saleEnded;

    /**
     * @notice The total amount of tokens bought.
     */
    uint256 public totalTokensBought;

    /**
     * @notice The start date of the sale in unix timestamp.
     */
    uint256 public start;

    /**
     * @notice The end date of the sale in unix timestamp.
     */
    uint256 public end;

    

    /**
     * @notice The amount of tokens bought by each address.
     */
    mapping(address => uint256) public amountBought;

    /**
     * @notice Emits when tokens are bought.
     * @param buyer The address of the buyer.
     * @param amount The amount of tokens bought.
     */

    event TokensBought(address indexed buyer, uint256 amount);


    
    /**
     * @notice Emits when the sale is ended.
     * @param totalAmountBought The total amount of tokens bought.
     * @param recipient The address of the recipient.
     */
    event SaleEnded(uint256 totalAmountBought, address indexed recipient);

    constructor( uint256 _start, uint256 _end) {
        start = _start;
        end = _end;
    }


    /**
     * @notice Buys tokens with ETH.
     */
    function buy() external payable {
        require(block.timestamp >= start, "Sale has not started yet");
        require(block.timestamp <= end, "Sale has ended");
        require(msg.value > 0, "Amount must be greater than 0");
        require(!saleEnded, "Sale has ended"); 

        // Compute the amount of tokens bought
        uint256 tokensBought = msg.value * 10 ** 18 / PRICE;


        // Update the storage variables
        amountBought[msg.sender] += tokensBought;
        totalTokensBought += tokensBought;
        emit TokensBought(msg.sender, tokensBought);
    }

    /**
     * @notice Ends the sale.
     */
    function endSale() external {
        require(block.timestamp > end, "Sale has not ended yet");
        require(!saleEnded, "Sale has already ended");

        // Mark the sale as ended
        saleEnded = true;   

         // Send the raised ETH to the recipient
        (bool sc,) = payable(recipient).call{value: address(this).balance}("");
        require(sc, "Transfer failed");
    
        emit SaleEnded(totalTokensBought, recipient);
    }
}