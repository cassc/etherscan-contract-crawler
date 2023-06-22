// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "openzeppelin/access/Ownable.sol";

error InsufficientCustomizationFee(uint256 sent, uint256 expected);
error CallerIsNotOwner();

interface IDreamZuki {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract DreamZukiCustomizer is Ownable {
    address constant public TEAM_WALLET = 0x7Ab93E182f872AB95593d68bcEf9e7D62c1e5D94;
    address constant public TEAM_WALLET2 = 0x41c3fA3c2512A858b8099fFf112a18A9a65AD3Ca;

    uint256 public customizeFee = 0.0085 ether;
    IDreamZuki public nft;

    event Customize(uint256 indexed id, uint256[] traits);

    constructor(address nft_) {
        nft = IDreamZuki(nft_);
    }

    function customize(uint256 id, uint256[] calldata traits) external payable {
        if(msg.value < customizeFee) revert InsufficientCustomizationFee(msg.value, customizeFee);
        if(nft.ownerOf(id) != msg.sender) revert CallerIsNotOwner();

        emit Customize(id, traits);
    }

    function setCustomizationFee(uint256 fee) external onlyOwner {
        customizeFee = fee;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = TEAM_WALLET.call{value: address(this).balance * 7 / 10}("");
        require(success, "Transfer failed.");

        (bool success2, ) = TEAM_WALLET2.call{value: address(this).balance}("");
        require(success2, "Transfer failed.");
    }
}