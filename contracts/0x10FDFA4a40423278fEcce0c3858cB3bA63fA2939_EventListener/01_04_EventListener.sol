// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './IEventListener.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract EventListener is IEventListener, Ownable {
    mapping(address => bool) private tokenAddresses;

    constructor() {}

    function addContract(address _contractAddress) external onlyOwner {
        tokenAddresses[_contractAddress] = true;
        emit AddedContract(_contractAddress);
    }

    function callEvent(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(tokenAddresses[msg.sender], 'EventListener:: Contract not listed.');
        emit PackTransfer(msg.sender, _from, _to, _tokenId);
    }
}