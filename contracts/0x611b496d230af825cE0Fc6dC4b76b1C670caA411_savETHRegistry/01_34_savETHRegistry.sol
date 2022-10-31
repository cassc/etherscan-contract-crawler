pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { dETH } from "./dETH.sol";
import { savETH } from "./savETH.sol";
import { ScaledMath } from "./ScaledMath.sol";
import { StakeHouseUUPSCoreModule } from "./StakeHouseUUPSCoreModule.sol";
import { ISavETHRegistry } from "./ISavETHRegistry.sol";

/// @title savETH registry of dETH indices
/// @notice savETH is a special account for dETH token holders that allows earning exclusive dETH inflation rewards
/// @dev This contract maintains the minting and burning of savETH and dETH
contract savETHRegistry is Initializable, ISavETHRegistry, StakeHouseUUPSCoreModule {
    using ScaledMath for uint256;

    /// @notice Amount of tokens minted each time a KNOT is added to the universe. Denominated in ether due to redemption rights
    uint256 public constant KNOT_BATCH_AMOUNT = 24 ether;

    /// @notice Constant used to scale up the exchange rate to deal with fractions
    uint256 public constant EXCHANGE_RATE_SCALE = 1e18;

    /// @notice Constant that defines the max amount of dETH that can be deposited and withdrawn from the registry denominated in KNOTS (dETH / 24 ether)
    uint8 public constant MAX_AMOUNT_OF_KNOTS_THAT_CAN_DEPOSIT_AND_WITHDRAW = 40;

    struct dETHManagementMetadata {
        uint128 dETHUnderManagementInOpenIndex; // dETH managed within the open index (used for calculating the appropriate exchange rate for minting savETH)
        uint128 dETHInCirculation; // total dETH in circulation (tracks total in indices, open index and outside registry i.e. dETH that has been added and not rage quit)
    }

    /// @notice Metadata associated with minting and managing dETH
    dETHManagementMetadata public dETHMetadata;

    /// @notice This is a total number of ETH beacon chain inflation rewards ever minted for a KNOT
    mapping(bytes => uint256) public dETHRewardsMintedForKnot;

    /// @notice Knot ID -> owner -> approved spender that can transfer ownership of a KNOT from one index to another (a marketplace for example)
    mapping(bytes => mapping(address => address)) public approvedKnotSpender;

    /// @notice Knot ID -> approved spender that can transfer ownership of an entire index (a marketplace for example)
    mapping(uint256 => address) public approvedIndexSpender;

    /// @notice Tracks whether the 24 dETH has been minted for a KNOT
    mapping(bytes => bool) public knotdETHSharesMinted;

    /// @notice Source of next index ID and is equal to number of indices
    uint256 public indexPointer;

    /// @notice Given an index identifier, returns the owner of the index
    mapping(uint256 => address) public indexIdToOwner;

    // knots can be isolated in an index but must lock up their savETH shares in the registry to do this
    /// @notice index ID -> BLS pub key -> locked up dETH balance of KNOT within the index
    mapping(uint256 => mapping(bytes => uint256)) public knotDETHBalanceInIndex;

    /// @notice BLS public key -> assigned index id
    mapping(bytes => uint256) public associatedIndexIdForKnot;

    /// @notice Total amount of dETH minted within a house including all beacon chain inflation rewards
    mapping(address => uint256) public totalDETHMintedWithinHouse;

    /// @notice the risk free token of the protocol
    dETH public dETHToken;

    /// @notice Shares of the registry
    savETH public saveETHToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev can only be called once
    /// @param _universe Universe contract address
    /// @param _saveETHLogic Address of the SaveETH logic contract for proxy deployment
    function init(StakeHouseUniverse _universe, address _dETHLogic, address _saveETHLogic) external initializer {
        __StakeHouseUUPSCoreModule_init(_universe);

        ERC1967Proxy dETHProxy = new ERC1967Proxy(
            address(_dETHLogic),
            abi.encodeCall(
                dETH(address(_dETHLogic)).init,
                (address(this), _universe)
            )
        );

        dETHToken = dETH(address(dETHProxy));

        ERC1967Proxy saveETHProxy = new ERC1967Proxy(
            _saveETHLogic,
            abi.encodeCall(
                savETH(_saveETHLogic).init,
                (savETHRegistry(address(this)), _universe)
            )
        );

        saveETHToken = savETH(address(saveETHProxy));
    }

    /// @inheritdoc ISavETHRegistry
    function approveForIndexOwnershipTransfer(
        uint256 _indexId,
        address _owner,
        address _spender
    ) external onlyModule override {
        require(_indexId > 0, "Index cannot be zero");
        require(_indexId <= indexPointer, "Invalid index ID");
        require(_owner != address(0), "Owner cannot be zero address");
        require(_owner != _spender, "Owner cannot be spender");
        require(indexIdToOwner[_indexId] == _owner, "Only index owner");

        approvedIndexSpender[_indexId] = _spender;

        emit ApprovedSpenderForIndexTransfer(_indexId, _spender);
    }

    /// @inheritdoc ISavETHRegistry
    function transferIndexOwnership(
        uint256 _indexId,
        address _currentOwnerOrSpender,
        address _newOwner
    ) external onlyModule override {
        require(_indexId > 0, "Index cannot be zero");
        require(_indexId <= indexPointer, "Invalid index ID");
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_currentOwnerOrSpender != address(0), "Owner or spender cannot be zero");
        require(indexIdToOwner[_indexId] != _newOwner, "New owner cannot be old owner");
        require(
            indexIdToOwner[_indexId] == _currentOwnerOrSpender || approvedIndexSpender[_indexId] == _currentOwnerOrSpender,
            "Only owner or spender"
        );

        // clear the approval and then transfer index ownership
        delete approvedIndexSpender[_indexId];
        emit ApprovedSpenderForIndexTransfer(_indexId, address(0));

        indexIdToOwner[_indexId] = _newOwner;

        emit IndexOwnershipTransferred(_indexId);
    }

    /// @notice Called when a new KNOT is added to mint 24 dETH and add it to an index
    /// @param _stakeHouse House that the KNOT was just added to
    /// @param _memberId ID of the KNOT i.e. the BLS public key of the validator
    /// @param _indexId Index being assigned savETH KNOT shares with exclusive right to receive 100% of the dETH rewards
    function mintSaveETHBatchAndDETHReserves( // adds a knot to the universe
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _indexId
    ) external onlyModule onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        require(!knotdETHSharesMinted[_memberId], "dETH shares minted");

        // Make a note that the initial 24 dETH shares were minted - this must not be done more than once
        knotdETHSharesMinted[_memberId] = true;

        // track the amount of dETH minted within the house
        totalDETHMintedWithinHouse[_stakeHouse] += KNOT_BATCH_AMOUNT;

        // track circulating dETH across all houses
        dETHMetadata.dETHInCirculation += uint128(KNOT_BATCH_AMOUNT);

        // assign the 24 dETH for the knot to the specified index
        _addKnotIntoIndex(_indexId, _memberId, KNOT_BATCH_AMOUNT);
    }

    /// @notice Used by an authorised minter to mint new dETH inflation rewards reported from the beacon chain
    /// @param _stakeHouse StakeHouse that the KNOT belongs to
    /// @param _memberId ID of the KNOT that is receiving inflation rewards
    /// @param _amount of dETH to mint
    function mintDETHReserves(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount
    ) external onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(_amount > 0, "Amount cannot be zero");

        if (isKnotPartOfOpenIndex(_memberId)) {
            // ensure that if you are minting to the open index that there are savETH tokens to receive the dETH i.e.
            // you want to ensure that there are some KNOT(s) in the registry
            require(saveETHToken.totalSupply() > 0, "No supply");
            dETHMetadata.dETHUnderManagementInOpenIndex += uint128(_amount);

            // all savETH owners will get pro-rata share of new rewards for a KNOT that is part of the open index
            emit dETHReservesAddedToOpenIndex(_memberId, _amount);
        } else {
            // increase the dETH balance in the index
            uint256 indexId = associatedIndexIdForKnot[_memberId];
            knotDETHBalanceInIndex[indexId][_memberId] += _amount;

            emit dETHAddedToKnotInIndex(_memberId, _amount);
        }

        // Track how much dETH rewards has been minted for a KNOT
        dETHRewardsMintedForKnot[_memberId] += _amount;

        // track the amount of dETH minted within the house
        totalDETHMintedWithinHouse[_stakeHouse] += _amount;

        // track circulating dETH across all houses
        dETHMetadata.dETHInCirculation += uint128(_amount);
    }

    /// @inheritdoc ISavETHRegistry
    function transferKnotToAnotherIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwnerOrSpender,
        uint256 _newIndexId
    ) external override onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(!isKnotPartOfOpenIndex(_memberId), "KNOT is in the open index");
        require(_indexOwnerOrSpender != address(0), "Owner or spender field cannot be zero");

        // only owner of the index that the KNOT belongs to or an authorised KNOT spender, can transfer to another index
        uint256 indexIdForKnot = associatedIndexIdForKnot[_memberId];
        require(indexIdForKnot != _newIndexId, "Invalid transfer to same index");

        address indexOwner = indexIdToOwner[indexIdForKnot];
        require(
            _indexOwnerOrSpender == indexOwner || _indexOwnerOrSpender == approvedKnotSpender[_memberId][indexOwner],
            "Only index owner or spender"
        );

        uint256 dETHToTransfer = knotDETHBalanceInIndex[indexIdForKnot][_memberId];

        // delete current info
        delete approvedKnotSpender[_memberId][indexOwner];
        emit ApprovedSpenderForKnotInIndex(_memberId, address(0));

        delete knotDETHBalanceInIndex[indexIdForKnot][_memberId];
        delete associatedIndexIdForKnot[_memberId];

        // transfer to new index
        _addKnotIntoIndex(_newIndexId, _memberId, dETHToTransfer);

        // emit for off chain indexing
        emit KnotTransferredToAnotherIndex(_memberId, _newIndexId);
    }

    /// @inheritdoc ISavETHRegistry
    function approveSpendingOfKnotInIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner,
        address _spender
    ) external override onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(!isKnotPartOfOpenIndex(_memberId), "KNOT is in the open index");
        require(_indexOwner != address(0), "Owner is zero");

        uint256 indexIdForKnot = associatedIndexIdForKnot[_memberId];
        address indexOwner = indexIdToOwner[indexIdForKnot];
        require(indexOwner == _indexOwner, "Only index owner");
        require(_indexOwner != _spender, "Owner and spender cannot be the same");

        approvedKnotSpender[_memberId][indexOwner] = _spender;

        emit ApprovedSpenderForKnotInIndex(_memberId, _spender);
    }

    /// @inheritdoc ISavETHRegistry
    function addKnotToOpenIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner,
        address _recipient
    ) external override onlyModule onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        require(!isKnotPartOfOpenIndex(_memberId), "Already in the open index");
        require(_recipient != address(0), "Zero recipient");

        uint256 indexIdForKnot = associatedIndexIdForKnot[_memberId];
        address indexOwner = indexIdToOwner[indexIdForKnot];
        require(indexOwner == _indexOwner, "Only index owner");

        uint256 knotDETHBalance = knotDETHBalanceInIndex[indexIdForKnot][_memberId];
        uint256 saveETHToSend = dETHToSavETH(knotDETHBalance);

        dETHMetadata.dETHUnderManagementInOpenIndex += uint128(knotDETHBalance);

        delete approvedKnotSpender[_memberId][indexOwner];
        emit ApprovedSpenderForKnotInIndex(_memberId, address(0));

        delete knotDETHBalanceInIndex[indexIdForKnot][_memberId];
        delete associatedIndexIdForKnot[_memberId];

        saveETHToken.mint(_recipient, saveETHToSend);

        emit KnotAddedToOpenIndex(_memberId, _indexOwner, saveETHToSend);
    }

    /// @inheritdoc ISavETHRegistry
    function addKnotToOpenIndexAndWithdraw(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner,
        address _recipient
    ) external override onlyModule onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        require(!isKnotPartOfOpenIndex(_memberId), "Already in the open index");
        require(_recipient != address(0), "Zero recipient");

        uint256 indexIdForKnot = associatedIndexIdForKnot[_memberId];
        address indexOwner = indexIdToOwner[indexIdForKnot];
        require(indexOwner == _indexOwner, "Only index owner");

        uint128 dETHBalance = uint128(knotDETHBalanceInIndex[indexIdForKnot][_memberId]);

        _assert_dETHEntryExitRule(dETHBalance);

        delete approvedKnotSpender[_memberId][indexOwner];
        emit ApprovedSpenderForKnotInIndex(_memberId, address(0));

        delete knotDETHBalanceInIndex[indexIdForKnot][_memberId];
        delete associatedIndexIdForKnot[_memberId];

        dETHToken.mint(_recipient, uint256(dETHBalance));

        emit KnotAddedToOpenIndexAndDETHWithdrawn(_memberId);
    }

    /// @inheritdoc ISavETHRegistry
    function isolateKnotFromOpenIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _savETHOwner,
        uint256 _indexId
    ) external override onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        // savETH is required to be locked in order to isolate a KNOT and its based on the total amount of dETH given to the KNOT.
        // Total given to the KNOT is the 24 dETH they originally received plus any dETH rewards
        uint256 dETHRequiredForIsolation = KNOT_BATCH_AMOUNT + dETHRewardsMintedForKnot[_memberId];
        uint256 savETHRequiredForIsolation = dETHToSavETH(dETHRequiredForIsolation);

        // add the KNOT to the index owned by the index owner and record the savETH balance. Create a new index if needed
        _addKnotIntoIndex(_indexId, _memberId, dETHRequiredForIsolation);

        saveETHToken.burn(_savETHOwner, savETHRequiredForIsolation);
        dETHMetadata.dETHUnderManagementInOpenIndex -= uint128(dETHRequiredForIsolation);
    }

    /// @inheritdoc ISavETHRegistry
    function withdraw(address _savETHOwner, address _recipient, uint128 _amount) external onlyModule override {
        require(saveETHToken.balanceOf(_savETHOwner) >= _amount, "Not enough savETH balance");
        require(_recipient != address(0), "Zero recipient");

        // Calculate how much dETH is owed to the user
        uint128 dETHFromExchangeRate = uint128(savETHToDETH(_amount));

        _assert_dETHEntryExitRule(dETHFromExchangeRate);

        // safe math ensures this will not underflow
        dETHMetadata.dETHUnderManagementInOpenIndex -= dETHFromExchangeRate;

        // We now burn SaveETH and transfer dETH
        saveETHToken.burn(_savETHOwner, uint256(_amount));
        dETHToken.mint(_recipient, dETHFromExchangeRate);

        emit dETHWithdrawnFromOpenIndex(dETHFromExchangeRate);
    }

    /// @inheritdoc ISavETHRegistry
    function deposit(address _dETHOwner, address _savETHRecipient, uint128 _amount) external onlyModule override {
        require(dETHToken.balanceOf(_dETHOwner) >= _amount, "Not enough dETH balance");
        require(_savETHRecipient != address(0), "Zero recipient");

        _assert_dETHEntryExitRule(_amount);

        uint256 savETHToMint = dETHToSavETH(_amount);
        dETHMetadata.dETHUnderManagementInOpenIndex += _amount;

        dETHToken.burn(_dETHOwner, _amount);
        saveETHToken.mint(_savETHRecipient, savETHToMint);

        emit dETHDepositedIntoRegistry(_dETHOwner, uint256(_amount));
    }

    /// @inheritdoc ISavETHRegistry
    function depositAndIsolateKnotIntoIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _dETHOwner,
        uint256 _indexId
    ) external override onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        uint256 dETHRequiredForIsolation = KNOT_BATCH_AMOUNT + dETHRewardsMintedForKnot[_memberId];
        require(dETHToken.balanceOf(_dETHOwner) >= dETHRequiredForIsolation, "Not enough dETH balance");

        _assert_dETHEntryExitRule(uint128(dETHRequiredForIsolation));

        _addKnotIntoIndex(_indexId, _memberId, dETHRequiredForIsolation);

        dETHToken.burn(_dETHOwner, dETHRequiredForIsolation);

        emit dETHDepositedIntoRegistry(_dETHOwner, dETHRequiredForIsolation);
    }

    /// @notice An external module would use this to assist a user who does not want to be part of a StakeHouse
    /// @dev The KNOT has to be part of an index where the index owner agrees to rage quit
    /// @param _stakeHouse Address that the KNOT is part of
    /// @param _memberId ID of the KNOT
    /// @param _indexOwner Current owner of index that the KNOT is associated with in the registry
    function rageQuitKnot(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner
    ) external onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(msg.sender == address(universe.slotRegistry()), "Only SLOT registry");
        require(_indexOwner != address(0), "Invalid rage quitter");

        // Some context here:
        // A KNOT starts life in an index and receives exclusive ETH inflation rewards whilst being in that index
        // The associated savETH can be withdrawn at any time by moving the KNOT into the open index OR the KNOT can be kept outside the open index and its assets transferred to someone else (maybe via a secondary market)
        // If the KNOT is transferred outside the open index, the original owner no longer owns the assets and the new owner will get 100% of all dETH rewards
        // The index owner can collaborate with the collateralised SLOT owner to rage quit or buy back the dETH from the other index
        // However, if the KNOT was moved to the open index, it needs to be isolated again to rage quit which could mean buying back all the savETH and dETH needed
        _rageQuitKnotInIndex(_stakeHouse, _memberId, _indexOwner);
    }

    /// @dev Sets up an index for an ETH address by allocating a new unseen index identifier.
    function createIndex(address _owner) external onlyModule returns (uint256) {
        require(_owner != address(0), "New index owner cannot be zero");
        require(_owner != address(this), "Contract says no thanks");

        unchecked {
            indexPointer += 1;
        } // we would not reasonably expect 2 ^ 256 - 1 number of indices to be created

        indexIdToOwner[indexPointer] = _owner;

        emit IndexCreated(indexPointer);

        return indexPointer;
    }

    /// @notice If the KNOT is no longer part of an index, then they are in a general open index where dETH rewards are shared pro-rata
    function isKnotPartOfOpenIndex(bytes calldata _memberId) public view returns (bool) {
        return associatedIndexIdForKnot[_memberId] == 0;
    }

    /// @notice dETH managed within the open index (used for calculating the appropriate exchange rate for minting savETH)
    function dETHUnderManagementInOpenIndex() external view returns (uint256) {
        return dETHMetadata.dETHUnderManagementInOpenIndex;
    }

    // @notice total dETH in circulation (tracks total in indices, open index and outside registry i.e. dETH that has been added and not rage quit)
    function dETHInCirculation() external view returns (uint256) {
        return dETHMetadata.dETHInCirculation;
    }

    /// @notice Based on dETH in open index and dETH withdrawn from registry, amount left in indices
    function totalDETHInIndices() external view returns (uint256) {
        return dETHMetadata.dETHInCirculation - dETHMetadata.dETHUnderManagementInOpenIndex - dETHToken.totalSupply();
    }

    /// @notice Helper to convert a dETH amount to savETH amount
    function dETHToSavETH(uint256 _amount) public view returns (uint256) {
        if (dETHMetadata.dETHUnderManagementInOpenIndex == 0) {
            return _amount;
        }

        return _amount * saveETHToken.totalSupply() / dETHMetadata.dETHUnderManagementInOpenIndex;
    }

    /// @notice Helper to convert a savETH amount to dETH amount
    function savETHToDETH(uint256 _amount) public view returns (uint256) {
        if (dETHMetadata.dETHUnderManagementInOpenIndex == saveETHToken.totalSupply()) {
            return _amount;
        }

        return _amount * dETHMetadata.dETHUnderManagementInOpenIndex / saveETHToken.totalSupply();
    }

    /// @dev Registers a KNOT and a savETH balance into an index
    function _addKnotIntoIndex(uint256 _indexId, bytes calldata _memberId, uint256 _dETHBalance) internal {
        require(_indexId > 0, "Index ID cannot be zero");
        require(_indexId <= indexPointer, "Invalid index ID");
        require(associatedIndexIdForKnot[_memberId] == 0, "KNOT is associated with another index");
        require(knotDETHBalanceInIndex[_indexId][_memberId] == 0, "Index has a balance");
        require(_dETHBalance > 0, "No balance being registered");

        knotDETHBalanceInIndex[_indexId][_memberId] = _dETHBalance;
        associatedIndexIdForKnot[_memberId] = _indexId;

        emit KnotInsertedIntoIndex(_memberId, _indexId);
    }

    /// @dev Ensure for deposit and withdrawal of dETH it satisfies a safe min and mix amount
    function _assert_dETHEntryExitRule(uint128 _amount) internal pure {
        require(_amount >= 0.001 ether, "Amount must be >= 0.001 ether");
        require(
            _amount <= 24 ether * MAX_AMOUNT_OF_KNOTS_THAT_CAN_DEPOSIT_AND_WITHDRAW,
            "Max dETH exceeded"
        );
    }

    /// @dev When a rage quit is decided at a KNOT level and the KNOT is outside the open savETH index and part of an index
    function _rageQuitKnotInIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner
    ) internal {
        require(!isKnotPartOfOpenIndex(_memberId), "Only knots in an index");

        uint256 indexIdForKnot = associatedIndexIdForKnot[_memberId];
        address indexOwner = indexIdToOwner[indexIdForKnot];
        require(indexOwner == _indexOwner, "Only index owner");

        totalDETHMintedWithinHouse[_stakeHouse] -= knotDETHBalanceInIndex[indexIdForKnot][_memberId];
        dETHMetadata.dETHInCirculation -= uint128(knotDETHBalanceInIndex[indexIdForKnot][_memberId]);

        delete approvedKnotSpender[_memberId][indexOwner];
        emit ApprovedSpenderForKnotInIndex(_memberId, address(0));

        delete knotDETHBalanceInIndex[indexIdForKnot][_memberId];
        delete associatedIndexIdForKnot[_memberId];
        delete dETHRewardsMintedForKnot[_memberId];

        emit RageQuitKnot(_memberId);
    }
}