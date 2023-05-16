// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SDTToken is ERC20, Ownable {
    address erc721Address;

    constructor(address _erc721Address) ERC20("SDTToken", "SDTT") {
        erc721Address = _erc721Address;
    }

    modifier onlyERC721Address() {
        require(erc721Address == msg.sender, "SDTToken: Caller is not erc721Address");
        _;
    }

    function mint(address _to, uint _amount) public onlyERC721Address returns (bool) {
        _mint(address(_to), _amount);
        return true;
    }

    function burn(address _account, uint _amount) public onlyERC721Address returns (bool) {
        _burn(address(_account), _amount);
        return true;
    }
}