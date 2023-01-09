// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../Interfaces/IERC20.sol";
import "../Interfaces/IERC2612.sol";

interface IARTHValuecoin is IERC20, IERC2612 {
    // --- Events ---
    event BorrowerOperationsAddressToggled(
        address borrowerOperations,
        bool oldFlag,
        bool newFlag,
        uint256 timestamp
    );
    event TroveManagerToggled(address troveManager, bool oldFlag, bool newFlag, uint256 timestamp);
    event StabilityPoolToggled(address stabilityPool, bool oldFlag, bool newFlag, uint256 timestamp);
    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event ARTHTokenBalanceUpdated(address _user, uint256 _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function toggleBorrowerOperations(address borrowerOperations) external;

    function toggleTroveManager(address troveManager) external;

    function toggleStabilityPool(address stabilityPool) external;

    function sendToPool(
        address _sender,
        address poolAddress,
        uint256 _amount
    ) external;

    function returnFromPool(
        address poolAddress,
        address user,
        uint256 _amount
    ) external;
}