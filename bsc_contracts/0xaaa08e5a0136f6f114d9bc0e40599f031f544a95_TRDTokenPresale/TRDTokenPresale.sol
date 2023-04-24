/**
 *Submitted for verification at BscScan.com on 2023-04-20
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

// TRD token BEP-20 contract
interface TRDToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// TRD token presale contract
contract TRDTokenPresale {
    // TRD token contract address
    address public constant trdTokenAddress = 0xA88d22D5E719830da923E9cad0233F97FAf48918;

    // Sale rate (0.001 BNB = 100 TRD)
    uint256 public constant rate = 100;

    // Sale limit (0.001 BNB)
    uint256 public constant limit = 1000000000000000;

    // Total sale amount
    uint256 public totalSales = 0;

    // Purchased TRD token amounts
    mapping(address => uint256) public trdBalances;

    // Purchase function
    function buy() public payable {
       require(msg.value >= limit, "Purchase limit exceeded");
        require(msg.value % limit == 0, "Invalid amount"); // 0.001 BNB

        // Load TRD token contract
        TRDToken trdToken = TRDToken(trdTokenAddress);

        // Verify TRD token balance
        uint256 trdAmount = (msg.value / limit) * rate; // Calculate TRD
        require(trdToken.balanceOf(address(this)) >= trdAmount, "Purchase failed, insufficient TRD token supply");

        // Perform TRD token transfer
        require(trdToken.transferFrom(trdTokenAddress, msg.sender, trdAmount), "TRD token transfer failed");
        trdBalances[msg.sender] += trdAmount;
        totalSales += msg.value;
    }

    // Withdraw TRD balance
    function withdrawTRD() public {
        // Load TRD token contract
        TRDToken trdToken = TRDToken(trdTokenAddress);

        uint256 trdBalance = trdBalances[msg.sender];
        require(trdBalance > 0, "Insufficient TRD token balance");

        // Perform TRD token transfer
        require(trdToken.transfer(msg.sender, trdBalance), "TRD token transfer failed");
        trdBalances[msg.sender] = 0;
    }

    // Withdraw balance
    function withdrawBNB() public {
        require(totalSales > 0, "Insufficient BNB balance");

        uint256 balance = totalSales;
        totalSales = 0;

        payable(msg.sender).transfer(balance);
    }
}