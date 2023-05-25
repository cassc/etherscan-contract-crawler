// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract MPWRToken is ERC20, ERC20Burnable, ERC20Snapshot, ERC20Pausable, Ownable {
    uint8 private constant _decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1e8 * (10**uint256(_decimals));

    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isMinter;

    event Blacklisted(address indexed account, bool value);
    event SetMinter(address indexed _minter, bool _isMinter);

    constructor() ERC20("Empower Token", "MPWR") {}

    function initialize() external onlyOwner {
        isMinter[msg.sender] = true;
        mint(msg.sender, INITIAL_SUPPLY);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "onlyMinter: only minter can call this operation");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);

        require(!isBlacklisted[from] && !isBlacklisted[to], "Account blacklisted");
    }

    function blacklistMalicious(address account, bool value) external onlyOwner {
        isBlacklisted[account] = value;

        emit Blacklisted(account, value);
    }

    function setMinter(address _minter, bool _isMinter) external onlyOwner {
        require(_minter != address(0), "invalid minter address");
        isMinter[_minter] = _isMinter;

        emit SetMinter(_minter, _isMinter);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        require(_to != address(0), "Invalid address");
        _mint(_to, _amount);
    }
}