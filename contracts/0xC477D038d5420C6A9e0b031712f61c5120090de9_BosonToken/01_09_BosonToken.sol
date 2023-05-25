// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.6.6;

import "./ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BosonToken is ERC20Permit, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 private constant ONE_MILLION = 1 * 10**6;

    constructor(
        string memory name,
        string memory symbol,
        address _initialTokenOwner
    ) public ERC20Permit(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _mint(_initialTokenOwner, 200 * ONE_MILLION * 1 ether);
    }

    /**
     * @notice When Token contract is paused, no Token interactions are possible (e.g. approve, transfer, transferFrom or permit)
     * Requirements:
     *
     * - Caller must have PAUSER_ROLE
     */
    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @notice When Token contract is unpaused, all Token interactions can be executed (e.g. approve, transfer, transferFrom or permit)
     * Requirements:
     *
     * - Caller must have PAUSER_ROLE
     */
    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have pauser role to unpause"
        );
        _unpause();
    }
}