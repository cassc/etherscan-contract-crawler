//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PresaleDAYL is ERC20, Ownable {
    address public presale;

    constructor() ERC20("Project Daylight", "pDAYL") {}

    function setPresale(address _presale) public onlyOwner {
        require(_presale != address(0), "Invalid Presale Address");
        presale = _presale;
    }

    function mint(address dest, uint256 amount) external returns (bool) {
        require(
            msg.sender == presale || msg.sender == owner(),
            "Only Owner and Presale contract Mintable"
        );
        _mint(dest, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
}