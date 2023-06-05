// SPDX-License-Identifier: MIT
// twitter: AiCat_token
// website: https://aicat.site
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AiCat is ERC20, Ownable {
    //max supply 1B
    uint256 public maxSupply = 1000000000 * 10 ** decimals();

    mapping(address => bool) public minted;

    constructor() ERC20("AiCat", "AIC") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function mint() public payable {
        if(minted[msg.sender] == false){
            _mint(msg.sender, 500000 * 10 ** decimals());
            minted[msg.sender] = true;
        }else{
            require(msg.value >= 0.01 ether, "Pay 0.01 ether to mint again");
            _mint(msg.sender, 500000 * 10 ** decimals());
        }
        require(totalSupply() <= maxSupply, "Not enough AiCat left to mint");
    }

    function withdrawAmount(uint256 amount) public onlyOwner {
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}