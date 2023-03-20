// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./utils/Governable.sol";
import "./interfaces/ISGT.sol";

/**s
 * @title Solace Governance Token (SGT)
 * @author solace.fi
 * @notice The native governance token of the Solace Coverage Protocol.
 */
contract SGT is ISGT, ERC20Permit, Governable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using Address for address;

    // Minters
    EnumerableSet.AddressSet private _minters;

    /**
     * @notice Constructs the Solace Token contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) ERC20("Solace Governance Token", "SGT") ERC20Permit("Solace Governance Token") Governable(governance_) { }

    /**
     * @notice Returns true if `account` is authorized to mint [**SOLACE**](./SOLACE).
     * @param account Account to query.
     * @return status True if `account` can mint, false otherwise.
     */
    function isMinter(address account) external view override returns (bool status) {
        return _minters.contains(account);
    }

    /**
     * @notice Returns true minter count.
     * @return count The number of minters.
     */
    function numOfMinters() external view override returns (uint256 count) {
        return _minters.length();
    }

    /**
     * @notice Returns minters.
     * @return minterAdddresses The minter addresses.
     */
    function minters() external view override returns (address[] memory minterAdddresses) {
        return _minters.values();
    }

    /**
     * @notice Mints new [**SOLACE**](./SOLACE) to the receiver account.
     * Can only be called by authorized minters.
     * @param account The receiver of new tokens.
     * @param amount The number of new tokens.
     */
    function mint(address account, uint256 amount) external override {
        // can only be called by authorized minters
        require(_minters.contains(msg.sender), "!minter");
        // mint
        _mint(account, amount);
    }

    /**
     * @notice Burns [**SOLACE**](./SOLACE) from msg.sender.
     * @param amount Amount to burn.
     */
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Adds a new minter.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param minter The new minter.
     */
    function addMinter(address minter) external onlyGovernance override {
        require(minter != address(0x0), "zero address");
        require(!_minters.contains(minter), "already minter");
        _minters.add(minter);
        emit MinterAdded(minter);
    }

    /**
     * @notice Removes a minter.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param minter The minter to remove.
     */
    function removeMinter(address minter) external onlyGovernance override {
        require(_minters.contains(minter), "not a minter");
        _minters.remove(minter);
        emit MinterRemoved(minter);
    }

}