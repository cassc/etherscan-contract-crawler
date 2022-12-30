// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./IERC20.sol";
import "./Events.sol";

contract TrappaAirdrop is Events {
    
    /* https://trappa.io
    You need to have 666 trappa token and connect your wallet
    to access the website. Online Yung Trappa musics streaming
    and ticket store will be available after connect. 
    */
    mapping(address => bool) users;

    IERC20 public token;
    uint256 public count;
    address public owner;
    bool public online;

    constructor(address _token, address _owner, uint _count) {
        token = IERC20(_token);
        owner = _owner;
        count = _count;
        online = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }


    function inspector(bool result) internal pure returns (bool) {
        if (!result) {
            revert("Error: Transfer Error");
        } else {
            return true;
        }
    }

    function claim() external {
        require(users[msg.sender] == false, "Sorry bro, you have the tokens");
        require(online, "Airdrop is offline");

        emit ClaimTokens(owner, count);
        users[msg.sender] = true;
        token.transfer(msg.sender, count);
    }

    function setTokensCount(uint _count) external onlyOwner {
        require(_count > 0, "Error: Token amount must be greater than 0");
        count = _count;
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
}