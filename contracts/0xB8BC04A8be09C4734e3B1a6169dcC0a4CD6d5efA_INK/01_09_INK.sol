pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract INK is Context, Ownable, ERC20Capped {
    mapping (address => uint256) private _balances;
    mapping(address => bool) private whitelist;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor () ERC20("INK", "INK") ERC20Capped(500000000 * (10 ** uint256(18))) {}

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function setWhitelist(address[] calldata minters) external onlyOwner {
        for (uint256 i; i < minters.length; ) {
            whitelist[minters[i]] = true;
            unchecked { i += 1; }
        }
    }

    function whitelist_mint(address account, uint256 amount) external {
        require(whitelist[msg.sender], 'ERC20: sender must be whitelisted');
        _mint(account, amount);
    }

    function check_whitelist(address account) public view returns (bool) {
        return whitelist[account];
    }
}