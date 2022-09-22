// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./MntVotes.sol";

contract Mnt is ERC20, ERC20Permit, MntVotes {
    /// @notice Total number of tokens in circulation
    uint256 internal constant TOTAL_SUPPLY = 100_000_030e18; // 100,000,030 MNT

    constructor(address account, address admin) ERC20("Beta Minterest", "BMNT") ERC20Permit("Minterest") {
        _mint(account, uint256(TOTAL_SUPPLY));
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // The functions below are overrides required by Solidity.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, MntVotes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, MntVotes) {
        super._mint(to, amount);
    }

    // slither-disable-next-line dead-code
    function _burn(address, uint256) internal pure override(ERC20) {
        revert();
    }
}