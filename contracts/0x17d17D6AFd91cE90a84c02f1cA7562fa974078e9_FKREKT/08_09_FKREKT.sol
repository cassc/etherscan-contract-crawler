// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract FKREKT is ERC20, ERC20Burnable, Pausable, Ownable {
    uint256 public constant TOTAL_SUPPLY = 420000000000000 * 1e18;

    uint256 public constant TEAM_PERCENTAGE = 40;
    uint256 public constant MARKETING_PERCENTAGE = 220;
    uint256 public constant LP_PERCENTAGE = 740;

    uint256 public teamTokens;
    uint256 public marketingTokens;
    uint256 public lpTokens;

    address public teamAddress;
    address public marketingAddress;
    address public lpAddress;

    uint256 public lauchTime;

    constructor(
        address _teamAddress,
        address _marketingAddress,
        address _lpAddress
    ) ERC20("FKREKT", "FKREKT") {
        lauchTime = block.timestamp;
        require(_teamAddress != address(0), "Team address cannot be zero");
        require(
            _marketingAddress != address(0),
            "Marketing address cannot be zero"
        );
        require(_lpAddress != address(0), "LP address cannot be zero");

        teamAddress = _teamAddress;
        marketingAddress = _marketingAddress;
        lpAddress = _lpAddress;

        marketingTokens = (TOTAL_SUPPLY * MARKETING_PERCENTAGE) / 1000;
        lpTokens = (TOTAL_SUPPLY * LP_PERCENTAGE) / 1000;
        teamTokens = (TOTAL_SUPPLY - lpTokens - marketingTokens);
        require(marketingTokens > 0, "No marketing tokens to transfer");
        require(lpTokens > 0, "No LP tokens to transfer");

        _mint(msg.sender, TOTAL_SUPPLY);
        _transfer(msg.sender, marketingAddress, marketingTokens);
        _transfer(msg.sender, lpAddress, lpTokens);
    }

    function transferTeamTokens() public onlyOwner {
        require(teamTokens > 0, "No team tokens to transfer");
        _mint(msg.sender, teamTokens);
        _transfer(msg.sender, teamAddress, teamTokens);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (recipient == teamAddress) {
            require(
                block.timestamp >= (lauchTime + 180 days),
                "Team tokens are locked for 6 months."
            );
        }
        super.transfer(recipient, amount);
        return true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}