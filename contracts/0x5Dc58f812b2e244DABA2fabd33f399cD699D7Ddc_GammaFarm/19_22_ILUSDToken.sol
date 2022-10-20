// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

import "IERC20.sol";

interface ILUSDToken is IERC20 {
    // --- Events ---
    event TroveManagerAddressChanged(address troveManagerAddress);
    event StabilityPoolAddressChanged(address newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address newBorrowerOperationsAddress);
    event LUSDTokenBalanceUpdated(address user, uint amount);

    // --- Functions ---
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function sendToPool(address sender,  address poolAddress, uint256 amount) external;
    function returnFromPool(address poolAddress, address receiver, uint256 amount) external;
    
    // --- EIP 2612 Functionality ---
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function domainSeparator() external view returns (bytes32);
    function permitTypeHash() external view returns (bytes32);

    // --- IERC20 Extra Functionality ---
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function version() external view returns (string memory);
}