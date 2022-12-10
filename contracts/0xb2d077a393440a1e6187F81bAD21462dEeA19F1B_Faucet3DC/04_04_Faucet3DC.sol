// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Faucet3DC is Ownable {
    uint256 public claimFaucetAmount = 1 * 10**18;
    bool public paused;
    address public token3DC;
    mapping(address => bool) public claimedAccounts;

    constructor(address _token) {
        token3DC = _token;
    }

    modifier onlyWhenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    function claim() public onlyWhenNotPaused {
        require(!claimedAccounts[msg.sender], "Faucet already claimed");
        claimedAccounts[msg.sender] = true;
        IERC20(token3DC).transfer(msg.sender, claimFaucetAmount);
    }

    function getToken3DCBalance() public view returns (uint256) {
        return IERC20(token3DC).balanceOf(address(this));
    }

    function setPaused(bool _pasused) public onlyOwner {
        paused = _pasused;
    }

    function removeClaimedWallet(address _address) public onlyOwner {
        claimedAccounts[_address] = false;
    }

    function setClaimFaucetAmount(uint256 newClaimFaucetAmount)
        public
        onlyOwner
    {
        claimFaucetAmount = newClaimFaucetAmount;
    }

    function setToken(address newToken) public onlyOwner {
        token3DC = newToken;
    }

    function withdrawETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawERC20Asset(address _token, uint256 _amount)
        public
        onlyOwner
    {
        if (_token == address(0x0)) payable(owner()).transfer(_amount);
        else IERC20(_token).transfer(owner(), _amount);
    }
}