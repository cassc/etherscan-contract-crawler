// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/interfaces/IERC2981.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Royalty payments
 * @notice Support for the royalty standard (ERC-2981)
 */
abstract contract Royalties is IERC2981 {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Store information about token royalties
    struct RoyaltyInfo {
        address receiver;
        uint96 amount;
    }

    /// @dev The current royalty information
    RoyaltyInfo internal _royaltyInfo;

    /// @dev Interface id for the royalty information standard
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    bytes4 internal constant ROYALTY_INTERFACE_ID = 0x2a55205a;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error MoreThanOneHundredPercentRoyalty();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    event RoyaltyInfoSet(address indexed receiver, uint256 indexed amount);
    event RoyaltyInfoUpdated(address indexed receiver, uint256 indexed amount);

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param royaltiesReceiver The receiver of royalty payments
     * @param royaltiesAmount The royalty percentage with two decimals (10,000 = 100%)
     */
    constructor(address royaltiesReceiver, uint256 royaltiesAmount) {
        _royaltyInfo = RoyaltyInfo(royaltiesReceiver, uint96(royaltiesAmount));
        emit RoyaltyInfoSet(royaltiesReceiver, royaltiesAmount);
    }

    /* ------------------------------------------------------------------------
                                  E R C 2 9 8 1
    ------------------------------------------------------------------------ */

    /// @notice EIP-2981 royalty standard for on-chain royalties
    function royaltyInfo(uint256, uint256 salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyInfo.receiver;
        royaltyAmount = (salePrice * _royaltyInfo.amount) / 100_00;
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @dev Internal function to set the royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10,000 = 100%)
     */
    function _setRoyaltyInfo(address receiver, uint256 amount) internal {
        if (amount > 100_00) revert MoreThanOneHundredPercentRoyalty();
        _royaltyInfo = RoyaltyInfo(receiver, uint24(amount));
        emit RoyaltyInfoUpdated(receiver, amount);
    }
}