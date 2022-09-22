//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Airdrop is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    mapping(address => uint) public invests;
    address[] public investors;

    uint public raised;
    mapping(address => bool) public claimed;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function setInvestors(address[] calldata _investors, uint[] calldata _amounts) external onlyOwner {
        require(_investors.length == _amounts.length, "invalid data");

        for (uint i = 0; i < _investors.length; i++) {
            address _investor = _investors[i];
            uint _amount = _amounts[i];

            investors.push(_investor);

            raised += _amount;
            invests[_investor] += _amount;
        }
    }

    function multiSend() external onlyOwner {
        for (uint i = 0; i < investors.length; i++) {
            address investor = investors[i];
            if (claimed[investor] == true) continue;

            uint claimAmount = invests[investor];

            require (claimAmount <= token.balanceOf(address(this)), "Insufficient balance");
            
            token.safeTransfer(investor, claimAmount);

            claimed[investor] = true;
        }
    }

    function clear() external onlyOwner {
        raised = 0;
        for (uint i = 0; i < investors.length; i++) {
            claimed[investors[i]] = false;
            invests[investors[i]] = 0;
        }
        delete investors;
    }

    function claimable(address _user) external view returns(uint) {
        return invests[_user];
    }

    function getInvestors() external view returns (address[] memory, uint[] memory) {
        address[] memory investorList = new address[](investors.length);
        uint[] memory amountList = new uint[](investors.length);
        for (uint i = 0; i < investors.length; i++) {
            investorList[i] = investors[i];
            amountList[i] = invests[investors[i]];
        }

        return (investorList, amountList);
    }

    function count() external view returns (uint) {
        return investors.length;
    }

    function getTokensInStuck(uint256 _amount) external onlyOwner {
        uint256 _bal = token.balanceOf(address(this));
        if (_amount > _bal) _amount = _bal;

        token.safeTransfer(msg.sender, _amount);
    }
}