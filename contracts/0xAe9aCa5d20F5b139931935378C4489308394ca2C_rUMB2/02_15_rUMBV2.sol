//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// Inheritance
import "./SwappableTokenV2.sol";
import "./MintableToken.sol";


/// @title   Umbrella Rewards contract
/// @author  umb.network
/// @notice  This is reward UMB token (rUMB)
/// @dev     Rewards tokens are used for farming and other rewards distributions.
abstract contract rUMBV2 is MintableToken, SwappableTokenV2 {
    // ========== STATE VARIABLES ========== //

    // ========== CONSTRUCTOR ========== //

    constructor (
        address _owner,
        uint256 _maxAllowedTotalSupply,
        uint32 _swapStartsOn,
        uint32 _dailyCup,
        string memory _name,
        string memory _symbol,
        address _umb
    )
        Owned(_owner)
        ERC20(_name, _symbol)
        MintableToken(_maxAllowedTotalSupply)
        SwappableTokenV2(_umb, _swapStartsOn, _dailyCup) {}
}