// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ShowUpPass.sol";
import "./UltraTaiwan.sol";

contract Minter is Ownable, ReentrancyGuard {
    uint256 public price = 0.2 ether;
    uint256 public maxSupply = 50;
    uint256 public startTimestamp = 0;
    address public receiver;

    ShowUpPass public showUpPass;
    UltraTaiwan public ultraTaiwan;
    UltraTaiwanStub public ultraTaiwanStub;

    constructor(uint256 _price, uint256 _maxSupply, uint256 _startTimestamp, address _receiver) {
        showUpPass = new ShowUpPass();
        ultraTaiwan = new UltraTaiwan();
        ultraTaiwanStub = ultraTaiwan.stub();

        showUpPass.setMinter(address(this));
        ultraTaiwan.setMinter(address(this));

        showUpPass.setURI("ipfs://QmPJLjKxVwymB6uMGZMCmc8pPnF14smYpVPVPjfEvqHFJR/");
        ultraTaiwan.setURI("ipfs://QmYR3YPQfr4vtKzjYij6XvhKepwitvRkEJ1iYdfguWuU1X/");
        ultraTaiwanStub.setURI("ipfs://QmYR3YPQfr4vtKzjYij6XvhKepwitvRkEJ1iYdfguWuU1X/");

        // 2023-04-17 00:00:00+08:00
        ultraTaiwanStub.setTransferableTimestamp(1681660800);

        showUpPass.transferOwnership(msg.sender);
        ultraTaiwan.transferOwnership(msg.sender);
        ultraTaiwanStub.transferOwnership(msg.sender);

        set(_price, _maxSupply, _startTimestamp, _receiver);
    }

    function set(uint256 _price, uint256 _maxSupply, uint256 _startTimestamp, address _receiver) public onlyOwner {
        require(_receiver != address(0), "receiver is zero address");
        price = _price;
        maxSupply = _maxSupply;
        startTimestamp = _startTimestamp;
        receiver = _receiver;
    }

    function mint(address to, uint256 amount) external payable nonReentrant {
        require(startTimestamp != 0 && block.timestamp >= startTimestamp, "not started yet");
        require(msg.value >= amount * price, "not enough ether");
        require(showUpPass.totalSupply() + amount <= maxSupply, "max supply reached");

        for (uint256 i = 0; i < amount; i++) {
            showUpPass.mint(to);
            ultraTaiwan.mint(to);
        }

        (bool success,) = payable(receiver).call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    receive() external payable {}

    fallback() external payable {}
}