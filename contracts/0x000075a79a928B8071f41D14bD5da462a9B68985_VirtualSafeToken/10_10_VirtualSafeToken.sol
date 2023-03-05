// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Enum, BaseGuard, GuardManager} from "lib/safe-contracts/contracts/base/GuardManager.sol";
import {ModuleManager} from "lib/safe-contracts/contracts/base/ModuleManager.sol";
import {IProxy} from "lib/safe-contracts/contracts/proxies/SafeProxy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @title Virtual Safe Token.
/// @author z0r0z.eth
/// @custom:coauthor ellie.lens
/// @custom:coauthor 0xdapper
/// @notice Makes Safe Token (SAFE) opt-in transferable via tx guard.
/// Users can mint vSAFE equal to their SAFE while it is paused.
/// SAFE can be reclaimed from vSAFE pool by burning vSAFE.
contract VirtualSafeToken is BaseGuard, ERC20("Virtual Safe Token", "vSAFE", 18), Owned(tx.origin) {
    /// @dev Fired off when trusted master copy set for Safe guard check.
    event TrustedMasterCopySet(address masterCopy, bool trusted);

    /// @dev Fired off when trusted proxy hash set for Safe guard check.
    event TrustedProxySet(bytes32 proxyHash, bool trusted);

    /// @dev Canonical deployment of SAFE on Ethereum.
    address internal constant safeToken = 0x5aFE3855358E112B5647B952709E6165e1c1eEEe;

    /// @dev Internal flag to ensure this guard is enabled.
    uint256 internal guardCheck = 1;

    /// @dev Tracks active mint claims by Safes.
    mapping(address safe => bool minted) public active;

    /// @dev Trusted master copies.
    mapping(address => bool) public trustedMasterCopies;

    /// @dev Trusted Safe proxies.
    mapping(bytes32 => bool) public trustedProxies;

    /// @dev We can cut 10 opcodes in the creation-time
    /// EVM bytecode by declaring constructor payable.
    constructor() payable {}

    /// @dev Fetches whether SAFE is paused.
    function paused() public view returns (bool) {
        return VirtualSafeToken(safeToken).paused();
    }

    /// @dev Mints unclaimed vSAFE to SAFE holders.
    function mint(address to) external payable {
        // Ensure this call is by guarded Safe.
        require(guardCheck == 2, "UNGUARDED");

        // Reset guard value.
        guardCheck = 1;

        // Ensure no mint during transferable period.
        require(paused(), "UNPAUSED");

        // Ensure that SAFE custody is given to vSAFE to fund redemptions.
        require(ERC20(safeToken).allowance(msg.sender, address(this)) == type(uint256).max, "UNAPPROVED");

        // Ensure no double mint and mint vSAFE per SAFE balance.
        if (active[msg.sender] = true == !active[msg.sender]) {
            _mint(to, ERC20(safeToken).balanceOf(msg.sender));
        } else {
            revert("ACTIVE");
        }
    }

    /// @dev Burns an amount of vSAFE.
    function burn(uint256 amount) external payable {
        _burn(msg.sender, amount);
    }

    /// @dev Burns an amount of vSAFE to redeem SAFE.
    function redeem(address from, uint256 amount) external payable {
        ERC20(safeToken).transferFrom(from, msg.sender, amount);

        _burn(msg.sender, amount);
    }

    /// @dev Burns vSAFE to exit Safe guard conditions.
    /// Users renouncing should make sure they revoke
    /// SAFE allowance given at the time of minting. Otherwise,
    /// anyone can redeem against user's SAFE when they become
    /// transferable.
    function renounce() external payable {
        delete active[msg.sender];

        _burn(msg.sender, ERC20(safeToken).balanceOf(msg.sender));
    }

    /// @dev Called by a Safe before a transaction is executed.
    /// @param to Destination address of the Safe transaction.
    /// @param data Calldata of the Safe transaction.
    /// @param op Operation in Safe transaction.
    function checkTransaction(
        address to,
        uint256,
        bytes calldata data,
        Enum.Operation op,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address
    )
        external
        override
    {
        // Ensure no delegate call to run restricted code.
        require(op != Enum.Operation.DelegateCall, "RESTRICTED_CALL");

        // Ensure mint by guarded Safe.
        if (to == address(this)) {
            require(msg.sender.code.length > 0 && trustedProxies[msg.sender.codehash], "UNKNOWN_PROXY");
            require(trustedMasterCopies[IProxy(msg.sender).masterCopy()], "UNKNOWN_MASTER_COPY");
            require(_getNumberOfEnabledModules(msg.sender) == 0, "MODULES_ENABLED");

            guardCheck = 2;
        } else {
            if (active[msg.sender]) {
                // Ensure guard cannot be removed while active.
                if (to == msg.sender && data.length >= 4 && bytes4(data[:4]) == GuardManager.setGuard.selector) {
                    revert("RESTRICTED_FUNC");
                }

                // Ensure no calls to SAFE token.
                require(to != safeToken, "RESTRICTED_DEST");
            }
        }
    }

    /// @dev Internal Safe module fetch.
    function _getNumberOfEnabledModules(address safe) internal view returns (uint256) {
        (address[] memory modules,) = ModuleManager(safe).getModulesPaginated(address(0x1), 1);

        return modules.length;
    }

    /// @dev Placeholder for after-execution check in Safe guard.
    function checkAfterExecution(bytes32, bool) external view override {}

    /// @dev Operator sets trusted master copy for Safe guard check.
    function setTrustedMasterCopy(address masterCopy, bool trusted) external payable onlyOwner {
        trustedMasterCopies[masterCopy] = trusted;

        emit TrustedMasterCopySet(masterCopy, trusted);
    }

    /// @dev Operator sets trusted proxy hash for Safe guard check.
    function setTrustedProxy(bytes32 proxyHash, bool trusted) external payable onlyOwner {
        trustedProxies[proxyHash] = trusted;

        emit TrustedProxySet(proxyHash, trusted);
    }
}