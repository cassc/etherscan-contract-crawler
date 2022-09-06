// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BoardingPass is ERC1155, Ownable, ReentrancyGuard {

    struct PassPrinter {
        uint256 available;
        uint256 price;
        uint256 txLimit;
        bool publicMint;
    }
    uint256 public totalPrinters;

    mapping(uint256 => PassPrinter) _passPrinters;

    constructor(string memory uri) ERC1155(uri) Ownable() {}

    function setURI(
        string memory newuri
    ) external onlyOwner {
        _setURI(newuri);
    }

    function newPrinter(
        uint256 supply,
        uint256 price,
        uint256 txLimit,
        bool publicMint
    ) external onlyOwner {
        totalPrinters += 1;
        _passPrinters[totalPrinters] = PassPrinter(supply, price, txLimit, publicMint);
    }

    function getPrinter(
        uint256 id
    ) external view returns (PassPrinter memory) {
        require(id <= totalPrinters && id != 0, "BoardingPass: Pass Printer doesn't exist");
        return _passPrinters[id];
    }

    function print(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) nonReentrant external payable {
        PassPrinter memory passPrinter = _passPrinters[id];

        require(passPrinter.available >= amount, "BoardingPass: can't print provided the pass with given id/amount");
        require(passPrinter.price * amount <= msg.value || msg.sender == owner(), "BoardingPass: not enough Eth to print passes");
        require(passPrinter.txLimit >= amount || msg.sender == owner(), "BoardingPass: available amount exceeds the tx limit");
        require(passPrinter.publicMint || msg.sender == owner(), "BoardingPass: msg.sender should be the owner to perform the action");

        passPrinter.available -= amount;
        _passPrinters[id] = passPrinter;
        _mint(to, id, amount, data);
    }

}