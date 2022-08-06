// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract FIEF is ERC20PresetMinterPauser {

    uint256 public constant MAX_CAP = 500_000_000 * 10 ** 18;

    constructor(
        address adminRole,
        address minterAddress,
        address pauserAddress
    ) ERC20PresetMinterPauser("Fief", "FIEF") {
        _setupRole(DEFAULT_ADMIN_ROLE, adminRole);
        _setupRole(MINTER_ROLE, minterAddress);
        _setupRole(PAUSER_ROLE, pauserAddress);

        // By default msg.sender is admin, minter and pauser. So, we revoke all these roles for the sender.
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _revokeRole(MINTER_ROLE, _msgSender());
        _revokeRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public override {
        require(totalSupply() + amount <= MAX_CAP, "exceeds_max_supply");
        super.mint(to, amount);
    }
}