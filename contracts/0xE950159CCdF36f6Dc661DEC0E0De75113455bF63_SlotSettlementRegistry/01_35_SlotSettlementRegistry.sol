pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";
import { IMembershipRegistry } from "./IMembershipRegistry.sol";
import { ScaledMath } from "./ScaledMath.sol";
import { StakeHouseUUPSCoreModule } from "./StakeHouseUUPSCoreModule.sol";
import { sETH } from "./sETH.sol";
import { CollateralisedSlotManager } from "./CollateralisedSlotManager.sol";
import { ISlotSettlementRegistry } from "./ISlotSettlementRegistry.sol";

/// @title SLOT token manager and share issuer
/// @notice Each StakeHouse has its own share token called sETH. This is the circulating money where as SLOT is part of the broad money supply that is never in circulation.
contract SlotSettlementRegistry is Initializable, ISlotSettlementRegistry, CollateralisedSlotManager, StakeHouseUUPSCoreModule {
    using ScaledMath for uint256;

    /// @notice Constant used to scale up the exchange rate to deal with fractions
    uint256 public constant EXCHANGE_RATE_SCALE = 1e18;

    /// @notice The base exchange rate of SLOT to sETH for all new houses is 3:1 and based on total dETH in house / total SLOT
    uint256 public constant BASE_EXCHANGE_RATE = 3 ether;

    /// @notice maximum amount of SLOT available to slash per KNOT
    uint256 public constant SLASHING_COLLATERAL = 4 ether;

    /// @notice amount of SLOT allocated to free floating sETH of a house
    uint256 public constant FREE_FLOATING_SLOT = 4 ether;

    /// @notice Total amount of SLOT minted per KNOT
    uint256 public constant SLOT_MINTED_PER_KNOT = 8 ether;

    /// @dev Beacon for each sETH proxy deployed. See beacon proxy pattern
    address private sETHBeacon;

    /// @notice StakeHouse registry address -> sETH share token for the StakeHouse
    mapping(address => sETH) public stakeHouseShareTokens;

    /// @notice sETH share token => address of associated StakeHouse
    mapping(sETH => address) public shareTokensToStakeHouse;

    /// @notice StakeHouse address -> total amount of SLOT slashed across all KNOTs in the house. See redemption rate
    mapping(address => uint256) public stakeHouseCurrentSLOTSlashed;

    /// @notice Current amount of SLOT that has been slashed from collateralised slot owner(s) which has not been purchased yet
    mapping(bytes => uint256) public currentSlashedAmountOfSLOTForKnot;

    /// @notice Whether SLOT has been minted for a KNOT
    mapping(bytes => bool) public knotSlotSharesMinted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(
        StakeHouseUniverse _universe,
        address _sETHBeacon
    ) external initializer {
        require(_sETHBeacon != address(0), "sETH beacon is zero");

        __StakeHouseUUPSCoreModule_init(_universe);

        sETHBeacon = _sETHBeacon;
    }

    /// @notice Deploys an sETH token contract for a StakeHouse
    /// @dev Only core module and a StakeHouse that's been deployed by the universe
    /// @param _stakeHouse Address of StakeHouse
    function deployStakeHouseShareToken(address _stakeHouse) external onlyModule onlyValidStakeHouse(_stakeHouse) {
        require(address(stakeHouseShareTokens[_stakeHouse]) == address(0), "Share token already created");

        // deploy and init new sETH
        BeaconProxy sETHProxy = new BeaconProxy(
            sETHBeacon,
            abi.encodeCall(sETH(sETHBeacon).init, ())
        );

        sETH token = sETH(address(sETHProxy));

        stakeHouseShareTokens[_stakeHouse] = token;
        shareTokensToStakeHouse[token] = _stakeHouse;

        emit StakeHouseShareTokenCreated(_stakeHouse);
    }

    /// @notice Adds 8 SLOT and issues shares to that KNOT based on the origin (which StakeHouse a KNOT belongs to)
    /// @dev Only core module and a StakeHouse that's been deployed by the universe
    function mintSLOTAndSharesBatch(
        address _stakeHouse,
        bytes calldata _memberId,
        address _recipient
    ) external onlyModule onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        require(_recipient != address(0), "Zero recipient");
        require(msg.sender == address(universe), "Only banking");

        // Make a note of the SLOT shares being minted - this must not be done more than once
        require(!knotSlotSharesMinted[_memberId], "SLOT shares minted");
        knotSlotSharesMinted[_memberId] = true;

        // Send recipient sETH representing half of the SLOT - they are free to do what they want with the sETH
        // Minted 3:1 effective but user can query active balance at any time which is affected by the dynamic exchange rate
        stakeHouseShareTokens[_stakeHouse].mint(_recipient, 12 ether);

        // The shares for the rest of the SLOT becomes collateral for the KNOT and are managed by the collateralised SLOT registry
        _increaseCollateralisedBalance(_stakeHouse, _recipient, _memberId, SLASHING_COLLATERAL);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function slashAndBuySlot(
        address _stakeHouse,
        bytes calldata _memberId,
        address _slasher,
        uint256 _slashAmount,
        uint256 _buyAmount,
        bool _isKickRequired
    ) external override onlyModule { // both sub methods check stake house and KNOT are valid so no need for duplicate check
        // slash collateralised SLOT owners for the given KNOT
        slash(_stakeHouse, _memberId, _slashAmount, _isKickRequired);

        // buy slashed slot
        buySlashedSlot(_stakeHouse, _memberId, _buyAmount, _slasher);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function slash(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount,
        bool _isKickRequired
    ) public override onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(
            currentSlashedAmountOfSLOTForKnot[_memberId] + _amount <= SLASHING_COLLATERAL,
            "Collateral exhausted"
        );

        _slashOwners(_stakeHouse, _memberId, _amount);

        // update the current amount slashed at KNOT and house level
        unchecked {
            stakeHouseCurrentSLOTSlashed[_stakeHouse] += _amount;
            currentSlashedAmountOfSLOTForKnot[_memberId] += _amount;
        } // knot value should not overflow as we have require. House val should not overflow because it allows for (2^256)/(4e18) number of KNOTs to be each fully slashed

        // check whether module declares a kick is required or if all of the collateralised SLOT for a KNOT has been exhausted, then we must kick it
        if (_isKickRequired || ((SLASHING_COLLATERAL - currentSlashedAmountOfSLOTForKnot[_memberId]) < 0.1 ether)) {
            IMembershipRegistry(_stakeHouse).kick(_memberId);
        }

        emit SlotSlashed(_memberId, _amount);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function buySlashedSlot(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount, // wei amount
        address _recipient
    ) public override onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(_recipient != address(0), "Recipient cannot be zero");
        require(_amount > 0, "Amount cannot be zero");

        require(
            currentSlashedAmountOfSLOTForKnot[_memberId] >= _amount,
            "Cannot buy more SLOT than has been slashed"
        );

        // reduce the current amount slashed as its being purchased
        unchecked {
            stakeHouseCurrentSLOTSlashed[_stakeHouse] -= _amount; // wei amount
            currentSlashedAmountOfSLOTForKnot[_memberId] -= _amount; // wei amount
        } // require above ensures underflow is prevented

        // update the collateralised registry balances due to the slashed SLOT that has been purchased
        _increaseCollateralisedBalance(_stakeHouse, _recipient, _memberId, _amount);

        emit SlashedSlotPurchased(_memberId, _amount);
    }

    /// @notice a core module can assist a user in rage quitting a StakeHouse
    /// @notice A user MUST have 4 collateralised slot, 4 free circulating (sETH) + dETH of KNOT inside index
    /// @param _stakeHouse Address of the StakeHouse that the knot belongs to
    /// @param _memberId Knot ID
    /// @param _collateralisedSlotOwners The full list of accounts that own collateralised sETH for a KNOT
    /// @param _freeFloatingSlotOwner Owner of the free floating 4 SLOT
    /// @param _savETHIndexOwner Owner of the index that contains the knot rage quitting
    /// @param _amountOfETHInDepositQueue Amount of ETH below 1 ETH that is yet to be sent to the deposit contract
    function rageQuitKnotOnBehalfOf(
        address _stakeHouse,
        bytes calldata _memberId,
        address _ethRecipient,
        address[] calldata _collateralisedSlotOwners,
        address _freeFloatingSlotOwner,
        address _savETHIndexOwner,
        uint256 _amountOfETHInDepositQueue
    ) external onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(_amountOfETHInDepositQueue == 0, "No funds in the queue permitted");

        _burnTokensUnderRageQuit(
            _stakeHouse,
            _memberId,
            _ethRecipient,
            _collateralisedSlotOwners,
            _freeFloatingSlotOwner,
            _savETHIndexOwner
        );
    }

    /// @notice Account manager can mark a user withdrawn when they have claimed their original staked asset
    function markUserKnotAsWithdrawn(
        address _knotOwner,
        bytes calldata _memberId
    ) external onlyModule {
        require(msg.sender == address(universe.accountManager()), "Only account manager");
        _markUserAsWithdrawn(_knotOwner, _memberId);
    }

    /// @notice Total dETH minted by adding knots and minting inflation rewards within a house
    function dETHMintedInHouse(address _stakeHouse) public view returns (uint256) {
        return universe.saveETHRegistry().totalDETHMintedWithinHouse(_stakeHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function exchangeRate(address _stakeHouse) public override view returns (uint256) {
        uint256 totalDETHMintedWithinHouse = dETHMintedInHouse(_stakeHouse);
        uint256 totalSlotInHouse = activeSlotMintedInHouse(_stakeHouse);

        if (totalDETHMintedWithinHouse == 0 || totalSlotInHouse == 0) {
            return BASE_EXCHANGE_RATE; // 3:1
        }

        return totalDETHMintedWithinHouse.sDivision(totalSlotInHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function redemptionRate(address _stakeHouse) public override view returns (uint256) {
        uint256 totalDETHMintedWithinHouse = dETHMintedInHouse(_stakeHouse);
        uint256 circulatingSlotForHouse = circulatingSlot(_stakeHouse);

        if (totalDETHMintedWithinHouse == 0 || circulatingSlotForHouse == 0) {
            // Exchange rate for a house starts at 3 : 1
            return BASE_EXCHANGE_RATE;
        }

        return totalDETHMintedWithinHouse.sDivision(circulatingSlotForHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function circulatingSlot(
        address _stakeHouse
    ) public override onlyValidStakeHouse(_stakeHouse) view returns (uint256) {
        return activeSlotMintedInHouse(_stakeHouse) - stakeHouseCurrentSLOTSlashed[_stakeHouse];
    }

    /// @notice Total SLOT minted for all KNOTs that have not rage quit the house
    function activeSlotMintedInHouse(address _stakeHouse) public view returns (uint256) {
        return IMembershipRegistry(_stakeHouse).numberOfActiveKNOTsThatHaveNotRageQuit() * SLOT_MINTED_PER_KNOT;
    }

    /// @inheritdoc ISlotSettlementRegistry
    function circulatingCollateralisedSlot(
        address _stakeHouse
    ) public override onlyValidStakeHouse(_stakeHouse) view returns (uint256) {
        return activeCollateralisedSlotMintedInHouse(_stakeHouse) - stakeHouseCurrentSLOTSlashed[_stakeHouse];
    }

    /// @notice Total collateralised SLOT minted for all KNOTs that have not rage quit the house
    function activeCollateralisedSlotMintedInHouse(address _stakeHouse) public view returns (uint256) {
        return IMembershipRegistry(_stakeHouse).numberOfActiveKNOTsThatHaveNotRageQuit() * SLASHING_COLLATERAL;
    }

    /// @inheritdoc ISlotSettlementRegistry
    function currentSlashedAmountForKnot(bytes calldata _memberId) external override view returns (uint256 currentSlashedAmount) {
        return currentSlashedAmountOfSLOTForKnot[_memberId];
    }

    /// @inheritdoc ISlotSettlementRegistry
    function sETHRedemptionThreshold(address _stakeHouse) public override view returns (uint256) {
        // Equivalent to (SLASHING_COLLATERAL * redemptionRate(_stakeHouse))
        return (SLASHING_COLLATERAL * dETHMintedInHouse(_stakeHouse)) / circulatingSlot(_stakeHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function totalCollateralisedSETHForStakehouse(
        address _stakeHouse
    ) external override view returns (uint256) {
        return sETHForSLOTBalance(_stakeHouse, circulatingCollateralisedSlot(_stakeHouse));
    }

    /// @inheritdoc ISlotSettlementRegistry
    function totalUserCollateralisedSETHBalanceInHouse(
        address _stakeHouse,
        address _user
    ) external override view returns (uint256) {
        return sETHForSLOTBalance(
            _stakeHouse,
            totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][_user]
        );
    }

    /// @inheritdoc ISlotSettlementRegistry
    function totalUserCollateralisedSETHBalanceForKnot(
        address _stakeHouse,
        address _user,
        bytes calldata _memberId
    ) external override view returns (uint256) {
        return sETHForSLOTBalance(
            _stakeHouse,
            totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][_user][_memberId]
        );
    }

    /// @notice Helper for calculating an sETH balance from a SLOT amount
    /// @param _stakeHouse Target Stakehouse registry - each has their own exchange rate
    /// @param _slotAmount SLOT amount in wei
    function sETHForSLOTBalance(address _stakeHouse, uint256 _slotAmount) public view returns (uint256) {
        // Equivalent to SLOT * exchange rate
        return activeSlotMintedInHouse(_stakeHouse) == 0 ? _slotAmount * 3 :
            (_slotAmount * dETHMintedInHouse(_stakeHouse)) / activeSlotMintedInHouse(_stakeHouse);
    }

    /// @notice Helper for calculating a SLOT balance from an sETH amount
    /// @param _stakeHouse Target Stakehouse registry - each has their own exchange rate
    /// @param _sETHAmount sETH amount in wei
    function slotForSETHBalance(address _stakeHouse, uint256 _sETHAmount) public view returns (uint256) {
        return activeSlotMintedInHouse(_stakeHouse) == 0 ? _sETHAmount.sDivision(BASE_EXCHANGE_RATE) :
            (_sETHAmount * activeSlotMintedInHouse(_stakeHouse)) / dETHMintedInHouse(_stakeHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function getCollateralizedSlotAccumulation(
        address[] calldata _sETHList,
        address _owner
    ) external override view returns (uint256) {
        uint256 sum;
        uint256 listLength = _sETHList.length;

        for (uint256 i; i < listLength; i = _unchecked_inc(i)) {
            /// Used to prevent sETH address repetition, sorting must happen off-chain
            if (i > 0) {
                require(_sETHList[i - 1] < _sETHList[i], 'sETH addresses must be ordered in decreasing order');
            }

            address stakeHouse = shareTokensToStakeHouse[sETH(_sETHList[i])];
            sum += totalUserCollateralisedSLOTBalanceInHouse[stakeHouse][_owner];
        }

        return sum;
    }

    /// @dev Given a KNOT and all tokens minted for the KNOT over its lifecycle, burn the tokens and allow redemption rights to be exercised
    /// @param _stakeHouse Address of registry of associated KNOT
    /// @param _memberId ID of the KNOT
    /// @param _collateralisedSlotOwners The full list of accounts that own collateralised sETH for a KNOT - they all have to approve the rage quit
    /// @param _freeFloatingSlotOwner Account that is in possession of the sETH that freely circulates on the market
    /// @param _savETHIndexOwner Owner of the index in the savETH registry
    function _burnTokensUnderRageQuit(
        address _stakeHouse,
        bytes calldata _memberId,
        address _ethRecipient,
        // even though we have the owners in the contract we request a full list of owners which have signed the rage quit
        address[] calldata _collateralisedSlotOwners,
        address _freeFloatingSlotOwner,
        address _savETHIndexOwner
    ) internal {
        require(_collateralisedSlotOwners.length > 0, "No collateralised owners specified");

        // check that all the collateralised SLOT owners have enough SLOT collateral to rate quit i.e. 4 SLOT
        {
            // KNOT must have the full 8 SLOT to rage quit and if there is any slashing, the ETH has to be supplied to fix that
            require(currentSlashedAmountOfSLOTForKnot[_memberId] == 0, "Knot has been slashed");

            // sum up all the collateral owned by all collateralised KNOT owners
            (
                uint256 totalCollateralisedKnotBalanceFound,
                uint256 totalCollateralisedSLOTBalInHouseFound
            ) = _reduceCollateralisedBalanceForAllHolders(
                _stakeHouse,
                _memberId,
                _collateralisedSlotOwners
            );

            // if the SLOT for all collateralise SLOT owners does not add up to 4, then we are missing an owner
            require(
                totalCollateralisedKnotBalanceFound == SLASHING_COLLATERAL,
                "Missing member"
            );

            // The total collateralised sETH for a KNOT must be greater than or equal to the threshold sETH amount as
            // defined by the redemption rate
            require(
                sETHForSLOTBalance(_stakeHouse, totalCollateralisedSLOTBalInHouseFound) >= sETHRedemptionThreshold(_stakeHouse),
                "Threshold not met"
            );
        }

        // burn free floating SLOT
        stakeHouseShareTokens[_stakeHouse].burn(_freeFloatingSlotOwner, 12 ether);

        // this is the user nominated account that will receive the ETH balance from the beacon chain
        _enableUserForKnotWithdrawal(_ethRecipient, _memberId);

        // rageQuit savETH and burn all dETH tokens
        universe.saveETHRegistry().rageQuitKnot(_stakeHouse, _memberId, _savETHIndexOwner);

        // update the registry to reflect that the member has rage quit the house
        IMembershipRegistry(_stakeHouse).rageQuit(_memberId);

        // off chain logging
        emit RageQuitKnot(_memberId);
    }

    /// @dev Every collateralised SLOT holder for a particular KNOT must have their balance reduced under rage quit
    /// @dev This means also reducing the total collateral a user owns at a house level as well as updating the total collateral in the house
    function _reduceCollateralisedBalanceForAllHolders(
        address _stakeHouse,
        bytes calldata _memberId,
        address[] calldata _collateralisedSlotOwners
    ) internal returns (uint256, uint256) {
        // When iterating over collateralised SLOT owners, we need to total up minted collateralised balance
        // so that on exit we ensure that we have accounted for all collateralised SLOT owners
        uint256 numOfOwners = _collateralisedSlotOwners.length;
        if (numOfOwners == 1) {
            address owner = _collateralisedSlotOwners[0];
            require(isCollateralisedOwner[_memberId][owner], "Invalid owner");
            isCollateralisedOwner[_memberId][owner] = false;

            uint256 knotSLOTBalanceForOwner = totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][owner][_memberId];
            uint256 userSlotBalAcrossEntireHouse = totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][owner];

            _decreaseCollateralisedBalance(_stakeHouse, owner, _memberId, knotSLOTBalanceForOwner);

            return (knotSLOTBalanceForOwner, userSlotBalAcrossEntireHouse);
        } else {
            uint256 totalCollateralisedKnotBalanceFound;

            // possibility for 1 owner to have significantly more SLOT at house level than required
            // this is ok as long as rage quit checks that the total collateralised SLOT for a KNOT across all owners
            // is exactly 4 SLOT.
            uint256 totalCollateralisedSLOTBalInHouseFound;

            for (uint256 i; i < numOfOwners; i = _unchecked_inc(i)) {
                address collateralisedSlotOwner = _collateralisedSlotOwners[i];
                require(isCollateralisedOwner[_memberId][collateralisedSlotOwner], "Invalid owner");
                isCollateralisedOwner[_memberId][collateralisedSlotOwner] = false;

                // burn all SLOT balances for the house, user and knot
                uint256 knotSLOTBalanceForOwner = totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][collateralisedSlotOwner][_memberId];
                require(knotSLOTBalanceForOwner > 0, "Zero SLOT owned");

                totalCollateralisedKnotBalanceFound += knotSLOTBalanceForOwner;
                totalCollateralisedSLOTBalInHouseFound += totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][collateralisedSlotOwner];

                _decreaseCollateralisedBalance(_stakeHouse, collateralisedSlotOwner, _memberId, knotSLOTBalanceForOwner);
            }

            return (totalCollateralisedKnotBalanceFound, totalCollateralisedSLOTBalInHouseFound);
        }
    }

    /// @dev Starting with entity that tied the knot, slash each collateralised SLOT owner
    function _slashOwners(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount
    ) internal {
        uint256 leftToSlash = _amount;
        if (leftToSlash > 0) {
            uint256 numOfCollateralisedOwners = collateralisedSLOTOwners[_memberId].length;
            if (numOfCollateralisedOwners == 1) {
                _decreaseCollateralisedBalance(_stakeHouse, collateralisedSLOTOwners[_memberId][0], _memberId, leftToSlash);
                leftToSlash = 0;
            } else { // else clause assumes the array has been set up correctly i.e. it is not possible to have zero owners
                for (uint256 i; i < numOfCollateralisedOwners; i = _unchecked_inc(i)) {
                    address owner = collateralisedSLOTOwners[_memberId][i];
                    uint256 slotBalance = totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][owner][_memberId];

                    if (slotBalance >= leftToSlash) {
                        _decreaseCollateralisedBalance(_stakeHouse, owner, _memberId, leftToSlash);
                        leftToSlash = 0;
                        break;
                    } else {
                        leftToSlash -= slotBalance;
                        _decreaseCollateralisedBalance(_stakeHouse, owner, _memberId, slotBalance);
                    }
                }
            }
        }
        assert(leftToSlash == 0);
    }

    /// @dev Save GAS by not using SafeMath on loop increment operations
    function _unchecked_inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }
}