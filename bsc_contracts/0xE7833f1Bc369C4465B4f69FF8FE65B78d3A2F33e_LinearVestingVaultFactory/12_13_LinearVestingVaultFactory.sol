// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ClonesWithImmutableArgs} from
    "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {LinearVestingVault} from "./LinearVestingVault.sol";
import {IVestingVaultFactory} from "./interfaces/IVestingVaultFactory.sol";

contract LinearVestingVaultFactory is IVestingVaultFactory {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @notice Creates a new vesting vault
     * @param token The ERC20 token to vest over time
     * @param beneficiary The address who will receive tokens over time
     * @param startTimestamp The time at which vesting starts(ed )
     * @param endTimestamp The time at which vesting ends
     * @param amount The amount of tokens to vest
     */
    function createVault(
        address token,
        address beneficiary,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 amount
    )
        public
        returns (address)
    {
        bytes memory data = abi.encodePacked(
            token, beneficiary, startTimestamp, endTimestamp, amount
        );
        LinearVestingVault clone =
            LinearVestingVault(implementation.clone(data));

        IERC20Upgradeable(token).safeTransferFrom(
            msg.sender, address(this), amount
        );
        IERC20Upgradeable(token).approve(address(clone), amount);
        clone.initialize();

        emit VaultCreated(token, beneficiary, address(clone));
        return address(clone);
    }
}