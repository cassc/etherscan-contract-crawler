// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/permissioning/PermissioningLogic.sol";

interface IHumanboundPermissionLogic {
    /**
     * @dev Emitted when `operator` is updated in any way
     */
    event OperatorUpdated(address newOperator);

    /**
     * @notice Updates the `operator` to `newOperator`
     */
    function updateOperator(address newOperator) external;

    /**
     * @notice Returns the current `operator`
     */
    function getOperator() external returns (address);
}

abstract contract HumanboundPermissionExtension is IHumanboundPermissionLogic, PermissioningLogic {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    super.getSolidityInterface(),
                    "function updateOperator(address newOperator) external;\n"
                    "function getOperator() external returns(address);\n"
                )
            );
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](2);

        bytes4[] memory functions = new bytes4[](2);
        functions[0] = IHumanboundPermissionLogic.updateOperator.selector;
        functions[1] = IHumanboundPermissionLogic.getOperator.selector;

        interfaces[1] = super.getInterface()[0];
        interfaces[0] = Interface(type(IHumanboundPermissionLogic).interfaceId, functions);
    }
}