/**
 *Submitted for verification at BscScan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address owner) external returns (uint256);

    function transfer(address owner, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract PaymentContract {
    address payable public fundWallet;
    address payable public owner;
    address public usdtTokenAddress;
    address public busdTokenAddress;
    uint256 public totalBnbPaid;
    uint256 public totalUSDTPaid;
    uint256 public totalBusdPaid;
    uint256 public totalSold;
    uint256 private rateInEth = 184882; //number of tokens for 1 BNB
    uint256 private rateInUSDT = 588;   //number of tokens for 1 USDT
    uint256 private rateInBUSD = 588;   //number of tokens for 1 BUSD


    mapping (address => uint256) private tokensPurchased;

    event PaymentReceived(address payer, uint256 amount, string currency);

    constructor() {
        fundWallet = payable(0x5Cd6c59e8a140d33adF2e1e661361c4243fB517f);
        usdtTokenAddress = 0x55d398326f99059fF775485246999027B3197955;
        busdTokenAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        owner = payable(msg.sender);
    }

    function payInBnb() public payable {
        require(msg.value > 0, "Payment amount must be greater than zero");
       
        (bool success, ) = payable(fundWallet).call{value: msg.value}("");
        require(success, "Payment failed");
        totalBnbPaid += msg.value;
        uint256 amount = msg.value * rateInEth;
        tokensPurchased[msg.sender] += amount;
        totalSold += amount;
        emit PaymentReceived(msg.sender, msg.value, "BNB");
    }

    function payInUsdt(uint256 _amount) public {
        require(
            _amount > 0,
            "PaymentContract: Payment amount must be greater than 0."
        );
        uint256 allowance = IERC20(usdtTokenAddress).allowance(
            msg.sender,
            address(this)
        );
        require(
            allowance >= _amount,
            "PaymentContract: Insufficient USDT allowance."
        );
        bool success = IERC20(usdtTokenAddress).transferFrom(
            msg.sender,
            fundWallet,
            _amount
        );
        require(success, "PaymentContract: Failed to transfer USDT tokens.");
        totalUSDTPaid += _amount;
        uint256 amount = _amount * rateInUSDT;
        tokensPurchased[msg.sender] += amount;
        totalSold += amount;
        emit PaymentReceived(msg.sender, _amount, "USDT");
    }

     function payInBusd(uint256 _amount) public {
        require(
            _amount > 0,
            "PaymentContract: Payment amount must be greater than 0."
        );
        uint256 allowance = IERC20(busdTokenAddress).allowance(
            msg.sender,
            address(this)
        );
        require(
            allowance >= _amount,
            "PaymentContract: Insufficient USDT allowance."
        );
        bool success = IERC20(busdTokenAddress).transferFrom(
            msg.sender,
            fundWallet,
            _amount
        );
        require(success, "PaymentContract: Failed to transfer USDT tokens.");
        totalUSDTPaid += _amount;
        uint256 amount = _amount * rateInBUSD;
        tokensPurchased[msg.sender] += amount;
        totalSold += amount;
        emit PaymentReceived(msg.sender, _amount, "BUSD");
    }

    function withdraw() external {
        require(
            msg.sender == owner,
            "PaymentContract: Only owner can withdraw funds."
        );
        uint256 balance = address(this).balance;
        if (balance > 0) {
            owner.transfer(balance);
        }
        uint256 usdtBalance = IERC20(usdtTokenAddress).balanceOf(address(this));
        if (usdtBalance > 0) {
            bool success = IERC20(usdtTokenAddress).transfer(
                owner,
                usdtBalance
            );
            require(
                success,
                "PaymentContract: Failed to transfer USDT tokens."
            );
        }

        uint256 busdBalance = IERC20(busdTokenAddress).balanceOf(address(this));
        if (busdBalance > 0) {
            bool success = IERC20(busdTokenAddress).transfer(
                owner,
                busdBalance
            );
            require(
                success,
                "PaymentContract: Failed to transfer BUSD tokens."
            );
        }
    }

    function changeWalletAddress(address payable _wallet) external {
        require(msg.sender == owner, "Caller is not an owner");
        owner = _wallet;
    }

     function changePriceUsdt(uint256 amount) external {
        require(msg.sender == owner, "Caller is not an owner");
        rateInUSDT = amount;
    }

     function changePriceEth(uint256 amount) external {
        require(msg.sender == owner, "Caller is not an owner");
        rateInEth = amount;
    }

    


}