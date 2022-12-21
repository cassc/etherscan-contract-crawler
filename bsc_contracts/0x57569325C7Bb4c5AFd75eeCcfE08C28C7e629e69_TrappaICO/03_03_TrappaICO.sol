// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./IERC20.sol";
import "./Events.sol";

contract TrappaICO is Events {
    
    /* https://trappa.io
    You need to have 666 trappa token and connect your wallet
    to access the website. Online Yung Trappa musics streaming
    and ticket store will be available after connect. 
    */

    IERC20 public token;
    uint256 public price;
    address public owner;
    bool public online;

    constructor(address _token, uint256 _price, address _owner) {
        token = IERC20(_token);
        price = _price; //60000000000000 // 1BNB = 1666
        owner = _owner;
        online = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    receive() external payable {
        require(online, "Error: ICO is offline");

        uint256 amount = msg.value / price;

        require(amount > 0, "Error: Token amount must be greater than 0");

        require(
            token.balanceOf(address(this)) >= amount,
            "Error: Try to buy less tokens"
        );

        uint256 _amount = amount * 10**18;

        emit BuyTokens(msg.sender, _amount);
        bool callback = token.transfer(msg.sender, _amount);

        inspector(callback);
    }

    function inspector(bool result) internal pure returns (bool) {
        if (!result) {
            revert("Error: Transfer Error");
        } else {
            return true;
        }
    }

    function transferBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Error: BNB amount must be greater than 0");
        emit TransferBalance(owner, balance);
        payable(owner).transfer(balance);
    }

    function revertTokens() external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "Error: Token amount must be greater than 0");
        emit RevertTokens(owner, amount);
        token.transfer(owner, amount);
    }

    function switchOnOff() external onlyOwner {
        if (!online) {
            online = true;
        } else {
            online = false;
        }

        emit SwitchOnOff(online);
    }

    function returnStuckTokens(address stuckToken) external onlyOwner {
        require(
            stuckToken != address(token),
            "Error: You can't to withdraw a main token"
        );

        emit ReturnStuckTokens(owner, stuckToken);

        IERC20 _stuckToken = IERC20(stuckToken);

        uint256 amount = _stuckToken.balanceOf(address(this));

        require(amount > 0, "Error: Token amount must be greater than 0");

        bool callback = _stuckToken.transfer(owner, amount);
        inspector(callback);
    }
}