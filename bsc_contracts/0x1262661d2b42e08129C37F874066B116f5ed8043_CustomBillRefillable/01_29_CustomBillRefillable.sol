// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./interfaces/ICustomBillRefillable.sol";
import "./CustomBill.sol";

/// @title CustomBillRefillable
/// @author ApeSwap.Finance
/// @notice Provides a method of refilling CustomBill contracts without needing owner rights
/// @dev Extends CustomBill
contract CustomBillRefillable is ICustomBillRefillable, CustomBill, AccessControlEnumerableUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    
    event BillRefilled(address payoutToken, uint256 amountAdded);

    bytes32 public constant REFILL_ROLE = keccak256("REFILL_ROLE");

    function initialize(
        ICustomTreasury _customTreasury,
        BillCreationDetails memory _billCreationDetails,
        BillTerms memory _billTerms,
        BillAccounts memory _billAccounts,
        address[] memory _billRefillers
    ) external {
        super.initialize(
            _customTreasury,
            _billCreationDetails,
            _billTerms,
            _billAccounts
        );

        for (uint i = 0; i < _billRefillers.length; i++) {
            _grantRole(REFILL_ROLE, _billRefillers[i]);
        }
    }

    /**
     * @notice Grant the ability to refill the CustomBill to whitelisted addresses
     * @param _billRefillers Array of addresses to whitelist as bill refillers
     */
    function grantRefillRole(address[] calldata _billRefillers) external override onlyOwner {
        for (uint i = 0; i < _billRefillers.length; i++) {
            _grantRole(REFILL_ROLE, _billRefillers[i]);
        }
    }

    /**
     * @notice Revoke the ability to refill the CustomBill to whitelisted addresses
     * @param _billRefillers Array of addresses to revoke as bill refillers
     */
    function revokeRefillRole(address[] calldata _billRefillers) external override onlyOwner {
        for (uint i = 0; i < _billRefillers.length; i++) {
            _revokeRole(REFILL_ROLE, _billRefillers[i]);
        }
    }

    /**
     *  @notice Transfer payoutTokens from sender to customTreasury and update maxTotalPayout
     *  @param _refillAmount amount of payoutTokens to refill the CustomBill with 
     */
    function refillPayoutToken(uint256 _refillAmount) external override nonReentrant onlyRole(REFILL_ROLE) {
        require(_refillAmount > 0, "Amount is 0");
        require(customTreasury.billContract(address(this)), "Bill is disabled");
        uint256 balanceBefore = payoutToken.balanceOf(address(customTreasury));
        payoutToken.safeTransferFrom(msg.sender, address(customTreasury), _refillAmount);
        uint256 refillAmount = payoutToken.balanceOf(address(customTreasury)) - balanceBefore;
        require(refillAmount > 0, "No refill made");
        uint256 maxTotalPayout = terms.maxTotalPayout + refillAmount;
        terms.maxTotalPayout = maxTotalPayout;
        emit BillRefilled(address(payoutToken), refillAmount);
        emit MaxTotalPayoutChanged(maxTotalPayout);
    }
}