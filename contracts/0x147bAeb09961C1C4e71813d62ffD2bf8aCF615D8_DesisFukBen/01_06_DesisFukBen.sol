// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DesisFukBen is ERC20, Ownable {
    string private _logoURI;

    constructor() ERC20("BenChod", "BENCHOD") {
        uint256 initialSupply = 69420000000000 * 10 ** decimals();
        _mint(msg.sender, initialSupply);
        _logoURI = "";
    }

    function logoURI() public view returns (string memory) {
        return _logoURI;
    }

    function updateLogoURI(string memory newURI) external onlyOwner {
        _logoURI = newURI;
    }
}