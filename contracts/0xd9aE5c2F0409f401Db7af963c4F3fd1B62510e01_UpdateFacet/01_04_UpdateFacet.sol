// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "./BaseFacet.sol";

contract UpdateFacet is BaseFacet {
    function initialize() external onlyOwner {
        Address.sendValue(payable(s.royaltiesRecipient), address(this).balance);
    }
}