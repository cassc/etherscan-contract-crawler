// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SotokotoPeaceToken is ERC20, Pausable, Ownable {
    uint256 public constant DECIMAL_MULTIPLIER = 10**8;
    uint256 public constant INITIAL_SUPPLY = 500 * 10**6 * DECIMAL_MULTIPLIER;
    uint256 public constant MAX_SUPPLY = 50 * 10**9 * DECIMAL_MULTIPLIER;

    /**
     * @dev Constructor.
     * @param _name name of the token
     * @param _symbol symbol of the token, 3-4 chars is recommended
     * @param _admin address that get INITIAL_SUPPLY of token
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _admin
    ) ERC20(_name, _symbol) {
        _mint(_admin, INITIAL_SUPPLY);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner {
        _pause();
    }


    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply if have role contract owner.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "MINT: Max supply exceeded");
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from owner of contract, reducing the
     * total supply if have role contract owner.
     */
    function burn(uint256 amount) external onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Prevent transfer token if have issues.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}