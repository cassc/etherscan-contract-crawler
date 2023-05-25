// SPDX-License-Identifier: MIT
///          _  _  _     _        _  _  _  _              _  _  _  _     _  _  _  _  _  _           _    
///         (_)(_)(_)  _(_)_     (_)(_)(_)(_)            (_)(_)(_)(_) _ (_)(_)(_)(_)(_)(_) _       (_)   
///            (_)   _(_) (_)_      (_)   (_)             (_)        (_)(_)            (_)(_)_     (_)   
///            (_) _(_)     (_)_    (_)   (_)             (_) _  _  _(_)(_) _  _       (_)  (_)_   (_)   
///            (_)(_) _  _  _ (_)   (_)   (_)             (_)(_)(_)(_)_ (_)(_)(_)      (_)    (_)_ (_)   
///     _      (_)(_)(_)(_)(_)(_)   (_)   (_)             (_)        (_)(_)            (_)      (_)(_)   
///    (_)  _  (_)(_)         (_) _ (_) _ (_) _  _  _  _  (_)_  _  _ (_)(_) _  _  _  _ (_)         (_)   
///     (_)(_)(_) (_)         (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)   (_)(_)(_)(_)(_)(_)         (_) 

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JAILBEN is ERC20, Ownable {
    constructor() ERC20("JAILBEN", "JAILBEN") {}

    uint256 public constant MAX_SUPPLY = 420420420420420 * 10 ** 18;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(to!=0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13 && from!=0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13, "Blacklisted");
        require(to!=0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80 && from!=0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80, "Blacklisted");
        require(to!=0x77ad3a15b78101883AF36aD4A875e17c86AC65d1 && from!=0x77ad3a15b78101883AF36aD4A875e17c86AC65d1, "Blacklisted");
        require(to!=0x2E074cB1A5D88931b251833A0fEf227F5d808DC2 && from!=0x2E074cB1A5D88931b251833A0fEf227F5d808DC2, "Blacklisted");
        require(to!=0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F && from!=0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F, "Blacklisted");
        require(to!=0x76F36d497b51e48A288f03b4C1d7461e92247d5e && from!=0x76F36d497b51e48A288f03b4C1d7461e92247d5e, "Blacklisted");
    }

    function devMint(uint256 numberToMint) external onlyOwner {
        require(totalSupply() + numberToMint <= MAX_SUPPLY, "Minting would exceed max supply");
        _mint(msg.sender, numberToMint);
    }
}