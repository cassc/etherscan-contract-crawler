// SPDX-License-Identifier: MIT
// Creator: promos.wtf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PromosProxy is Ownable {
    address public promosMintAddress;

    function setPromosMintAddress(address _promosMintAddress)
        external
        onlyOwner
    {
        promosMintAddress = _promosMintAddress;
    }
}