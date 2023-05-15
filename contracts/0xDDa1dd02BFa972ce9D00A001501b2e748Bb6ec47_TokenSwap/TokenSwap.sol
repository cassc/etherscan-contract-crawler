/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface USDTIERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TokenSwap {
    address payable public owner;
    uint256 public ethRate;
    uint256 public usdtRate;
    uint256 public airdropRate;
    IERC20 public token;
    uint8 public tokenDecimals = 18;
    USDTIERC20 public usdt;
    uint8 public usdtDecimals = 6;
    event Swap(address indexed from, uint256 ethAmount, uint256 tokenAmount);

    constructor(
        address _token,
        address _usdtAddress,
        uint256 _ethRate,
        uint256 _usdtRate,
        uint256 _airdropRate
    ) {
        owner = payable(msg.sender);
        token = IERC20(_token);
        usdt = USDTIERC20(_usdtAddress);
        ethRate = _ethRate;
        usdtRate = _usdtRate;
        airdropRate = _airdropRate;
    }

    function swapTokenForEth(address payable airdropAddress) external payable {
        uint256 tokenAmount = msg.value * ethRate;
        uint256 airdropAmount = (tokenAmount * airdropRate) / 100;
        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Insufficient token balance"
        );
        require(
            token.transfer(msg.sender, tokenAmount),
            "Token transfer failed"
        );
        if (airdropAddress != address(0)) {
            token.transfer(airdropAddress, airdropAmount);
        }
        emit Swap(msg.sender, msg.value, tokenAmount);
    }

    function swapTokenForUSDT(
        uint256 swapAmount,
        address payable airdropAddress
    ) external {
        uint256 allowanceAmount = usdt.allowance(msg.sender, address(this));
        require(allowanceAmount >= swapAmount, "Must approve USDT first");
        require(
            usdt.balanceOf(msg.sender) >= swapAmount,
            "Insufficient USDT balance"
        );
        uint256 aipepeAmount = swapAmount * (10** (tokenDecimals - usdtDecimals)) * usdtRate;
        require(
            token.balanceOf(address(this)) >= aipepeAmount,
            "Insufficient aipepe balance"
        );
        usdt.transferFrom(msg.sender, address(this), swapAmount);
        require(
            token.transfer(msg.sender, aipepeAmount),
            "Aipepe transfer failed"
        );
        if (airdropAddress != address(0)) {
            uint256 airdropAmount = (aipepeAmount * airdropRate) / 100;
            require(
                token.balanceOf(address(this)) >= airdropAmount,
                "Insufficient aipepe balance"
            );
            require(
                token.transfer(airdropAddress, airdropAmount),
                "Failed to transfer aipepe to airdrop address"
            );
        }
    }

    function setEthRate(uint256 _rate) external {
        require(msg.sender == owner, "Not authorized");
        require(_rate > 0, "Rate must be greater than zero");

        ethRate = _rate;
    }

    function getEthRate() external view returns (uint256) {
        require(msg.sender == owner, "Not authorized");
        return ethRate;
    }

    function setUsdtRate(uint256 _rate) external {
        require(msg.sender == owner, "Not authorized");
        require(_rate > 0, "Rate must be greater than zero");
        usdtRate = _rate;
    }

    function getUsdtRate() external view returns (uint256) {
        require(msg.sender == owner, "Not authorized");
        return usdtRate;
    }

    function setToken(address _token) external {
        require(msg.sender == owner, "Not authorized");
        require(_token != address(0), "Token address must be valid");

        token = IERC20(_token);
    }

    function setTokenDecimals(uint8 _decimals) external {
        require(msg.sender == owner, "Not authorized");
        require(_decimals > 0, "Decimals must be greater than zero");
        tokenDecimals = _decimals;
    }

    function getTokenDecimals() external view returns (uint8) {
        require(msg.sender == owner, "Not authorized");
        return tokenDecimals;
    }

    function setUsdtDecimals(uint8 _decimals) external {
        require(msg.sender == owner, "Not authorized");
        require(_decimals > 0, "Decimals must be greater than zero");
        usdtDecimals = _decimals;
    }

    function getUsdtDecimals() external view returns (uint8) {
        require(msg.sender == owner, "Not authorized");
        return usdtDecimals;
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Not authorized");
        require(address(this).balance >= amount, "Insufficient ETH balance");

        owner.transfer(amount);
    }

    function withdrawUSDT(uint256 amount) external {
        require(msg.sender == owner, "Not authorized");
        require(
            usdt.balanceOf(address(this)) >= amount,
            "Insufficient token balance"
        );

        usdt.transfer(owner, amount);
    }
}