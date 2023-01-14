// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NotablesToken.sol";

contract BunnyKittyToken is NotablesToken {

    address mintContract;

    constructor(address _receiver) ERC721A("BK Genesis", "BKG") {
        setRoyalties(750, _receiver);
    }

    function mint(uint256 _amount, address _recipient) external {
        require(msg.sender == mintContract, "Tokens can only be minted through mint contract");
        _mint(_recipient, _amount);
    }

    function setMintContract(address _mintContract) external onlyOwner {
        mintContract = _mintContract;
    }

}