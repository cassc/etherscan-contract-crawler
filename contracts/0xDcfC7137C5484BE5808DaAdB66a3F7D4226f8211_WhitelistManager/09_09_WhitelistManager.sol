// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./Errors.sol";

/// @dev When the owner sets the Whitelist Manager address in the Loan Vault, the Whitelist Manager is enabled
contract WhitelistManager is OwnableUpgradeable {
    event ModifyWhitelist();

    /// @dev Addresses which are allowed to deposit into the vault; address => whitelisted status [true/false]
    mapping(address => bool) private whitelist;

    // interface to ERC721 integration to access balanceOf
    IERC721Upgradeable public lobs;

    // interface to ERC1155 integration to access balanceOf
    IERC1155Upgradeable public beacon;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line

    function initialize() external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function modifyWhitelist(address[] calldata depositors, bool whitelisted) external onlyOwner {
        for (uint256 i = 0; i < depositors.length; i++) {
            whitelist[depositors[i]] = whitelisted;
        }
        emit ModifyWhitelist();
    }

    function isDepositorWhitelisted(address depositor) public view returns (bool) {
        return isOnWhitelist(depositor) || hasLobs(depositor) || hasBeacon(depositor);
    }

    function setLobsAddress(IERC721Upgradeable _lobs) external onlyOwner {
        lobs = _lobs;
    }

    function setBeaconAddress(IERC1155Upgradeable _beacon) external onlyOwner {
        beacon = _beacon;
    }

    function isOnWhitelist(address depositor) public view returns (bool) {
        return whitelist[depositor];
    }

    // lobs = 0x026224A2940bFE258D0dbE947919B62fE321F042
    function hasLobs(address depositor) public view returns (bool) {
        if (address(lobs) != address(0)) {
            try IERC721Upgradeable(lobs).balanceOf(depositor) returns (uint256 result) {
                return result > 0;
            } catch {
                return false;
            }
        }
        return false;
    }

    // beacon = 0x0521FA0bf785AE9759C7cB3CBE7512EbF20Fbdaa
    function hasBeacon(address _address) public view returns (bool) {
        if (address(beacon) != address(0)) {
            try IERC1155Upgradeable(beacon).balanceOf(_address, 0) returns (uint256 result) {
                return result > 0;
            } catch {
                return false;
            }
        }
        return false;
    }
}