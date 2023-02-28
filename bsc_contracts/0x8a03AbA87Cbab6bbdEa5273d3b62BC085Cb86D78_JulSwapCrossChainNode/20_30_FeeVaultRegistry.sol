// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../lib/Ownable.sol";

/**
 * @title Allows the owner to set fee account
 * @author Padoriku
 */
abstract contract FeeVaultRegistry is Ownable, Initializable {
    address public feeVault;

    event FeeVaultUpdated(address from, address to);

    function initFeeVaultRegistry(address _vault) internal onlyInitializing {
        _setFeeVault(_vault);
    }

    function setFeeVault(address _vault) external onlyOwner {
        _setFeeVault(_vault);
    }

    function _setFeeVault(address _vault) private {
        address oldFeeCollector = feeVault;
        feeVault = _vault;
        emit FeeVaultUpdated(oldFeeCollector, _vault);
    }
}