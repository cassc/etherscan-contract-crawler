//.██████..███████.███████.██.....██████..██████...██████.
//.██...██.██......██......██.....██...██.██...██.██....██
//.██████..█████...█████...██.....██████..██████..██....██
//.██...██.██......██......██.....██......██...██.██....██
//.██...██.███████.██......██.....██......██...██..██████.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IVaultConfig {
    function canDeposit(address _user, uint256 _assets) external view returns (bool);

    function isFeeEnabled(address _user) external view returns (bool);

    function entryFeeBps(address _user) external view returns (uint256);

    function exitFeeBps(address _user) external view returns (uint256);

    /// @dev management fee is the same for everyone
    // function managementFeeBps() external view returns (uint256);
}