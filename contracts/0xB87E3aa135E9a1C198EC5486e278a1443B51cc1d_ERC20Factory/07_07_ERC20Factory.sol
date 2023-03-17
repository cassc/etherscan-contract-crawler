// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Contract.sol";

contract ERC20Factory is Ownable {

    address public deployerAddress;

    constructor(address _deployerAddress) {
        deployerAddress = _deployerAddress;
    }

    function updateDeployer(address _deployerAddress) external onlyOwner {
        deployerAddress = _deployerAddress;
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _owner
    ) external returns (address) {
        require(deployerAddress == msg.sender, "Not authorized");
        ERC20Contract _contract = new ERC20Contract(_name, _symbol, _maxSupply, _owner);
        return address(_contract);
    }
}