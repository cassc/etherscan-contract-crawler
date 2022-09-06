// SPDX-License-Identifier: MIT LICENSE
/*
 * @title Fake Token v0.1
 * @author Marcus J. Carey, @marcusjcarey
 * @notice $FAKE is a ERC-20 Token for education & testing purposes only
 */
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract Fake is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) controllers;
    mapping(address => uint256) public lastMint;

    uint256 public interval;
    uint256 public traunch;

    constructor() ERC20('Fake', 'FAKE') {
        traunch = 100;
        interval = 60 * 60 * 24;
    }

    function faucet() external {
        if (lastMint[msg.sender] < 1) {
            lastMint[msg.sender] = block.timestamp;
            _mint(msg.sender, traunch);
        } else {
            require(
                (lastMint[msg.sender] + interval < block.timestamp),
                'Too soon!'
            );
            lastMint[msg.sender] = block.timestamp;
            _mint(msg.sender, traunch);
        }
    }

    function nextTraunch() public view returns (uint256) {
        if (block.timestamp < lastMint[msg.sender] + interval) {
            return (lastMint[msg.sender] + interval) - block.timestamp;
        }
        return 0;
    }

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], 'Only controllers can mint');
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        if (controllers[msg.sender]) {
            _burn(account, amount);
        } else {
            super.burnFrom(account, amount);
        }
    }

    function setInterval(uint256 _interval) public onlyOwner {
        interval = _interval;
    }

    function setTraunch(uint256 _traunch) public onlyOwner {
        traunch = _traunch;
    }

    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
    }

    function removeController(address _controller) external onlyOwner {
        controllers[_controller] = false;
    }

    function checkController(address _controller)
        external
        view
        onlyOwner
        returns (bool)
    {
        return controllers[_controller];
    }

    function getAddress() external view onlyOwner returns (address) {
        return address(this);
    }
}