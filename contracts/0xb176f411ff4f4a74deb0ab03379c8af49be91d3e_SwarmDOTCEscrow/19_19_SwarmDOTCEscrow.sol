//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IEscrow.sol";
import "./interfaces/IdOTC.sol";
import "./structures/EscrowDepositStructures.sol";

/**
 * @title Escrow contract
 * @author Swarm
 */
contract SwarmDOTCEscrow is ERC1155Holder, AccessControl, IEscrow {
    ///@dev Freeze escrow
    /**
     * @dev Emmited when escrow frozen
     */
    event EscrowFrozen(address indexed frozenBy, address calledBy);
    /**
     * @dev Emmited when escrow unfrozen
     */
    event UnFreezeEscrow(address indexed unFreezeBy, address calledBy);

    ///@dev Offer escrow
    /**
     * @dev Emmited when offer frozen
     */
    event OfferFrozen(uint256 indexed offerId, address indexed offerOwner, address frozenBy);
    /**
     * @dev Emmited when offer unfrozen
     */
    event OfferUnfrozen(uint256 indexed offerId, address indexed offerOwner, address frozenBy);

    ///@dev Offer actions
    /**
     * @dev Emmited when offer removed
     */
    event OfferRemove(uint256 indexed offerId, address indexed offerOwner, uint256 amountReverted, address removedBy);
    /**
     * @dev Emmited when offer withdrawn
     */
    event OfferWithdrawn(uint256 indexed offerId, uint256 indexed orderId, address indexed taker, uint256 amount);
    /**
     * @dev Emmited when offer cancelled
     */
    event OfferCancelled(
        uint256 indexed offerId,
        IERC20Metadata indexed token,
        address indexed maker,
        uint256 _amountToSend
    );

    /**
     * @dev ESCROW_MANAGER_ROLE hashed string
     */
    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    /**
     * @dev BPSNUMBER used to standardize decimals
     */
    uint256 public constant BPSNUMBER = 10 ** 27;
    /**
     * @dev This  determine is the escrow is frozen
     */
    bool public isFrozen;

    // Private variables
    address internal dOTC;
    mapping(uint256 => OfferDeposit) private deposits;

    ///@dev Escrow need to be not frozen
    modifier escrowNotFrozen() {
        require(!isFrozen, "Escrow: escrow is Frozen");
        _;
    }

    ///@dev Only ESCROW_MANAGER_ROLE can call function with this modifier
    modifier onlyEscrowManager() {
        require(hasRole(ESCROW_MANAGER_ROLE, _msgSender()), "Escrow: must have escrow manager role");
        _;
    }

    ///@dev Offer need to be not frozen
    modifier depositNotFrozen(uint256 offerId) {
        require(!deposits[offerId].isFrozen, "Escrow: offer is frozen");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Grants ESCROW_MANAGER_ROLE to `_escrowManager`
     *
     * Requirements:
     * - the caller must have ``role``'s admin role
     */
    function setEscrowManager(address _escrowManager) public {
        grantRole(ESCROW_MANAGER_ROLE, _escrowManager);
    }

    /**
     * @dev Sets initial the deposit of the maker.
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     * - escrow must not be frozen
     *
     * @param _offerId uint256 the offer ID
     */
    function setMakerDeposit(uint256 _offerId) external onlyEscrowManager escrowNotFrozen {
        (, address cpk) = IdOTC(dOTC).getOfferOwner(_offerId);
        deposits[_offerId] = OfferDeposit(_offerId, cpk, IdOTC(dOTC).getOffer(_offerId).amountInAmountOut[0], false);
    }

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
    function withdrawDeposit(
        uint256 offerId,
        uint256 orderId
    ) external onlyEscrowManager escrowNotFrozen depositNotFrozen(offerId) returns (bool) {
        require(offerId == IdOTC(dOTC).getTakerOrders(orderId).offerId, "Escrow: offer and order ids are not correct");

        IERC20Metadata token = IERC20Metadata(IdOTC(dOTC).getOffer(offerId).tokenInTokenOut[0]);

        address _receiver = IdOTC(dOTC).getTakerOrders(orderId).takerAddress;
        uint256 standardAmount = IdOTC(dOTC).getTakerOrders(orderId).amountToReceive;
        uint256 minExpectedAmount = IdOTC(dOTC).getTakerOrders(orderId).minExpectedAmount;
        uint256 amount = unstandardisedNumber(standardAmount, token);
        require(amount > 0, "Escrow: Amount <= 0");

        require(
            deposits[offerId].amountDeposited >= standardAmount,
            "Escrow: Deposited amount must be >= standardAmount"
        );
        require(minExpectedAmount <= standardAmount, "Escrow: minExpectedAmount must be <= standardAmount");

        deposits[offerId].amountDeposited -= standardAmount;

        safeInternalTransfer(token, _receiver, amount);

        emit OfferWithdrawn(offerId, orderId, _receiver, amount);

        return true;
    }

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
    ) external onlyEscrowManager returns (bool status) {
        require(makerCpk != address(0) && address(token) != address(0), "Escrow: Passed zero addresses");

        deposits[offerId].amountDeposited = 0;

        safeInternalTransfer(token, msg.sender, _amountToSend);

        emit OfferCancelled(offerId, token, makerCpk, _amountToSend);

        return true;
    }

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
    function freezeEscrow(address _account) external onlyEscrowManager returns (bool status) {
        isFrozen = true;

        emit EscrowFrozen(msg.sender, _account);

        return true;
    }

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
    function unFreezeEscrow(address _account) external onlyEscrowManager returns (bool status) {
        isFrozen = false;

        emit UnFreezeEscrow(msg.sender, _account);

        return true;
    }

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
    function setdOTCAddress(address _dOTC) external onlyEscrowManager returns (bool status) {
        require(_dOTC != address(0), "Escrow: Passed zero address");

        dOTC = _dOTC;

        return true;
    }

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
    function freezeOneDeposit(uint256 offerId, address frozenBy) external onlyEscrowManager returns (bool status) {
        deposits[offerId].isFrozen = true;

        emit OfferFrozen(offerId, deposits[offerId].maker, frozenBy);

        return true;
    }

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
    function unFreezeOneDeposit(uint256 offerId, address unFrozenBy) external onlyEscrowManager returns (bool status) {
        deposits[offerId].isFrozen = false;

        emit OfferUnfrozen(offerId, deposits[offerId].maker, unFrozenBy);

        return true;
    }

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
    function removeOffer(
        uint256 offerId,
        address account,
        address removedBy
    ) external onlyEscrowManager returns (bool status) {
        IERC20Metadata token = IERC20Metadata(IdOTC(dOTC).getOffer(offerId).tokenInTokenOut[0]);
        uint256 _amount = unstandardisedNumber(deposits[offerId].amountDeposited, token);

        OfferDeposit storage deposit = deposits[offerId];
        deposit.isFrozen = true;
        deposit.amountDeposited = 0;

        safeInternalTransfer(token, account, _amount);

        emit OfferRemove(offerId, deposit.maker, _amount, removedBy);

        return true;
    }

    /**
     * @dev Checks interfaces support
     * @dev AccessControl, ERC1155Receiver overrided
     *
     * @return bool
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function standardiseNumber(uint256 amount, IERC20Metadata _token) internal view returns (uint256) {
        uint8 decimal = _token.decimals();
        return (amount * BPSNUMBER) / 10 ** decimal;
    }

    function unstandardisedNumber(uint256 _amount, IERC20Metadata _token) internal view returns (uint256) {
        uint8 decimal = _token.decimals();
        return (_amount * 10 ** decimal) / BPSNUMBER;
    }

    /**
     * @dev safeInternalTransfer Asset from the escrow; revert transaction if failed
     * @param token address
     * @param _receiver address
     * @param _amount uint256
     */
    function safeInternalTransfer(IERC20Metadata token, address _receiver, uint256 _amount) internal {
        require(_amount > 0, "Escrow: Amount == 0");
        require(token.transfer(_receiver, _amount), "Escrow: Transfer failed and reverted");
    }
}