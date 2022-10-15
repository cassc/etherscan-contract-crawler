// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract KBNRToken is ERC20, ERC20Pausable {

    uint8 private constant _decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1e6 * (10**uint256(_decimals));
    
    address owner;

    mapping(address => bool) public isBlacklisted;

    modifier onlyOwner()
    {
        require(msg.sender == owner,"not owner");
        _;
    }

    event Blacklisted(address indexed account, bool value);
    event UpdateOwner(address oldOwner, address newOwner);
    
    constructor(address _owner) ERC20("Karbun", "KBNR") 
    {
        owner = _owner;
        _mint(_owner, INITIAL_SUPPLY);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);

        require(!isBlacklisted[from] && !isBlacklisted[to], "Account blacklisted");
    }

    function blacklistMalicious(address account, bool value) external onlyOwner {
        isBlacklisted[account] = value;

        emit Blacklisted(account, value);
    }

    function setOwner(address _owner) external onlyOwner
    {
        owner = _owner;
        emit UpdateOwner(msg.sender, _owner);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}