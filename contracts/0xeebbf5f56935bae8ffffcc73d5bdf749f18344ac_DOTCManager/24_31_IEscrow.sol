//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Interface for Escrow
 * @author Swarm
 */
interface IEscrow {
    /**
     * @dev Sets initial the deposit of the maker.
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     * - escrow must not be frozen
     *
     * @param _offerId uint256 the offer ID
     */
    function setMakerDeposit(uint256 _offerId) external;

    /**
     * @dev Withdraws deposit from the Escrow to to the taker address
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     * - escrow must not be frozen
     *
     * @param offerId the Id of the offer
     * @param orderId the order id
     *
     * @return bool
     */
    function withdrawDeposit(uint256 offerId, uint256 orderId) external returns (bool);

    /**
     * @dev Makes the escrow smart contract unactive
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param _account address that froze the escrow
     *
     * @return status bool
     */
    function freezeEscrow(address _account) external returns (bool);

    /**
     * @dev Sets dOTC Address
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *   - `_dOTC` != 0
     *
     * @param _dOTC dOTC address
     *
     * @return status bool
     */
    function setdOTCAddress(address _dOTC) external returns (bool);

    /**
     * @dev Freezes a singular offer on the escrow smart contract
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param frozenBy address
     *
     * @return status bool
     */
    function freezeOneDeposit(uint256 offerId, address frozenBy) external returns (bool);

    /**
     * @dev Unfreezes a singular offer on the escrow smart contract
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param unFrozenBy address
     *
     * @return status bool
     */
    function unFreezeOneDeposit(uint256 offerId, address unFrozenBy) external returns (bool);

    /**
     * @dev Sets the escrow to active
     *
     *   Requirments:
     *   - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param _account address that unfroze the escrow
     *
     * @return status bool
     */
    function unFreezeEscrow(address _account) external returns (bool status);

    /**
     * @dev Cancels deposit to escrow
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param offerId the Id of the offer
     * @param token the token from deposit
     * @param makerCpk maker's CPK address
     * @param _amountToSend the amount to send
     *
     * @return status bool
     */
    function cancelDeposit(
        uint256 offerId,
        IERC20Metadata token,
        address makerCpk,
        uint256 _amountToSend
    ) external returns (bool status);

    /**
     * @dev Returns the funds from the escrow to the maker
     *
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param account address
     * @param removedBy address
     *
     * @return status bool
     */
    function removeOffer(uint256 offerId, address account, address removedBy) external returns (bool status);
}