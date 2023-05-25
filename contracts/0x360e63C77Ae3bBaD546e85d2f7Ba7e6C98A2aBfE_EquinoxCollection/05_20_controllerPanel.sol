//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract controllerPanel is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _controllers;

    event ApprovedController(address indexed account, address indexed sender);
    event RevokedController(address indexed account, address indexed sender);

    modifier onlyAllowed() {
        require(
            (_controllers.contains(msg.sender) || owner() == msg.sender),
            "Not Authorised"
        );
        _;
    }

    function getControllers()
        external
        view
        returns (address[] memory _allowed)
    {
        _allowed = new address[](_controllers.length());
        for (uint256 i = 0; i < _controllers.length(); i++) {
            _allowed[i] = _controllers.at(i);
        }
        return _allowed;
    }

    function approveController(address _controller) external onlyOwner {
        require(
            !_controllers.contains(_controller),
            "Controller already added."
        );
        _controllers.add(_controller);
        emit ApprovedController(_controller, msg.sender);
    }

    function revokeController(address _controller) external onlyOwner {
        require(
            _controllers.contains(_controller),
            "Controller do not hold admin rights."
        );
        _controllers.remove(_controller);
        emit RevokedController(_controller, msg.sender);
    }

    function isController(address _controller) public view returns (bool) {
        return (owner() == _controller || _controllers.contains(_controller));
    }
}