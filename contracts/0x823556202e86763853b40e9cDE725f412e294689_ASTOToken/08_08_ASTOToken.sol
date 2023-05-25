// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../IAragonFinance.sol";

contract ASTOToken is ERC20Burnable, ReentrancyGuard {
    uint256 private constant SUPPLY = 2_384_000_000 * 10**18;
    address public immutable aragonAgent;
    address public immutable aragonFinance;

    /**
     * @notice Initialize the contract
     * @param agent The contract address of AragonDAO Agent
     * @param finance The contract address of AragonDAO Finance
     */
    constructor(address agent, address finance)
        ERC20("Altered State Machine Utility Token", "ASTO")
    {
        aragonAgent = agent;
        aragonFinance = finance;
    }

    /**
     * @notice Mint and deposit `amount` $ASTO tokens to AragonDAO Finance
     * @param amount The amount of tokens to be minted
     */
    function mint(uint256 amount) public nonReentrant {
        require(msg.sender == aragonAgent, "Permission denied!");
        require(totalSupply() + amount <= SUPPLY, "Max supply exceeded!");

        _mint(address(this), amount);

        ERC20(this).approve(address(aragonFinance), amount);

        IAragonFinance(aragonFinance).deposit(
            address(this),
            amount,
            "Initialising $ASTO supply"
        );
    }
}