// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @custom:salt ALCAMinter
/// @custom:deploy-type deployUpgradeable
contract ALCAMinter is ImmutableALCA, IStakingTokenMinter {
    error MintingExceeds1Billion(uint256 currentSupply);
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    constructor() ImmutableFactory(msg.sender) ImmutableALCA() IStakingTokenMinter() {}

    /**
     * @notice Mints ALCAs
     * @param to_ The address to where the tokens will be minted
     * @param amount_ The amount of ALCAs to be minted
     * */
    function mint(address to_, uint256 amount_) public onlyFactory {
        // calls the alca for current supply
        uint256 currentSupply = IERC20(_alcaAddress()).totalSupply();
        // revert if the current supply plus the amount to mint is greater than 1 billion
        if (currentSupply + amount_ > MAX_SUPPLY) {
            revert MintingExceeds1Billion(currentSupply);
        }
        IStakingToken(_alcaAddress()).externalMint(to_, amount_);
    }

    /**
     * @notice gets the current supply of ALCAs
     */
    function totalSupply() public view returns (uint256) {
        return IERC20(_alcaAddress()).totalSupply();
    }
}