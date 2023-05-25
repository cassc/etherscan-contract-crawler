// SPDX-License-Identifier: Unlicense
pragma solidity =0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract Manager is Ownable, Pausable {
    mapping(address => bool) public isOperator;

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Oops!You-are-not-operator");
        _;
    }

    constructor() public {
        isOperator[msg.sender] = true;
    }

    function whiteListOperator(address _operator, bool _isOperator)
        external
        onlyOwner()
    {
        isOperator[_operator] = _isOperator;
    }

    function stop() external onlyOperator() {
        require(!paused(), "Already-paused");
        _pause();
    }

    function start() external onlyOperator() {
        require(paused(), "Already-start");
        _unpause();
    }
}