// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/ICollateralLiquidationReceiver.sol";

/**
 * @title No Operation Pool Configuration (for emergency pause on proxied
 * pools)
 * @author MetaStreet Labs
 */
contract NoopPool is ERC165 {
    /**
     * @notice Get implementation name
     * @return Implementation name
     */
    function IMPLEMENTATION_NAME() external pure virtual returns (string memory) {
        return "NoopPool";
    }

    /**
     * @notice Get implementation version
     * @return Implementation version
     */
    function IMPLEMENTATION_VERSION() external pure returns (string memory) {
        return "0.1";
    }

    /******************************************************/
    /* ERC165 interface */
    /******************************************************/

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ICollateralLiquidationReceiver).interfaceId || super.supportsInterface(interfaceId);
    }
}