pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface ISlotSettlementRegistry {

    ////////////
    // Events //
    ////////////

    /// @notice Collateralised SLOT deducted from a collateralised SLOT owner
    event SlotSlashed(bytes memberId, uint256 amount);

    /// @notice Collateralised SLOT purchased from KNOT
    event SlashedSlotPurchased(bytes memberId, uint256 amount);

    /// @notice KNOT has exited the protocol exercising their redemption rights
    event RageQuitKnot(bytes memberId);

    event CollateralisedOwnerAddedToKnot(bytes knotId, address indexed owner);

    /// @notice User is able to trigger beacon chain withdrawal
    event UserEnabledForWithdrawal(address indexed user, bytes memberId);

    /// @notice User has withdrawn ETH from beacon chain - do not allow any more withdrawals
    event UserWithdrawn(address indexed user, bytes memberId);

    ////////////
    // View   //
    ////////////

    /// @notice Total collateralised SLOT owned by an account across all KNOTs in a given StakeHouse
    function totalUserCollateralisedSLOTBalanceInHouse(address _stakeHouse, address _user) external view returns (uint256);

    /// @notice Total collateralised SLOT owned by an account for a given KNOT in a Stakehouse
    function totalUserCollateralisedSLOTBalanceForKnot(address _stakeHouse, address _user, bytes calldata _blsPublicKey) external view returns (uint256);

    // @notice Given a KNOT and account, a flag represents whether the account has been a collateralised SLOT owner at some point in the past
    function isCollateralisedOwner(bytes calldata blsPublicKey, address _user) external view returns (bool);

    /// @notice If a user account has been able to rage quit a KNOT, this flag is set to true to allow beacon chain funds to be claimed
    function isUserEnabledForKnotWithdrawal(address _user, bytes calldata _blsPublicKey) external view returns (bool);

    /// @notice Once beacon chain funds have been redeemed, this flag is set to true in order to block double withdrawals
    function userWithdrawn(address _user, bytes calldata _blsPublicKey) external view returns (bool);

    /// @notice Total number of collateralised SLOT owners for a given KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    function numberOfCollateralisedSlotOwnersForKnot(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Fetch a collateralised SLOT owner address for a specific KNOT at a specific index
    function getCollateralisedOwnerAtIndex(bytes calldata _blsPublicKey, uint256 _index) external view returns (address);

    /// @dev Get the sum of total collateralized SLOT balances for multiple sETH tokens for specific owner
    /// @param _sETHList List of sETH token addresses from different Stakehouses
    /// @param _owner Address that has an sETH token balance within the sETH list
    function getCollateralizedSlotAccumulation(address[] calldata _sETHList, address _owner) external view returns (uint256);

    /// @notice Total amount of SLOT that has been slashed but not topped up yet
    /// @param _blsPublicKey BLS public key of KNOT
    function currentSlashedAmountForKnot(bytes calldata _blsPublicKey) external view returns (uint256 currentSlashedAmount);

    /// @notice Total amount of collateralised sETH owned by an account for a given KNOT
    /// @param _stakeHouse Address of Stakehouse registry contract
    /// @param _user Collateralised SLOT owner address
    /// @param _blsPublicKey BLS pub key of the validator
    function totalUserCollateralisedSETHBalanceForKnot(
        address _stakeHouse,
        address _user,
        bytes calldata _blsPublicKey
    ) external view returns (uint256);

    /// @notice Total collateralised sETH owned by a user across all KNOTs in the house
    /// @param _stakeHouse Address of the Stakehouse registry
    /// @param _user Collateralised SLOT owner in house
    function totalUserCollateralisedSETHBalanceInHouse(
        address _stakeHouse,
        address _user
    ) external view returns (uint256);

    /// @notice The total collateralised sETH circulating for the house i.e. (8 * number of knots) - total slashed
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function totalCollateralisedSETHForStakehouse(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Minimum amount of collateralised sETH a user must hold at a house level in order to rage quit a healthy knot
    function sETHRedemptionThreshold(address _stakeHouse) external view returns (uint256);

    /// @notice Given the total SLOT in the house (8 * number of KNOTs), how much is in circulation when filtering out total slashed
    /// @param _stakeHouse Address of the Stakehouse registry
    function circulatingSlot(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Given the total amount of collateralised SLOT in the house (4 * number of KNOTs), how much is in circulation when filtering out total slashed
    /// @param _stakeHouse Address of the Stakehouse registry
    function circulatingCollateralisedSlot(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Amount of sETH required per SLOT at the house level in order to rage quit
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function redemptionRate(address _stakeHouse) external view returns (uint256);

    /// @notice Amount of sETH per SLOT for a given house calculated as total dETH minted in house / total SLOT from all KNOTs
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function exchangeRate(address _stakeHouse) external view returns (uint256);

    /// @notice Returns the address of the sETH token for a given Stakehouse registry
    function stakeHouseShareTokens(address _stakeHouse) external view returns (address);

    /// @notice Returns the address of the associated house for an sETH token
    function shareTokensToStakeHouse(address _sETHToken) external view returns (address);

    /// @notice Returns the total amount of SLOT slashed at the Stakehouse level
    function stakeHouseCurrentSLOTSlashed(address _stakeHouse) external view returns (uint256);

    /// @notice Returns the total amount of SLOT slashed for a KNOT
    function currentSlashedAmountOfSLOTForKnot(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Total dETH minted by adding knots and minting inflation rewards within a house
    function dETHMintedInHouse(address _stakeHouse) external view returns (uint256);

    /// @notice Total SLOT minted for all KNOTs that have not rage quit the house
    function activeSlotMintedInHouse(address _stakeHouse) external view returns (uint256);

    /// @notice Total collateralised SLOT minted for all KNOTs that have not rage quit the house
    function activeCollateralisedSlotMintedInHouse(address _stakeHouse) external view returns (uint256);

    /// @notice Helper for calculating an active sETH balance from a SLOT amount
    /// @param _stakeHouse Target Stakehouse registry - each has their own exchange rate
    /// @param _slotAmount SLOT amount in wei
    function sETHForSLOTBalance(address _stakeHouse, uint256 _slotAmount) external view returns (uint256);

    /// @notice Helper for calculating a SLOT balance from an sETH amount
    /// @param _stakeHouse Target Stakehouse registry - each has their own exchange rate
    /// @param _sETHAmount sETH amount in wei
    function slotForSETHBalance(address _stakeHouse, uint256 _sETHAmount) external view returns (uint256);

}