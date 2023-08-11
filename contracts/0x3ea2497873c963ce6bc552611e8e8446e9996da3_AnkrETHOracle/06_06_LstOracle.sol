// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IMasterVault {
    function previewRedeem(uint256 shares) external view returns (uint256);
    function decimals() external view returns (uint256);
}
interface IRatioAdapter {
    function fromValue(address token, uint256 amount) external view returns (uint256);
    function toValue(address token, uint256 amount) external view returns (uint256);
}

// Abstract contract as base for any liquid staking master vault
abstract contract LstOracle is Initializable {

    IMasterVault internal masterVault; // master vault

    function __LstOracle__init(IMasterVault _masterVault) internal onlyInitializing {
        masterVault = _masterVault;
    }

    /**
     * Returns the latest price
     */
    function peek() public view returns (bytes32, bool) {
        (uint256 lsTokenPrice, bool isPositive) = _peekLstPrice();
        if (!isPositive) {
            return (0, isPositive);
        }

        // Get LST equivalent to 1 share in MasterVault
        uint256 vaultShares = masterVault.previewRedeem(1e18);
        uint256 sharePrice = (lsTokenPrice * vaultShares) / 1e18;

        return (bytes32(sharePrice), true);
    }

    function _peekLstPrice() internal virtual view returns (uint256, bool);
}