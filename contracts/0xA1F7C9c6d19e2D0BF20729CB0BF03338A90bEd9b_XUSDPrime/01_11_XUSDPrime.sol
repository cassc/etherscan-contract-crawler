// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./TokenRecover.sol";

/**
 * @title ERC20Mint
 * @dev Implementation of the ERC20Mint
 */
contract XUSDPrime is ERC20, ERC20Burnable, TokenRecover {

    //@dev decalre the initialSupply

    uint public initialSupply = 650500000000;

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
        require(!_mintingFinished, "XUSD Prime: minting is finished");
        _;
    }
    constructor (
        string memory name,
        string memory symbol)
        ERC20(name, symbol) {
        _setupDecimals(18);

        _mint(msg.sender, initialSupply);
    }

    /**
     * @return if minting is finished or not.
     */
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens
     * @param value The amount of tokens to mint
     */
    function mint(address to, uint256 value) public canMint onlyOwner {
        _mint(to, value);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}