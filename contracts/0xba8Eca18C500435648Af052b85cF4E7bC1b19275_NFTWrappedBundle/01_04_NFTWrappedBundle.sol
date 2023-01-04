// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMintableBundle.sol";

contract NFTWrappedBundle is Ownable {
    uint256 public PRICE_BUNDLE = 0.06 ether;

    address public contract1;
    address public contract2;

    function mint() external payable {
        require(msg.value >= PRICE_BUNDLE, "Not enough ETH");
        IMintableBundle(contract1).mintBundle(msg.sender);
        IMintableBundle(contract2).mintBundle(msg.sender);
    }

    // Only owner

    function setBundleContracts(address _contract1, address _contract2) external onlyOwner {
        contract1 = _contract1;
        contract2 = _contract2;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}