// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IBlockMelonMarketConfig.sol";

abstract contract BlockMelonMarketConfig is
    IBlockMelonMarketConfig,
    Initializable
{
    /// @notice Emitted when the market fees are updated
    event MarketFeesUpdated(
        uint256 primaryBlockMelonFeeInBps,
        uint256 secondaryBlockMelonFeeInBps,
        uint256 secondaryCreatorFeeInBps,
        uint256 secondaryFirstOwnerFeeInBps
    );

    /// @dev Fees that BlockMelon recieves after the primary sale
    uint256 private _primaryBlockMelonFeeInBps;
    /// @dev Fees that BlockMelon recieves after secondary a secondary sale
    uint256 private _secondaryBlockMelonFeeInBps;
    /// @dev Fees that the token creator recieves after a secondary sale
    uint256 private _secondaryCreatorFeeInBps;
    /// @dev Fees that the very first owner of a token recieves after a secondary sale
    uint256 private _secondaryFirstOwnerFeeInBps;
    uint256 private constant BASIS_POINTS = 10000;

    function __BlockMelonMarketConfig_init_unchained(
        uint256 primaryBlockMelonFeeInBps,
        uint256 secondaryBlockMelonFeeInBps,
        uint256 secondaryCreatorFeeInBps,
        uint256 secondaryFirstOwnerFeeInBps
    ) internal onlyInitializing {
        _updateFeesConfig(
            primaryBlockMelonFeeInBps,
            secondaryBlockMelonFeeInBps,
            secondaryCreatorFeeInBps,
            secondaryFirstOwnerFeeInBps
        );
    }

    /**
     * @dev See {IBlockMelonMarketConfig-getFeeConfig}
     */
    function getFeeConfig()
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _primaryBlockMelonFeeInBps,
            _secondaryBlockMelonFeeInBps,
            _secondaryCreatorFeeInBps,
            _secondaryFirstOwnerFeeInBps
        );
    }

    function _updateFeesConfig(
        uint256 primaryBlockMelonFeeInBps,
        uint256 secondaryBlockMelonFeeInBps,
        uint256 secondaryCreatorFeeInBps,
        uint256 secondaryFirstOwnerFeeInBps
    ) internal {
        require(
            primaryBlockMelonFeeInBps < BASIS_POINTS,
            "primary fee >= 100%"
        );
        require(
            secondaryBlockMelonFeeInBps +
                secondaryCreatorFeeInBps +
                secondaryFirstOwnerFeeInBps <
                BASIS_POINTS,
            "secondary fees >= 100%"
        );
        _primaryBlockMelonFeeInBps = primaryBlockMelonFeeInBps;
        _secondaryBlockMelonFeeInBps = secondaryBlockMelonFeeInBps;
        _secondaryCreatorFeeInBps = secondaryCreatorFeeInBps;
        _secondaryFirstOwnerFeeInBps = secondaryFirstOwnerFeeInBps;

        emit MarketFeesUpdated(
            primaryBlockMelonFeeInBps,
            secondaryBlockMelonFeeInBps,
            secondaryCreatorFeeInBps,
            secondaryFirstOwnerFeeInBps
        );
    }

    uint256[50] private __gap;
}