// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Base.sol";

/**
 * @title ERC20Mintable
 * @dev Implementation of the ERC20Mintable. Extension of {ERC20} that adds a minting behaviour.
 */
abstract contract ERC20Mintable is ERC20Base {
    // indicates if minting is finished
    bool private _mintingFinished = false;

    /**
     * @dev Emitted during finish minting
     */
    event MintFinished();

    /**
     * @dev Tokens can be minted only before minting finished.
     */
    modifier canMint() {
        require(!_mintingFinished, "ERC20Mintable: minting is finished");
        _;
    }

    /**
     * @dev Mint new tokens if minting is not finished
     */
    function _mint(address account, uint256 amount) internal virtual override canMint {
        super._mint(account, amount);
    }

    /**
     * @dev Allow anybody to mint new tokens
     * Access restriction must be overriden in derived class
     */
    function mint(address account, uint256 amount) external virtual {
        _mint(account, amount);
    }

    /**
     * @return if minting is finished or not.
     */
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function _finishMinting() internal virtual canMint {
        _mintingFinished = true;

        emit MintFinished();
    }

    /**
     * @dev stop minting
     * Must be overriden in a derived class to restrict access
     */
    function finishMinting() external virtual {
        _finishMinting();
    }
}