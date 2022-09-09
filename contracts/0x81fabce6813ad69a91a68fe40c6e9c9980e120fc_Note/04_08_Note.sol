// SPDX-License-Identifier: MIT

/**

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Note is ERC20, Ownable, ReentrancyGuard {

    address private manager;

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    modifier onlyManager(address _manager) {
        require(manager == _manager, "Only Manager Can Call This Function");
        _;
    }

    address private pool;

    function setPool(address _pool) external onlyOwner {
        pool = _pool;
    }

    modifier onlyPool(address _pool) {
        require(pool == _pool, "Only Pool Can Call This Function");
        _;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    constructor() ERC20("Note Token", "NT") {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function mint(address to, uint256 amount) external onlyManager(msg.sender) {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external onlyPool(msg.sender) {
        _burn(account, amount);
    }
}