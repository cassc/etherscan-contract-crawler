// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

interface IDungeons is IERC721 {
    function publicMint(uint256 amount) external payable;

    function claimed() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);
}

contract DungeonMinter is Ownable {
    IDungeons dungeons;

    uint256 price = 0.019 ether;
    address wallet;

    constructor(IDungeons _dungeons, address _wallet) {
        dungeons = _dungeons;
        wallet = _wallet;
    }

    function transferDungeonOwnership(address newOwner) public onlyOwner {
        dungeons.transferOwnership(newOwner);
    }

    function updateWallet(address newWallet) public onlyOwner {
        wallet = newWallet;
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    error InvalidMintAmount();
    error InvalidEthAmountSent();

    function mint(uint256 amount) public payable {
        if (amount < 1 || amount > 20) {
            revert InvalidMintAmount();
        }
        uint256 txPrice = amount * price;
        if (msg.value != txPrice) {
            revert InvalidEthAmountSent();
        }

        (bool sent, bytes memory data) = wallet.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        uint256 startingId = dungeons.claimed() + 1;
        uint256 endingId = startingId + amount - 1;

        dungeons.publicMint(amount);

        for (uint256 i = startingId; i <= endingId; i++) {
            dungeons.transferFrom(address(this), msg.sender, i);
        }
    }
}