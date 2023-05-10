// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCAMinter.sol";
import "contracts/utils/auth/ImmutableALCABurner.sol";
import "contracts/interfaces/IStakingToken.sol";
import "contracts/libraries/errors/StakingTokenErrors.sol";

/**
 * @notice This is the ERC20 implementation of the staking token used by the
 * AliceNet layer2 dapp.
 *
 */
contract ALCA is IStakingToken, ERC20, ImmutableFactory, ImmutableALCAMinter, ImmutableALCABurner {
    uint256 internal constant _CONVERSION_MULTIPLIER = 15_555_555_555_555_555_555_555_555_555;
    uint256 internal constant _CONVERSION_SCALE = 10_000_000_000_000_000_000_000_000_000;
    uint256 internal constant _INITIAL_MINT_AMOUNT = 244_444_444_444444444444444444;
    address internal immutable _legacyToken;
    bool internal _hasEarlyStageEnded;

    constructor(
        address legacyToken_
    )
        ERC20("AliceNet Staking Token", "ALCA")
        ImmutableFactory(msg.sender)
        ImmutableALCAMinter()
        ImmutableALCABurner()
    {
        _legacyToken = legacyToken_;
        _mint(msg.sender, _INITIAL_MINT_AMOUNT);
    }

    /**
     * Migrates an amount of legacy token (MADToken) to ALCA tokens
     * @param amount the amount of legacy token to migrate.
     */
    function migrate(uint256 amount) public returns (uint256) {
        return _migrate(msg.sender, amount);
    }

    /**
     * Migrates an amount of legacy token (MADToken) to ALCA tokens to a certain address
     * @param to the address that will receive the alca tokens
     * @param amount the amount of legacy token to migrate.
     */
    function migrateTo(address to, uint256 amount) public returns (uint256) {
        if (to == address(0)) {
            revert StakingTokenErrors.InvalidAddress();
        }
        return _migrate(to, amount);
    }

    /**
     * Allow the factory to turns off migration multipliers
     */
    function finishEarlyStage() public onlyFactory {
        _finishEarlyStage();
    }

    /**
     * Mints a certain amount of ALCA to an address. Can only be called by the
     * ALCAMinter role.
     * @param to the address that will receive the minted tokens.
     * @param amount the amount of legacy token to migrate.
     */
    function externalMint(address to, uint256 amount) public onlyALCAMinter {
        _mint(to, amount);
    }

    /**
     * Burns an amount of ALCA from an address. Can only be called by the
     * ALCABurner role.
     * @param from the account to burn the ALCA tokens.
     * @param amount the amount to burn.
     */
    function externalBurn(address from, uint256 amount) public onlyALCABurner {
        _burn(from, amount);
    }

    /**
     * Get the address of the legacy token.
     * @return the address of the legacy token (MADToken).
     */
    function getLegacyTokenAddress() public view returns (address) {
        return _legacyToken;
    }

    /**
     * gets the expected token migration amount
     * @param amount amount of legacy tokens to migrate over
     * @return the amount converted to ALCA*/
    function convert(uint256 amount) public view returns (uint256) {
        return _convert(amount);
    }

    /**
     * returns true if the early stage multiplier is still active
     */
    function isEarlyStageMigration() public view returns (bool) {
        return !_hasEarlyStageEnded;
    }

    function _migrate(address to, uint256 amount) internal returns (uint256 convertedAmount) {
        uint256 balanceBefore = IERC20(_legacyToken).balanceOf(address(this));
        IERC20(_legacyToken).transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(_legacyToken).balanceOf(address(this));
        if (balanceAfter <= balanceBefore) {
            revert StakingTokenErrors.InvalidConversionAmount();
        }
        uint256 balanceDiff = balanceAfter - balanceBefore;
        convertedAmount = _convert(balanceDiff);
        _mint(to, convertedAmount);
    }

    // Internal function to finish the early stage multiplier.
    function _finishEarlyStage() internal {
        _hasEarlyStageEnded = true;
    }

    // Internal function to convert an amount of MADToken to ALCA taking into
    // account the early stage multiplier.
    function _convert(uint256 amount) internal view returns (uint256) {
        if (_hasEarlyStageEnded) {
            return amount;
        } else {
            return _multiplyTokens(amount);
        }
    }

    // Internal function to compute the amount of ALCA in the early stage.
    function _multiplyTokens(uint256 amount) internal pure returns (uint256) {
        return (amount * _CONVERSION_MULTIPLIER) / _CONVERSION_SCALE;
    }
}