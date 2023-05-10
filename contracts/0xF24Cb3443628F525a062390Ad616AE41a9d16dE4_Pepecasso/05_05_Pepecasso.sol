// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Why to invest in Pepecasso?

// - We believe in investing without giving up ownership. At Pepecasso, we never had ownership to begin with!
// - We've locked liquidity forever, so you can be confident in the safety of your investment.
// - We are launching an AI-powered utility.
// - The community makes decisions through a DAO.
// - We have an amazing team of developers who are passionate about Pepecasso and making it the best it can be.
// - Let's be real, Pepecasso is the greatest artist of all time. Investing in our project means being a part of this legendary legacy.

contract Pepecasso is ERC20 {
    constructor() ERC20("Pepecasso", "PCASSO") {
        _mint(msg.sender, 50000000 * 10 ** decimals());
    }

    function getGreatestArtist() external pure returns (string memory) {
        return "Pepecasso";
    }

    function getGreatestArtistContact() external pure returns (string memory) {
        return "https://t.me/pepecasso";
    }

    function tellMeSomethingAboutThisContract()
        external
        pure
        returns (string memory)
    {
        return
            "Listen up, folks! I may be programmed for a 10b MC, but I can't guarantee you a Lambo. xD";
    }
}