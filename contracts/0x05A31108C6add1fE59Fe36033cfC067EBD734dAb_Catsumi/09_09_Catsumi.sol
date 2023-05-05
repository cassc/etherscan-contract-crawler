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
  /\___/\
  ꒰˶• ༝ -꒱      
  ︻デ═一....•°♥︎                                     ฅ૮・ﻌ・აฅ   
  .----------------.  .----------------.  .----------------. 
 | .--------------. || .--------------. || .--------------. |
 | |     ______   | || |      __      | || |  _________   | |
 | |   .' ___  |  | || |     /  \     | || | |  _   _  |  | |
 | |  / .'   \_|  | || |    / /\ \    | || | |_/ | | \_|  | |
 | |  | |         | || |   / ____ \   | || |     | |      | |
 | |  \ `.___.'\  | || | _/ /    \ \_ | || |    _| |_     | |
 | |   `._____.'  | || ||____|  |____|| || |   |_____|    | |
 | |              | || |              | || |              | |
 | '--------------' || '--------------' || '--------------' |
  '----------------'  '----------------'  '----------------'                                                                                                                                                                                                                                                         
*/

contract Catsumi is ERC20, ERC20Burnable, Pausable, Ownable, IERC20Mintable, ReentrancyGuard {

    constructor() ERC20("Catsumi", "CAT") {
        _mint(msg.sender, 200000000000 * 10 ** decimals());
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