//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
This contract receives XRUNE from the `EmissionsSplitter` contract and allows
private investors to claim their share of vested tokens. If they need to update
their address the owner can do so for them.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmissionsPrivateDispenser is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint public totalReceived;
    mapping(address => uint) public investorsPercentages; // 1e12 = 100%
    mapping(address => uint) public investorsClaimedAmount;

    event ConfigureInvestor(address investor, uint percentage);
    event Claim(address user, uint amount);
    event Deposit(uint amount);

    constructor(address _token, address[] memory investors, uint[] memory percentages) {
        token = IERC20(_token);
        require(investors.length == percentages.length);
        uint total = 0;
        for (uint i = 0; i < investors.length; i++) {
            require(investors[i] != address(0), "!zero");
            investorsPercentages[investors[i]] = percentages[i];
            emit ConfigureInvestor(investors[i], percentages[i]);
            total += percentages[i];
        }
        require(total == 1e12, "percentagees don't add up to 100%");
    }

    function updateInvestorAddress(address oldAddress, address newAddress) public onlyOwner {
        require(investorsPercentages[oldAddress] > 0, "not an investor");
        investorsPercentages[newAddress] = investorsPercentages[oldAddress];
        investorsPercentages[oldAddress] = 0;
        investorsClaimedAmount[newAddress] = investorsClaimedAmount[oldAddress];
        investorsClaimedAmount[oldAddress] = 0;
        emit ConfigureInvestor(newAddress, investorsPercentages[newAddress]);
    }
    
    function claimable(address user) public view returns (uint) {
        return ((totalReceived * investorsPercentages[user]) / 1e12) - investorsClaimedAmount[user];
    }

    function claim() public {
        uint amount = claimable(msg.sender);
        require(amount > 0, "nothing to claim");
        investorsClaimedAmount[msg.sender] += amount;
        token.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function deposit(uint amount) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        totalReceived += amount;
        emit Deposit(amount);
    }
}