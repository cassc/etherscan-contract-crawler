//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    function retrieveERC20(IERC20 _token) external onlyOwner {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }
}