// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CrownyToken is ERC20, Pausable, Ownable {
    using SafeMath for uint256;

    uint256 immutable public maxSupply;

    constructor (string memory _name, string memory _symbol, uint256 _maxSupply) ERC20(_name, _symbol) {
        maxSupply = _maxSupply;
        _mint(_msgSender(), _maxSupply);
    }

    function burn(uint256 amount) external onlyOwner {                   
        _burn(_msgSender(), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply().add(amount) <= maxSupply, "CrownyToken: totalSupply cannot exceed the max supply");

        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "CrownyToken: token transfer while paused");
    }
}