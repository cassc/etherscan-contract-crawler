// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";


contract SailToken is ERC20("SAIL Token", "SAIL"), ERC20Permit("SAIL Token"), ERC20Burnable, Ownable2Step {
    uint256 public nextMintTime;
    uint256 public nextMintAmount;

    uint256 constant MINIMUM_MINT_WAITING_PERIOD = 2 weeks;
    uint256 constant MAXIMUM_MINT_AMOUNT_BASIS_POINTS = 250;
    uint256 constant ONE_IN_BASIS_POINTS = 1e4;
    uint256 constant INITIAL_TOKEN_SUPPLY = 1e9 ether;

    error InvalidMint();
    event MintSet(uint256 mintTime, uint256 mintAmount);

    constructor(address theDAO) {
        _transferOwnership(theDAO);
        _mint(theDAO, INITIAL_TOKEN_SUPPLY);
    }

    function setMint(uint256 mintTime, uint256 mintAmount) external onlyOwner {
        if(mintTime < block.timestamp + MINIMUM_MINT_WAITING_PERIOD) {
            revert InvalidMint();
        }
        if(mintAmount > (MAXIMUM_MINT_AMOUNT_BASIS_POINTS*totalSupply())/ONE_IN_BASIS_POINTS) {
            revert InvalidMint();
        }
        nextMintTime = mintTime;
        nextMintAmount = mintAmount;
        emit MintSet(mintTime, mintAmount);
    }

    function executeMint() external {
        // Checks
        if(nextMintTime==0) {
            revert InvalidMint();
        }
        if(block.timestamp < nextMintTime) {
            revert InvalidMint();
        }
        // Effects
        nextMintTime = 0;
        // Interactions
        _mint(owner(), nextMintAmount);
    }

}