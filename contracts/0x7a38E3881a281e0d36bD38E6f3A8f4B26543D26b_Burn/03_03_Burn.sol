// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

interface IToken {
    function burnFT(address, uint256, uint256) external;

    function mintNFT(address to, uint16 tier, uint256 quantity) external;
}

struct TokenMap {
    bool enabled;
    uint16 tier;
    uint256 quantity;
}

contract Burn is Ownable {
    address private _tokenAddress;
    bool private _enabled;

    mapping(uint256 => TokenMap) _tokenToTier;

    function setEnabled(bool b) public onlyOwner {
        _enabled = b;
    }

    function setTokenAddress(address addr) public onlyOwner {
        _tokenAddress = addr;
    }

    function setMapping(
        uint256 fungibleID,
        bool enabled,
        uint16 tier,
        uint256 quantity
    ) public onlyOwner {
        _tokenToTier[fungibleID] = TokenMap(enabled, tier, quantity);
    }

    function breakCrate(address to, uint256 token, uint256 quantity) public {
        require(_enabled == true, "Breaking is not enabled.");
        require(_tokenToTier[token].enabled, "Token not configured.");

        // console.log("burning FTs", token, quantity);

        IToken(_tokenAddress).burnFT(_msgSender(), token, quantity);

        // console.log(
        //     "minting NFTs",
        //     _tokenToTier[token].tier,
        //     _tokenToTier[token].quantity * quantity
        // );

        IToken(_tokenAddress).mintNFT(
            to,
            _tokenToTier[token].tier,
            _tokenToTier[token].quantity * quantity
        );

        // console.log("done with break");
    }
}