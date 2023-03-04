// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./IERC165.sol";
import "./IERC1633.sol";

abstract contract ITokenVault
    is 
        IERC20Upgradeable,
        IERC165,
        IERC1633
{
    event Acquired(address buyer, uint256 value);
    event Withdrawal(address from, uint256 value);

    /// @notice Returns whether this NFT vault has already been acquired. 
    function acquired() virtual external view returns (bool);

    /// @notice Address of the previous owner, the one that decided to fractionalize the NFT.
    function curator() virtual external view returns (address);

    /// @notice Redeems partial ownership of `parentTokenId` by providing valid ownership deeds.
    function redeem(bytes calldata deeds) virtual external;

    /// @notice Withdraw the proportional part of the acquisition value, according to caller's current balance.
    /// @dev Fails if not yet acquired. 
    function withdraw() virtual external returns (uint256);

    /// @notice Tells withdrawable amount in weis from given address.
    /// @dev Returns 0 in all cases while not yet acquired. 
    function withdrawableFrom(address from) virtual external view returns (uint256);
}