// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Administration.sol";

contract POWERSTONES is ERC20, Administration {

    uint256 private _initialTokens = 750000000 ether;
    
    constructor() ERC20("POWERSTONES", "POWR") {}
    
    function initialMint() external onlyAdmin {
        require(totalSupply() == 0, "ERROR: Assets found");
        _mint(owner(), _initialTokens);
    }

    function mintTokens(uint amount) public onlyAdmin {
        _mint(owner(), amount * (10**18));
    }

    function mintTo(address to, uint amount) public onlyAdmin {
        _mint(to, amount * (10**18));
    }
    
    function burnTokens(uint amount) external onlyAdmin {
        _burn(owner(), amount * (10**18));
    }

    function buy(address from, uint amount) external onlyAdmin {
        _burn(from, amount * (10**18));
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}