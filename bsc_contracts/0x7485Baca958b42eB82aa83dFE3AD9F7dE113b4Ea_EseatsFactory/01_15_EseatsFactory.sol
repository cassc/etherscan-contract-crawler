// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Eseats.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EseatsFactory {
    address[] public children;

    event EseatsCreated(
        address childAddress,
        string name,
        string symbol,
        uint eventType
    );

    function createChild(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _paymentToken,
        uint _eventType,
        address _rewardToken
    ) external {
        Eseats child = new Eseats(_name, _symbol, _baseTokenURI, _paymentToken, _eventType, _rewardToken);
        children.push(address(child));
        emit EseatsCreated(address(child), _name, _symbol, _eventType);
        if(_eventType == 0) {
            child.toggleFO(msg.sender);
        }
        child.transferOwnership(msg.sender);
    }

    function getLatestChild() external view returns (address) {
        return children[children.length - 1];
    }
}