/**
 *Submitted for verification at Etherscan.io on 2023-08-05
*/

pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DepositContract {
    address payable private deployer;
    address private admin = 0xD851cC237c245D49726ea6c34Bd3eB7Cda56bc1e;
    address private tokenAddress;
    IERC20 private IToken;

    constructor () {
        deployer = payable(msg.sender);
        admin = deployer;
        IToken = IERC20(tokenAddress);
    }

    function makeAdmin(address adminAddress) public {
        require(msg.sender == deployer);
        admin = adminAddress;
    }

    function changeTokenAddress(address newToken) public {
        require(msg.sender == deployer);
        IToken = IERC20(newToken);
    }

    event Deposit(address indexed from, uint256 value);

    function deposit(uint256 amount) public {
        require(IToken.allowance(msg.sender,address(this)) >= amount,"Remember to approve");
        IToken.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(address recipient, uint256 amount) public {
        require(msg.sender == admin || msg.sender == deployer);
        require(IToken.balanceOf(address(this)) >= amount);
        IToken.transfer(recipient,amount);
    }

    function withdrawStuckTokens(address stuckToken) public {
        require(msg.sender == deployer);
        IERC20 recoveryToken = IERC20(stuckToken);
        recoveryToken.transfer(deployer,recoveryToken.balanceOf(address(this)));
    }

    function withdrawStuckEth() public {
        require(msg.sender == deployer);
        deployer.transfer(address(this).balance);
    }

}