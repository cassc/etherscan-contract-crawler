// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Badge} from "./Badge.sol";
import {IERC20, IAirdropHub} from "./interfaces/IAirdropHub.sol";

contract AirdropHub is Initializable, IAirdropHub, OwnableUpgradeable {
    // The minted flag by wallet address
    mapping(address => bool) private _mintedOf;

    Badge public badge;

    function initialize(Badge _badge) public initializer {
        if (_badge == Badge(address(0))) revert ZeroAddress();

        badge = _badge;

        __Ownable_init();
    }

    /**
     * @notice
     * Batch mint badge to given addresses.
     * Only minted once per address.
     *
     * @param _recipients The address list of recipients
     */
    function batchMint(address[] calldata _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; ) {
            // only mint once for each address
            if (_mintedOf[_recipients[i]]) revert Minted();
            badge.mint(_recipients[i]);
            _mintedOf[_recipients[i]] = true;

            unchecked {
                i++;
            }
        }

        emit BatchMint(_recipients);
    }

    /**
     * @notice
     * Giveaway erc20 token to users
     *
     * @param _rewardToken The given token address
     * @param _recipients The address list of recipients
     * @param _amounts The given amounts
     */
    function giveaway(
        IERC20 _rewardToken,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if (_rewardToken == IERC20(address(0))) revert ZeroAddress();
        if (_recipients.length != _amounts.length) revert SizeNotMatch();

        for (uint256 i = 0; i < _recipients.length; ) {
            _rewardToken.transferFrom(msg.sender, _recipients[i], _amounts[i]);

            unchecked {
                i++;
            }
        }

        emit Giveaway(_rewardToken, _recipients, _amounts);
    }
}