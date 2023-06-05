//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "./interfaces/IdOTC.sol";
import "./permissions/AdminFunctions.sol";

/**
 * @title DOTCManager contract
 * @author Swarm
 */
contract DOTCManager is Initializable, ReentrancyGuardUpgradeable, ERC1155HolderUpgradeable, AdminFunctions, IdOTC {
    ///@notice dOTC's events
    /**
     * @dev Emitted when a new offer is created.
     */
    event CreatedOffer(
        uint256 indexed offerId,
        address indexed maker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        OfferType offerType,
        address specialAddress,
        uint256 expiryTime,
        uint256 timelockPeriod,
        bool isCompleted
    );
    /**
     * @dev Emitted when a new offer is created.
     */
    event CreatedOrder(
        uint256 indexed offerId,
        uint256 indexed orderId,
        address indexed orderedBy,
        uint256 amountToReceive,
        uint amountPaid
    );
    /**
     * @dev Emitted when an offer is completed.
     */
    event CompletedOffer(uint256 offerId);
    /**
     * @dev Emitted when an offer is canceled.
     */
    event CanceledOffer(uint256 indexed offerId, address canceledBy, uint256 amountToReceive);
    /**
     * @dev Emitted when an offer is frozen.
     */
    event OfferFrozen(uint256 indexed offerId, address frozenBy);
    /**
     * @dev Emitted when an offer is un frozen.
     */
    event OfferUnFrozen(uint256 indexed offerId, address unFrozenBy);
    /**
     * @dev Emitted when an admin removed offer.
     */
    event AdminRemoveOffer(uint256 indexed offerId, address frozenBy);
    /**
     * @dev Emitted when an offer updated.
     */
    event TokenOfferUpdated(uint256 indexed offerId, uint256 newOffer);
    /**
     * @dev Emitted when an expiry offer updated.
     */
    event UpdatedTokenOfferExpiry(uint256 indexed offerId, uint256 newExpiryTimestamp);
    /**
     * @dev Emitted when an admin removed offer.
     */
    event UpdatedTimeLockPeriod(uint256 indexed offerId, uint256 newTimelockPeriod);

    /**
     * @dev takerOrders this is store partial offer takers,
     *  ref the offerId  to the taker address and ref the amount paid
     */
    mapping(uint256 => Order) internal takerOrders;
    /**
     * @dev All offers that have ever been created
     */
    mapping(uint256 => dOTCOffer) internal allOffers;
    /**
     * @dev All offers that have ever been created by some address
     */
    mapping(address => dOTCOffer[]) internal offersFromAddress;
    /**
     * @dev All offers that have ever been taken by some address
     */
    mapping(address => dOTCOffer[]) internal takenOffersFromAddress;
    /**
     * @dev Timelock period
     */
    mapping(uint256 => uint256) internal timelock;

    // Private variables
    uint256 private _offerId;
    uint256 private _takerOrdersId;

    /**
     * @dev Asset is Approve on the Swarm DOTC Market
     * @param tokenAddress address
     */
    modifier allowedERC20Asset(address tokenAddress) {
        require(tokenListManager.allowedErc20tokens(tokenAddress) > 0, "dOTC: This token is not allowed");
        _;
    }

    /**
     * @dev Checks if sender account is suspended on the swarm market protocol
     */
    modifier notSuspended() {
        require(!permissionManager.isSuspended(msg.sender), "dOTC: Your account is suspended");
        _;
    }

    /**
        @dev notExpired check if an Order is Active
        @param offerId uint256
    */
    modifier notExpired(uint256 offerId) {
        require(isExpired(offerId), "dOTC: This offer is already expired");
        _;
    }

    /**
        @dev timelockPassed check if an offer is in timelock
        @param offerId uint256
    */
    modifier timelockPassed(uint256 offerId) {
        require(isInTimelock(offerId), "dOTC: This offer is in timelock");
        _;
    }

    /**
     * @dev Check if an offer can be cancelled
     * @param id uint256 id of the offer
     */
    modifier canBeCancelled(uint256 id) {
        require(allOffers[id].cpk == msg.sender, "dOTC: dOTCOffer can not be cancelled");
        _;
    }

    /**
     * @dev Check if an offer is special dOTCOffer assigined to a particular user
     * @param offerId uint256
     */
    modifier isSpecial(uint256 offerId) {
        if (allOffers[offerId].specialAddress != address(0)) {
            require(allOffers[offerId].specialAddress == msg.sender, "dOTC: You are not a designated buyer");
        }
        _;
    }

    /**
     * @dev Check if the offer is available
     */
    modifier isAvailable(uint256 offerId) {
        require(allOffers[offerId].amountInAmountOut[0] > 0, "dOTC: dOTCOffer not found");
        _;
    }

    /**
     * @notice dOTC constructor
     *
     * @dev Grants DEFAULT_ADMIN_ROLE to the deployer
     *
     * @param _tokenListManager address of TokenListManager contract
     * @param _permissionManager address of PermissionManagerV2 contract
     */
    function initialize(
        ITokenListManager _tokenListManager,
        IPermissionManagerV2 _permissionManager,
        IXTokenWrapper _wrapper
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __ERC1155Holder_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tokenListManager = _tokenListManager;
        permissionManager = _permissionManager;
        wrapper = _wrapper;

        feeAmount = 3 * 10 ** 24;
    }

    /**
     * @dev MakeOffer this create an dOTCOffer which can be sell or buy
     * @dev Provided `tokenInTokenOut` and `amountInAmountOut` arrays to prevent functions parameters limit
     *
     *  Requirements:
     *  - msg.sender must be a Tier 2
     *  - _tokenInAddress and _tokenOutAddress must be allowed on swarm market
     *   - expiration timestamp must not be expired
     *   - timelock period must not be expired
     *
     * @param  tokenInTokenOut[0] - tokenIn
     * @param  tokenInTokenOut[1] - tokenOut
     * @param  amountInAmountOut[0] - amountIn
     * @param  amountInAmountOut[1] - amountOut
     * @param  _expiryTimestamp uint256 in Days
     * @param  _offerType uint8 is the offer PARTIAL or FULL
     * @param _specialAddress special Adress of taker and if specified
     *  only this address can take the offer else anyone can take the offer
     *
     * @return offerId uint256
     */
    function makeOffer(
        address maker,
        address[2] memory tokenInTokenOut,
        uint256[2] memory amountInAmountOut,
        uint8 _offerType,
        address _specialAddress,
        uint256 _expiryTimestamp,
        uint256 _timelockPeriod
    )
        public
        allowedERC20Asset(tokenInTokenOut[0])
        allowedERC20Asset(tokenInTokenOut[1])
        notSuspended
        nonReentrant
        returns (uint256 offerId)
    {
        require(
            IERC20(tokenInTokenOut[0]).balanceOf(msg.sender) >= (amountInAmountOut[0]),
            "dOTC: You don't have enough tokens In"
        );
        require(tokenInTokenOut[0] != tokenInTokenOut[1], "dOTC: Token In same as Token Out");
        require(_expiryTimestamp > block.timestamp, "dOTC: Expiration timestamp has already expired");
        require(_timelockPeriod == 0 || _timelockPeriod > block.timestamp, "dOTC: Timelock period has already expired");
        require(_offerType <= uint8(OfferType.FULL), "dOTC: dOTCOffer type out of range");
        require(amountInAmountOut[0] > 0, "dOTC: Passed amount In = 0");
        require(amountInAmountOut[1] > 0, "dOTC: Passed amount Out = 0");

        _offerId++;
        uint256 currentOfferId = _offerId;

        dOTCOffer memory _offer = setOffer(
            maker, // not CPK
            currentOfferId,
            tokenInTokenOut,
            amountInAmountOut,
            OfferType(_offerType),
            _specialAddress,
            _expiryTimestamp,
            _timelockPeriod
        );

        offersFromAddress[msg.sender].push(_offer);
        allOffers[currentOfferId] = _offer;

        escrow.setMakerDeposit(currentOfferId);

        // Sending xTokens from maker(CPK) to Escrow
        require(
            IERC20(tokenInTokenOut[0]).transferFrom(msg.sender, address(escrow), amountInAmountOut[0]),
            "dOTC: ERC20 Transfer from maker to Escrow failed"
        );

        emit CreatedOffer(
            currentOfferId,
            msg.sender,
            tokenInTokenOut[0],
            tokenInTokenOut[1],
            amountInAmountOut[0],
            amountInAmountOut[1],
            OfferType(_offerType),
            _specialAddress,
            _expiryTimestamp,
            _timelockPeriod,
            false
        );

        return currentOfferId;
    }

    function setOffer(
        address maker,
        uint256 _currentOfferId,
        address[2] memory tokenInTokenOut,
        uint256[2] memory amountInAmountOut,
        OfferType _offerType,
        address _specialAddress,
        uint256 _expiryTimestamp,
        uint256 _timelockPeriod
    ) internal view returns (dOTCOffer memory offer) {
        uint256[2] memory standardAmountInAmountOut;
        for (uint8 i = 0; i < 2; ++i) {
            standardAmountInAmountOut[i] = standardiseNumber(amountInAmountOut[i], tokenInTokenOut[i]);
        }

        dOTCOffer memory _offer = dOTCOffer({
            maker: maker,
            cpk: msg.sender,
            offerId: _currentOfferId,
            fullyTaken: false,
            tokenInTokenOut: tokenInTokenOut,
            amountInAmountOut: standardAmountInAmountOut,
            availableAmount: standardAmountInAmountOut[0],
            unitPrice: (standardAmountInAmountOut[1] * 10 ** DECIMAL) / standardAmountInAmountOut[0],
            offerType: _offerType,
            specialAddress: _specialAddress,
            expiryTime: _expiryTimestamp,
            timelockPeriod: _timelockPeriod
        });
        return _offer;
    }

    /**
     * @dev TakeOffer this take an dOTCOffer that is available
     *
     *  Requirements:
     *  - `msg.sender` must have tiers
     *  - `offerId` must be available
     *  - `offerId` must be not expired
     *
     * @param  offerId uint256
     * @param  amountToSend uint256
     *
     * @return takenOderId uint256
     */
    function takeOffer(
        uint256 offerId,
        uint256 amountToSend,
        uint256 minExpectedAmount
    )
        public
        notSuspended
        isSpecial(offerId)
        isAvailable(offerId)
        notExpired(offerId)
        nonReentrant
        returns (uint256 takenOderId)
    {
        dOTCOffer storage offer = allOffers[offerId];

        uint256 amountToReceive = 0;

        require(amountToSend > 0, "dOTC: Passed amountToSend = 0");
        require(
            standardiseNumber(amountToSend, offer.tokenInTokenOut[1]) <= offer.amountInAmountOut[1],
            "dOTC: amountToSend is too big"
        );
        require(
            IERC20(offer.tokenInTokenOut[1]).balanceOf(msg.sender) >= amountToSend,
            "dOTC: You don't have enough tokens Out"
        );

        if (offer.offerType == OfferType.FULL) {
            require(
                standardiseNumber(amountToSend, offer.tokenInTokenOut[1]) == offer.amountInAmountOut[1],
                "dOTC: Full request required"
            );
            amountToReceive = offer.amountInAmountOut[0];
            offer.amountInAmountOut[1] = 0;
            offer.availableAmount = 0;
            offer.fullyTaken = true;
            emit CompletedOffer(offerId);
        } else {
            if (standardiseNumber(amountToSend, offer.tokenInTokenOut[1]) == offer.amountInAmountOut[1]) {
                amountToReceive = offer.availableAmount;
                offer.amountInAmountOut[1] = 0;
                offer.availableAmount = 0;
                offer.fullyTaken = true;
                emit CompletedOffer(offerId);
            } else {
                amountToReceive =
                    (standardiseNumber(amountToSend, offer.tokenInTokenOut[1]) * 10 ** DECIMAL) /
                    offer.unitPrice;
                offer.amountInAmountOut[1] -= standardiseNumber(amountToSend, offer.tokenInTokenOut[1]);
                offer.availableAmount -= amountToReceive;
            }
            if (offer.amountInAmountOut[1] == 0 || offer.availableAmount == 0) {
                offer.fullyTaken = true;
                emit CompletedOffer(offerId);
            }
        }

        takenOffersFromAddress[msg.sender].push(offer);

        _takerOrdersId++;

        takerOrders[_takerOrdersId] = Order(
            offerId,
            amountToSend,
            msg.sender,
            amountToReceive,
            standardiseNumber(minExpectedAmount, offer.tokenInTokenOut[0])
        );

        uint256 feesAmount = (amountToSend * feeAmount) / BPSNUMBER;
        uint256 amountToPay = amountToSend - feesAmount;

        require(feesAmount > 0, "dOTC: Fees amount must be > 0");
        require(amountToPay > 0, "dOTC: Amount without fees must be > 0!");

        // Send tokenOut fees from taker to `feeAddress`
        require(
            IERC20(offer.tokenInTokenOut[1]).transferFrom(msg.sender, feeAddress, feesAmount),
            "dOTC: ERC20 fees transfer failed"
        );

        // Sending xTokens from Escrow to taker(CPK)
        require(escrow.withdrawDeposit(offerId, _takerOrdersId), "dOTC: Escrow transfer xTokens failed");

        // Transfer tokenOut from taker(CPK) to dOTC
        require(
            IERC20(offer.tokenInTokenOut[1]).transferFrom(msg.sender, address(this), amountToPay),
            "dOTC: ERC20 Transfer to dOTC failed"
        );

        // Because taker(CPK) transferred xTokens to dOTC we need to unwrap it and send to maker
        require(wrapper.unwrap(offer.tokenInTokenOut[1], amountToPay), "dOTC: Unwraping error");

        // Transfer unwrapped tokenOut from dOTC to maker
        require(
            IERC20(wrapper.xTokenToToken(offer.tokenInTokenOut[1])).transfer(offer.maker, amountToPay),
            "dOTC: ERC20 Transfer to maker failed"
        );

        uint256 realAmount = unstandardisedNumber(amountToReceive, IERC20MetadataUpgradeable(offer.tokenInTokenOut[0]));

        emit CreatedOrder(offerId, _takerOrdersId, msg.sender, realAmount, amountToSend);

        return _takerOrdersId;
    }

    /**
     * @dev Cancel an offer, refunds offer maker.
     *
     *  Requirements:
     *  - `msg.sender` must be a creator of this offer
     *  - `offerId` can be cancelled
     *  - `offerId` timelock must be expired
     *
     * @param offerId uint256 order id
     *
     * @return success bool
     */
    function cancelOffer(
        uint256 offerId
    ) external canBeCancelled(offerId) timelockPassed(offerId) nonReentrant returns (bool success) {
        dOTCOffer memory offer = allOffers[offerId];
        require(offer.cpk == msg.sender, "dOTC: only creator of this offer");

        address tokenIn = offer.tokenInTokenOut[0];

        uint256 _amountToSend = offer.availableAmount;
        uint256 realAmount = unstandardisedNumber(_amountToSend, IERC20MetadataUpgradeable(tokenIn));

        require(_amountToSend > 0, "dOTC: _amountToSend must be >= 0");
        require(
            escrow.cancelDeposit(offerId, IERC20Metadata(tokenIn), msg.sender, realAmount),
            "Escrow: dOTCOffer can not be cancelled"
        );

        // Because maker(CPK) transferred xTokens to Escrow we need to unwrap it and send to maker
        require(wrapper.unwrap(tokenIn, realAmount), "dOTC: Unwraping error");

        // Transfer unwrapped tokenOut from dOTC to maker
        address xTokenIn = wrapper.xTokenToToken(tokenIn);
        require(IERC20(xTokenIn).transfer(offer.maker, realAmount), "dOTC: ERC20 Transfer to maker failed");

        delete allOffers[offerId];
        emit CanceledOffer(offerId, msg.sender, _amountToSend);
        return true;
    }

    /**
     * @dev Update offer for tokenOut and amountOut
     *
     *   Requirements
     *   - `msg.sender` must be a creator of this offer
     *   - expiration timestamp must not be expired
     *   - timelock period must be expired
     *
     * @param offerId uint256
     * @param newAmount uint256
     * @param _expiryTimestamp uint256
     * @param _timelockPeriod uint256
     *
     * @return status bool
     */
    function updateOffer(
        uint256 offerId,
        uint256 newAmount,
        uint256 _expiryTimestamp,
        uint256 _timelockPeriod
    ) external timelockPassed(offerId) returns (bool status) {
        require(newAmount > 0, "dOTC: newOffer must be >= 0");
        require(
            _expiryTimestamp == 0 || _expiryTimestamp > block.timestamp,
            "dOTC: Expiration timestamp has already expired"
        );
        require(_timelockPeriod == 0 || _timelockPeriod > block.timestamp, "dOTC: Timelock period has already expired");
        require(allOffers[offerId].cpk == msg.sender, "dOTC: You are not the owner of this offer");

        uint256 standardNewOfferOut = standardiseNumber(newAmount, allOffers[offerId].tokenInTokenOut[1]);

        if (standardNewOfferOut != allOffers[offerId].amountInAmountOut[1]) {
            allOffers[offerId].amountInAmountOut[1] = standardNewOfferOut;
            allOffers[offerId].unitPrice =
                (standardiseNumber(newAmount, allOffers[offerId].tokenInTokenOut[1]) * 10 ** DECIMAL) /
                allOffers[offerId].availableAmount;
            emit TokenOfferUpdated(offerId, newAmount);
        }

        if (_expiryTimestamp != allOffers[offerId].expiryTime && _expiryTimestamp != 0) {
            allOffers[offerId].expiryTime = _expiryTimestamp;
            emit UpdatedTokenOfferExpiry(offerId, _expiryTimestamp);
        }

        if (_timelockPeriod != allOffers[offerId].timelockPeriod && _timelockPeriod != 0) {
            allOffers[offerId].timelockPeriod = _timelockPeriod;
            emit UpdatedTimeLockPeriod(offerId, _timelockPeriod);
        }

        return true;
    }

    /**
     *    @dev Checks if the expiry date is < now
     *
     *    @param offerId uint256
     *
     *    @return expired bool
     */
    function isExpired(uint256 offerId) public view returns (bool expired) {
        expired = allOffers[offerId].expiryTime > block.timestamp;
    }

    /**
     *    @dev Checks if the timelockPeriod is < now
     *
     *    @param offerId uint256
     *
     *    @return inTimelock bool
     */
    function isInTimelock(uint256 offerId) public view returns (bool inTimelock) {
        inTimelock = allOffers[offerId].timelockPeriod < block.timestamp;
    }

    /**
     * @dev All offers from an account
     *
     * @param account address
     *
     * @return dOTCOffer[] memory
     */
    function getOffersFromAddress(address account) external view returns (dOTCOffer[] memory) {
        return offersFromAddress[account];
    }

    /**
     * @dev All offers from an account
     *
     * @param account address
     *
     * @return dOTCOffer[] memory
     */
    function getTakenOffersFromAddress(address account) external view returns (dOTCOffer[] memory) {
        return takenOffersFromAddress[account];
    }

    /**
     * @dev Returns the address of the maker
     *
     * @param offerId uint256 the Id of the order
     *
     * @return maker address
     * @return cpk address
     */
    function getOfferOwner(uint256 offerId) external view returns (address maker, address cpk) {
        maker = allOffers[offerId].maker;
        cpk = allOffers[offerId].cpk;
    }

    /**
     * @dev Returns the address of the taker
     *
     * @param orderId uint256 the id of the order
     *
     * @return taker address
     */
    function getTaker(uint256 orderId) external view returns (address taker) {
        return takerOrders[orderId].takerAddress;
    }

    /**
     * @dev Returns the dOTCOffer Struct of the offerId
     *
     * @param offerId uint256 the Id of the offer
     *
     * @return offer dOTCOffer
     */
    function getOffer(uint256 offerId) external view returns (dOTCOffer memory offer) {
        return allOffers[offerId];
    }

    /**
     * @dev Returns the Order Struct of the oreder_id
     *
     * @param orderId uint256
     *
     * @return order Order
     */
    function getTakerOrders(uint256 orderId) external view returns (Order memory order) {
        return takerOrders[orderId];
    }

    /**
     * @dev Returns the last offer id
     *
     * @return _offerId
     */
    function lastOfferId() external view returns (uint256) {
        return _offerId;
    }

    /**
     * @dev Remove a particular offer
     *
     *   Requirements:
     *   - `msg.sender` must be dOTCAmdin
     *
     * @param offerId uint256
     *
     * @return hasRemoved bool
     */
    function adminRemoveOffer(uint256 offerId) external onlyDotcAdmin returns (bool hasRemoved) {
        dOTCOffer memory offer = allOffers[offerId];

        address tokenIn = offer.tokenInTokenOut[0];

        uint256 _amountToSend = offer.availableAmount;
        uint256 realAmount = unstandardisedNumber(_amountToSend, IERC20MetadataUpgradeable(tokenIn));

        require(escrow.removeOffer(offerId, address(this), msg.sender), "dOTC: Offer removing error");

        // Because maker(CPK) transferred xTokens to Escrow we need to unwrap it and send to maker
        require(wrapper.unwrap(tokenIn, realAmount), "dOTC: Unwraping error");

        // Transfer unwrapped tokenOut from dOTC to maker
        require(
            IERC20(wrapper.xTokenToToken(tokenIn)).transfer(offer.maker, realAmount),
            "dOTC: ERC20 Transfer to maker failed"
        );

        delete allOffers[offerId];
        emit AdminRemoveOffer(offerId, msg.sender);
        return true;
    }

    /**
     * @dev Freeze a particular offer
     *
     *   Requirements
     *   - caller must have admin role
     *
     * @param offerId uint256
     *
     * @return hasfrozen bool
     */
    function freezeXOffer(uint256 offerId) external onlyDotcAdmin returns (bool hasfrozen) {
        require(escrow.freezeOneDeposit(offerId, msg.sender), "dOTC: freezing offer error");
        emit OfferFrozen(offerId, msg.sender);
        return true;
    }

    /**
     * @dev Unfreeze a particular offer
     *
     *   Requirements
     *   - caller must have admin role
     *
     * @param offerId uint256
     *
     * @return hasUnfrozen bool
     */
    function unFreezeXOffer(uint256 offerId) external onlyDotcAdmin returns (bool hasUnfrozen) {
        require(escrow.unFreezeOneDeposit(offerId, msg.sender), "dOTC: unfreezing failed");
        emit OfferUnFrozen(offerId, msg.sender);
        return true;
    }

    /**
     * @dev Checks interfaces support
     * @dev AccessControl, ERC1155Receiver overrided
     *
     * @return bool
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable, ERC1155ReceiverUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function standardiseNumber(uint256 amount, address _token) internal view returns (uint256) {
        uint8 decimal = IERC20MetadataUpgradeable(_token).decimals();
        return (amount * BPSNUMBER) / 10 ** decimal;
    }

    function unstandardisedNumber(uint256 _amount, IERC20MetadataUpgradeable _token) internal view returns (uint256) {
        uint8 decimal = _token.decimals();
        return (_amount * 10 ** decimal) / BPSNUMBER;
    }
}