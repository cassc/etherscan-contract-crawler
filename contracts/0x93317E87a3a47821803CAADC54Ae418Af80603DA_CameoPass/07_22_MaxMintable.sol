// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

///@notice Ownable helper contract to keep track of how many times an address has minted
contract MaxMintable is Ownable {
    uint256 public maxMintsPerWallet;
    mapping(address => uint256) addressToTotalMinted;

    error MaxMintedForWallet();

    constructor(uint256 _maxMintsPerWallet) {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    ///@notice set maxMintsPerWallet. OnlyOwner
    function setMaxMintsPerWallet(uint256 _maxMints) public onlyOwner {
        maxMintsPerWallet = _maxMints;
    }

    ///@notice atomically check and increase number of mints for msg.sender
    ///@param _quantity number of mints
    function _ensureWalletMintsAvailableAndIncrement(uint256 _quantity)
        internal
    {
        if (
            (addressToTotalMinted[msg.sender] + _quantity) > maxMintsPerWallet
        ) {
            revert MaxMintedForWallet();
        }
        unchecked {
            addressToTotalMinted[msg.sender] += _quantity;
        }
    }
}