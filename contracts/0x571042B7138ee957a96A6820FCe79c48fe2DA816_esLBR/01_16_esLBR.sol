// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
/**
 * @title esLBR is an ERC20-compliant token, but cannot be transferred and can only be minted through the esLBRMinter contract or redeemed for LBR by destruction.
 * - The maximum amount that can be minted through the esLBRMinter contract is 55 million.
 * - esLBR can be used for community governance voting.
 */

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./Governable.sol";

interface IlybraFund {
    function refreshReward(address user) external;
}

contract esLBR is ERC20Votes, Governable {
    mapping(address => bool) public esLBRMinter;
    address public immutable lybraFund;

    uint256 maxMinted = 60_500_000 * 1e18;
    uint256 public totalMinted;

    constructor(
        address _fund
    ) ERC20Permit("esLBR") ERC20("esLBR", "esLBR") {
        lybraFund = _fund;
        gov = msg.sender;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        revert("not authorized");
    }

    function setMinter(address[] calldata _contracts, bool[] calldata _bools) external onlyGov {
        for(uint256 i = 0;i<_contracts.length;i++) {
            esLBRMinter[_contracts[i]] = _bools[i];
        }
    }

    function mint(address user, uint256 amount) external returns(bool) {
        require(msg.sender == lybraFund || esLBRMinter[msg.sender] == true, "not authorized");
        uint256 reward = amount;
        if(msg.sender != lybraFund) {
            IlybraFund(lybraFund).refreshReward(user);
            if(totalMinted + reward > maxMinted) {
                reward = maxMinted - totalMinted;
            }
            totalMinted += reward;
        }
        _mint(user, reward);
        return true;
    }

    function burn(address user, uint256 amount) external returns(bool) {
        require(msg.sender == lybraFund || esLBRMinter[msg.sender] == true, "not authorized");
        if(msg.sender != lybraFund) {
            IlybraFund(lybraFund).refreshReward(user);
        }
        _burn(user, amount);
        return true;
    }
}