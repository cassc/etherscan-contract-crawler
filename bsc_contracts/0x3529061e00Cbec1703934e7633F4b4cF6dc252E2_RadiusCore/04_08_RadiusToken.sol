//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///@notice Fusion Finance's governance token
///@author John Nguyen (jooohn.eth)
contract RadiusToken is ERC20, Ownable {

    constructor() ERC20("Radius Token", "RADI") {}

    ///@notice wrapper for the _mint function, so that only the owner of the contract can mint tokens
    ///@param _to address of the user to mint
    ///@param _amount amount of $FUSN tokens to mint
    function mint(address _to, uint _amount) external onlyOwner {
        _mint(_to, _amount);
    }

}