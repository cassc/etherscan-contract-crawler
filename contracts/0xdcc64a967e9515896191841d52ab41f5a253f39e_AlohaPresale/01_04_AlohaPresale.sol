// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@oz/access/Ownable.sol";
import "@oz/token/ERC20/IERC20.sol";

contract AlohaPresale is Ownable {
    /// @notice The token being sold
    IERC20 public token;

    /// @notice Total supply of tokens for sale
    uint256 public supply;

    /// @notice Minimum amount a buyer can purchase
    uint256 public minAmount;

    /// @notice Maximum amount a buyer can purchase
    uint256 public maxAmount;

    /// @notice Total ETH collected from the sale
    uint256 public totalSales;

    /// @notice A structure to keep track of each buyer
    struct Buyer {
        address addr; // Address of the buyer
        uint256 amount; // Amount of ETH contributed by the buyer
    }

    /// @notice Mapping from index to Buyer struct
    mapping(uint256 => Buyer) public buyer;

    /// @notice Mapping from address of buyer to the index in the 'buyer' mapping
    mapping(address => uint256) public buyerIndex;

    /// @notice Number of unique buyers in the sale
    uint256 public totalBuyers;

    /// @notice Initializes contract with the creator as the owner
    constructor() Ownable(msg.sender) {}

    /// @notice Buy into the presale
    function buy() public payable {
        _presaleBuy();
    }

    /// @dev Fallback function for receiving ETH
    receive() external payable {
        _presaleBuy();
    }

    /// @dev Handles token purchase
    function _presaleBuy() private {
        require(maxAmount != 0, "Sale Not Open");
        require(msg.value >= minAmount, "Below ETH Minimum");
        uint256 index = buyerIndex[msg.sender];
        if (index == 0) {
            index = ++totalBuyers;
        }
        uint256 total = buyer[index].amount;
        require(msg.value + total <= maxAmount, "Above ETH Maximum");
        buyerIndex[msg.sender] = index;
        buyer[index].addr = msg.sender;
        buyer[index].amount += msg.value;
        totalSales += msg.value;
    }

    /// @dev Implements the logic for distributing tokens to buyers
    function _airdrop(uint256 from, uint256 to) private {
        require(address(token) != address(0) && supply != 0);
        uint256 tokenPrice = (totalSales * 10e18) / supply;
        for (uint256 i = from; i <= to; i++) {
            uint256 amount = buyer[i].amount * 10e18;
            uint256 numTokens = amount / tokenPrice;
            token.transfer(buyer[i].addr, numTokens);
        }
    }

    /// @dev Implements the logic for refunding buyers
    function _refund(uint256 a, uint256 b) private {
        require(a > 0);
        for (uint256 i = a; i <= b; i++) {
            address payable refunding = payable(buyer[i].addr);
            refunding.transfer(buyer[i].amount);
        }
    }

    /// @notice Allows contract owner to distribute tokens to the buyers
    /// @dev This function should be called after the sale has ended. It will calculate and distribute the tokens based on the contribution of each buyer.
    /// @dev Only accessible by contract owner
    function airdrop() external onlyOwner {
        _airdrop(1, totalBuyers);
    }

    /// @notice Allows contract owner to distribute tokens to a range of buyers
    /// @param a Index to start airdrop from
    /// @param b Index to stop airdrop at
    /// @dev This function should be called after the sale has ended. It will calculate and distribute the tokens based on the contribution of each buyer in the specified range.
    /// @dev Only accessible by contract owner
    function airdrop(uint256 a, uint256 b) external onlyOwner {
        require(a > 0);
        _airdrop(a, b);
    }

    /// @notice Allows contract owner to refund buyers
    /// @dev This function should be called if the sale has to be cancelled. It will refund the contributed Ether back to the buyers.
    /// @dev Only accessible by contract owner
    function refund() external onlyOwner {
        _refund(1, totalBuyers);
    }

    /// @notice Allows contract owner to refund a range of buyers
    /// @param from Index to start refund from
    /// @param to Index to stop refund at
    /// @dev This function should be called if the sale has to be cancelled. It will refund the contributed Ether back to the buyers in the specified range.
    /// @dev Only accessible by contract owner
    function refund(uint256 from, uint256 to) external onlyOwner {
        require(from > 0);
        _refund(from, to);
    }

    /// @notice Allows the contract owner to withdraw collected ETH
    /// @dev Only accessible by contract owner
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw Failed");
    }

    /// @notice Allows the contract owner to withdraw any ERC20 tokens sent to this contract by mistake
    /// @dev Only accessible by contract owner
    function withdrawERC20() external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    /// @notice Allows contract owner to set the token for the sale and its supply
    /// @param token_ The address of the token contract
    /// @param supply_ Total supply of the token for sale
    /// @dev Only accessible by contract owner
    function updateToken(IERC20 token_, uint256 supply_) external onlyOwner {
        token = token_;
        supply = supply_;
    }

    /// @notice Allows contract owner to update minimum and maximum purchase limits
    /// @param min New minimum purchase limit
    /// @param max New maximum purchase limit
    /// @dev Only accessible by contract owner
    function updateMinMaxAmount(uint256 min, uint256 max) public onlyOwner {
        minAmount = min;
        maxAmount = max;
    }
}