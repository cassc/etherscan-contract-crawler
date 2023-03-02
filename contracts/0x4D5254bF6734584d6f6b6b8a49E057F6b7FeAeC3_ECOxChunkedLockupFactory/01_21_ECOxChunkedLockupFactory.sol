// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IVestingVaultFactory} from "vesting/interfaces/IVestingVaultFactory.sol";
import {ECOxChunkedLockup} from "./ECOxChunkedLockup.sol";

contract ECOxChunkedLockupFactory is IVestingVaultFactory {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    address public immutable token;

    address public immutable staking;

    constructor(
        address _implementation,
        address _token,
        address _staking
    ) {
        implementation = _implementation;
        token = _token;
        staking = _staking;
    }

    /**
     * @notice Creates a new vesting vault
     * @param beneficiary The address who will receive tokens over time
     * @param admin The address that can claw back unvested funds
     * @param amounts The array of amounts to be vested at times in the timestamps array
     * @param timestamps The array of vesting timestamps for tokens in the amounts array
     * @return The address of the ECOxChunkedLockup contract created
     */
    function createVault(
        address beneficiary,
        address admin,
        uint256[] calldata amounts,
        uint256[] calldata timestamps
    ) public returns (address) {
        if (amounts.length != timestamps.length) revert InvalidParams();
        if (amounts.length == 0) revert InvalidParams();

        bytes memory data = abi.encodePacked(
            token,
            beneficiary,
            amounts.length,
            amounts,
            timestamps
        );
        ECOxChunkedLockup clone = ECOxChunkedLockup(implementation.clone(data));

        uint256 totalTokens = clone.vestedOn(type(uint256).max);
        IERC20Upgradeable(token).safeTransferFrom(
            msg.sender,
            address(this),
            totalTokens
        );
        IERC20Upgradeable(token).approve(address(clone), totalTokens);
        clone.initialize(admin, staking);
        emit VaultCreated(token, beneficiary, address(clone));
        return address(clone);
    }
}