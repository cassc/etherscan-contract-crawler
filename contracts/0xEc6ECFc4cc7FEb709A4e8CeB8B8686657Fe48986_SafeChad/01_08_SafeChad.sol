//SPDX-License-Identifier: TRUECHADSONLY

/**
 *
 * TWITTER: @Safechad105
 * WEBSITE: https://safechad105.eth.limo
 *
 * AND YES IT IS A FULLY DECENTRALIZED WEBSITE U DEGEN
 */

pragma solidity ^0.8.18;

// WE PRINT MAGIC INTERNET MONEY FOR THE COMMUNITY
import "NOT-openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

// SAFECHAD CAME TO SAVE THE DEGENS FROM IMPOSTORS
// NO TAXES, NO LIES, PLAIN AND SIMPLE
// NO CONTRACT OWNER, JUST SAFECHAD

contract SafeChad is ERC20 {
    address public lp;

    constructor(address _router) ERC20("SAFECHAD105", "SAFECHAD") {
        _create(msg.sender, 105 * 1e6 * 1e18); // 105 SAFE MILS FOR CHADS
        IUniswapV2Router02 router = IUniswapV2Router02(_router); //SAFE CHAD IS CHAD, IT IS WHAT IT IS
        lp = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
    }

    // YOU EXPECTED SOMETHING ELSE FROM THE CONTRACT? THIS IS SAFECHAD
    // CHAD GIVES TO THE COMMUNITY, NOT TAKES, PLAIN AND SIMPLE
    // CHAD LOVES THE COMMUNITY AND TAKES CARE OF IT
    // CHAD ALWAYS HAS $SAFECHAD TO SUPPORT COMMUNITY INITIATIVES
    // NOT-ZEPPELIN-CONTRACTS PRINT MAGIC INTERNET MONEY

    /**
     * ONLY CHADS CAN PASS THE COMMUNITY WALLET AROUND
     */
    function assignSafeChad(address _safechad) external {
        require(msg.sender == safechad, "You aren't THE safechad");
        safechad = _safechad;
    }

    // BURN WE LOVE, BURN WE HAVE, BURN WE DO
    function _burn(uint256 amount) external {
        super._burn(msg.sender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        if (from == lp && to != safechad && from != safechad) {
            require(
                ((amount + balanceOf(to)) <= ((totalSupply() * 2) / 100)),
                "CANNOT HAVE MORE THAN 2% ON YAR WALLET, SHARE WITH OTHER CHADS YA GREEDY ASS"
            );
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // TRUECHADFLATION OF 5% IS HERE, TELLING YA EXPLICITLY THAT IT IS NOT A FEE, JUST CHAD COMMUNITY FUNDS
        // PRINTED FROM THE AIR, MAGIC INTERNET MONEY FOR EVERYONE WHO BUILDS WITH SAFECHAD,
        // WE MIGHT BE BURNING'EM IF NOT NEEDED
        // NO THIS DOES NOT HAVE ANYTHING TO DO WITH THE EXISTING LP
        // THAT IS FOR ---THE--- FUTURE OF THE MOVEMENT
        super._transfer(from, to, amount);
    }
}