// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

/// @notice Minimal implementation of access control mechanism with two roles (owner & controller)
/// @dev Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)
contract Controlled {
    /*///////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error CallerIsNotAuthorized();
    error TargetIsZeroAddress();

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ControlTransferred(address indexed previousController, address indexed newController);

    /*///////////////////////////////////////////////////////////////
                             ROLES STORAGE
    //////////////////////////////////////////////////////////////*/

    address private _owner;
    address private _controller;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _transferOwnership(msg.sender);
        _transferControl(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (_owner != msg.sender) revert CallerIsNotAuthorized();
        _;
    }

    modifier onlyController() {
        if (_controller != msg.sender) revert CallerIsNotAuthorized();
        _;
    }

    modifier onlyOwnerOrController() {
        if (_owner != msg.sender && _controller != msg.sender) revert CallerIsNotAuthorized();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function controller() public view virtual returns (address) {
        return _controller;
    }

    /*///////////////////////////////////////////////////////////////
                               ACTIONS
    //////////////////////////////////////////////////////////////*/

    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function removeControl() external virtual onlyOwnerOrController {
        _transferControl(address(0));
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) revert TargetIsZeroAddress();
        _transferOwnership(newOwner);
    }

    function transferControl(address newController) external virtual onlyOwnerOrController {
        if (newController == address(0)) revert TargetIsZeroAddress();
        _transferControl(newController);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transferControl(address newController) internal virtual {
        address oldController = _controller;
        _controller = newController;
        emit ControlTransferred(oldController, newController);
    }
}