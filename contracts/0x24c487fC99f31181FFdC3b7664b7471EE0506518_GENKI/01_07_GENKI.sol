// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IMintableERC20.sol";

/** @title GENKI
 * Samurai Saga Reward Token
 * http://samuraisaga.com
 */
contract GENKI is Ownable, ERC20, IMintableERC20 {
    // flag indicating if mint is completed.
    // once set to true, tokens can't be minted any more
    bool public isMintComplete;

    // mapping of addresses allowed to mint
    mapping(address => bool) private _minters;

    event MintDisable();
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    modifier onlyMinter() {
        require(_minters[_msgSender()], "GENKI: Not minter");
        _;
    }

    modifier whenMintingOpened() {
        require(!isMintComplete, "GENKI: Mint is complete");
        _;
    }

    constructor()
        ERC20("Samurai Saga Genki Token", "GENKI") {
    }

    /**
     * @notice Mint `amount` of tokens to `destination`
     * only callable by a valid minter
     */
    function mint(address destination, uint256 amount) external override onlyMinter whenMintingOpened {
        require(destination != address(0), "GENKI: Mint to address(0)");
        _mint(destination, amount);
    }

    /**
     * @notice returns true if `account` is a valid minter
     */
    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    /**
     * @notice Grant `account` to the list of allowed minters
     */
    function addMinter(address account) external onlyOwner {
        require(!_minters[account], "GENKI: Already minter");
        _minters[account] = true;
        emit MinterAdded(account);
    }

    /**
     * @notice Revoke `account` from the list of allowed minters
     */
    function removeMinter(address account) external onlyOwner {
        require(_minters[account], "GENKI: Not minter");
        _minters[account] = false;
        emit MinterRemoved(account);
    }

    /**
     * @notice Disable minting
     * once set to true, this flag can't be reverted and the supply can't be increased any more
     */
    function disableMinting() external onlyOwner {
        require(!isMintComplete, "GENKI: Mint already complete");
        isMintComplete = true;
        emit MintDisable();
    }
}