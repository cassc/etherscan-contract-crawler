// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IController} from "./interfaces/IController.sol";
import "./interfaces/IOracle.sol";

contract Oracle is IOracle, Ownable {
  
    uint256 targetPrice;
    uint256 updatedTime;
    address public controller;

    event UpdatePrice(
        address indexed tokenAddress,
        uint256 targetPrice,
        uint256 updatedTime
    );


    
    /**
     * Network: Rinkeby
     * Oracle:  0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    constructor(address _controller) {
        setController(_controller);
    }

    modifier onlyAdmin() {
        require(IController(controller).admins(msg.sender) || msg.sender == owner() || msg.sender == controller, "Only admin can update price");
        _;
    }
    
    function setController(address _addr) public onlyOwner {
        controller = _addr;
    }

    function update(uint256 _targetPrice) public onlyAdmin {
        address tokenAddress = IController(controller).tokenForOracle(address(this));
        targetPrice = _targetPrice;
        updatedTime = block.timestamp;
        emit UpdatePrice(tokenAddress, targetPrice, updatedTime);
    }

    function getTargetValue() external view override returns(uint256, uint256) {
        return (targetPrice, updatedTime);
    }
}