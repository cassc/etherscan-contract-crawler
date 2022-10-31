pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

interface ISlotSettlementRegistry {
    /// @notice sETH token deployed for new Stakehouse
    event StakeHouseShareTokenCreated(address indexed stakeHouse);

    /// @notice Collateralised SLOT deducted from a collateralised SLOT owner
    event SlotSlashed(bytes memberId, uint256 amount);

    /// @notice Collateralised SLOT purchased from KNOT
    event SlashedSlotPurchased(bytes memberId, uint256 amount);

    /// @notice KNOT has exited the protocol exercising their redemption rights
    event RageQuitKnot(bytes memberId);

    /// @notice Function to report a slashing event (balance reduction in this case) and buy the slashed SLOT at the same time
    /// @dev Only core module and a StakeHouse that's been deployed by the universe
    /// @param _stakeHouse registry address
    /// @param _memberId ID of the member in the StakeHouse
    /// @param _slasher Recipient of the new collateralised SLOT being purhased
    /// @param _slashAmount Amount of collateralised SLOT being slashed
    /// @param _buyAmount Amount of collatearlised SLOT being purchased
    /// @param _isKickRequired Whether the KNOT needs to be kicked from the protocol due to misbehaving on the beacon chain
    function slashAndBuySlot(
        address _stakeHouse,
        bytes calldata _memberId,
        address _slasher,
        uint256 _slashAmount,
        uint256 _buyAmount,
        bool _isKickRequired
    ) external;

    /// @notice Slashes a KNOT (due to balance reduction and or beacon chain cheating) in a StakeHouse up to a given amount before auto-kicking member
    /// @dev Only core module and a StakeHouse that's been deployed by the universe
    /// @param _stakeHouse registry address
    /// @param _memberId ID of the member in the StakeHouse
    /// @param _amount Amount of SLOT being slashed
    /// @param _isKickRequired Whether the KNOT needs to be kicked for severe cheating (double proposal and voting or surround voting)
    function slash(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount,
        bool _isKickRequired
    ) external;

    /// @notice For a given KNOT that has been slashed in a StakeHouse, this allows the SLOT to be purchased
    /// @dev Only StakeHouse that's been deployed by the universe
    /// @param _stakeHouse Address of the registry
    /// @param _memberId ID of the slashed member of the StakeHouse
    /// @param _amount Amount of SLOT being purchased (which will dictate shares received)
    /// @param _recipient Recipient of the sETH shares that will be backed by the SLOT purchased
    function buySlashedSlot(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount,
        address _recipient
    ) external;

    /// @dev Get the sum of total collateralized SLOT balances for multiple sETH tokens for specific address
    /// @param _sETHList - List of sETH token addresses
    /// @param _owner - Address whose balance is summed over
    function getCollateralizedSlotAccumulation(address[] calldata _sETHList, address _owner) external view returns (uint256);

    /// @notice Total amount of SLOT that has been slashed but not purchased
    /// @param _memberId BLS public key of KNOT
    function currentSlashedAmountForKnot(bytes calldata _memberId) external view returns (uint256 currentSlashedAmount);

    /// @notice Total amount of collateralised sETH owned by an account for a given KNOT
    /// @param _stakeHouse Address of Stakehouse registry contract
    /// @param _user Collateralised SLOT owner address
    /// @param _memberId BLS pub key of the validator
    function totalUserCollateralisedSETHBalanceForKnot(
        address _stakeHouse,
        address _user,
        bytes calldata _memberId
    ) external view returns (uint256);

    /// @notice Total collateralised sETH owned by a user across all KNOTs in the house
    /// @param _stakeHouse Address of the Stakehouse registry
    /// @param _user Collateralised SLOT owner in house
    function totalUserCollateralisedSETHBalanceInHouse(
        address _stakeHouse,
        address _user
    ) external view returns (uint256);

    /// @notice Based on full health of the collateralised SLOT, the collateralised sETH for the house
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function totalCollateralisedSETHForStakehouse(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Total sETH threshold need to be met in order to rage quit. User must have more or same sETH than this at the house level
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

    /// @notice Amount of sETH required per SLOT in order to rage quit
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function redemptionRate(address _stakeHouse) external view returns (uint256);

    /// @notice Amount of sETH per SLOT for a given house calculated as total dETH minted in house / total SLOT from all KNOTs
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function exchangeRate(address _stakeHouse) external view returns (uint256);
}