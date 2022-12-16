pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IControllerRegistry.sol";

contract ControllerRegistry is IControllerRegistry, Ownable {
    mapping(address => bool) public controllerRegistry;

    event ControllerRegister(address newController);
    event ControllerRemove(address newController);

    /**
     * @param _controller The address to register as a controller
     */
    function registerController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid address");
        emit ControllerRegister(_controller);
        controllerRegistry[_controller] = true;
    }

    /**
     * @param _controller The address to remove as a controller
     */
    function removeController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid address");
        emit ControllerRemove(_controller);
        controllerRegistry[_controller] = false;
    }

    /**
     * @param _controller The address to check if registered as a controller
     * @return Boolean representing if the address is a registered as a controller
     */
    function isRegistered(address _controller)
        external
        view
        override
        returns (bool)
    {
        return controllerRegistry[_controller];
    }
}