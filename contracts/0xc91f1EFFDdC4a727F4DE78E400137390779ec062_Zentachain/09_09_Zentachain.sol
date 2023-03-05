// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev Interface overrided in the current contract to allow whitelisted ones to mint tokens for Pool.
 */
interface IERC20Mintable {
    function mint (address to, uint256 amount) external;
}

/*                                                                                                                                   
  .----------------.  .----------------.  .----------------.  .----------------.  .-----------------.
 | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
 | |     ______   | || |  ____  ____  | || |      __      | || |     _____    | || | ____  _____  | |
 | |   .' ___  |  | || | |_   ||   _| | || |     /  \     | || |    |_   _|   | || ||_   \|_   _| | |
 | |  / .'   \_|  | || |   | |__| |   | || |    / /\ \    | || |      | |     | || |  |   \ | |   | |
 | |  | |         | || |   |  __  |   | || |   / ____ \   | || |      | |     | || |  | |\ \| |   | |
 | |  \ `.___.'\  | || |  _| |  | |_  | || | _/ /    \ \_ | || |     _| |_    | || | _| |_\   |_  | |
 | |   `._____.'  | || | |____||____| | || ||____|  |____|| || |    |_____|   | || ||_____|\____| | |
 | |              | || |              | || |              | || |              | || |              | |
 | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'                                                                                                                                                                                                                                                             
*/

contract Zentachain is ERC20, ERC20Burnable, Pausable, Ownable, IERC20Mintable, ReentrancyGuard {

    constructor() ERC20("Zentachain", "CHAIN") {
        _mint(msg.sender, 5000000 * 10 ** decimals());
    }

    mapping(address => bool) private _minters;

    modifier onlyMinters() {
        require(_minters[msg.sender], "NOT_ALLOWED!");
        _;
    }

    event MinterSet(address minter, bool allowed);

    /**
     * @dev Pause the contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Returns the number of decimal
     */
    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Add or remove contract address to the whitelist and allow them to use the mint function.
     *
     * Emits a {MinterSet} event.
     */
    function toggleMinters(address minter) external onlyOwner {
        _minters[minter] = !_minters[minter];
        emit MinterSet(minter, _minters[minter]);
    }

    function mint (address to, uint256 amount)
        external
        virtual
        override
        onlyMinters
        nonReentrant
    {
        _mint(to, amount);
    }

    function _beforeTokenTransfer (
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}