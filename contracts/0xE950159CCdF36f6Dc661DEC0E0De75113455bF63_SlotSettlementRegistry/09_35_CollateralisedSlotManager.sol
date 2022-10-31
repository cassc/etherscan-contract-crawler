pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

/// @dev Management of the collateralised SLOT accounts for all users, KNOTs and StakeHouses
abstract contract CollateralisedSlotManager {

    event CollateralisedOwnerAddedToKnot(bytes knotId, address indexed owner);

    /// @notice User is able to trigger beacon chain withdrawal
    event UserEnabledForWithdrawal(address indexed user, bytes memberId);

    /// @notice User has withdrawn ETH from beacon chain - do not allow any more withdrawals
    event UserWithdrawn(address indexed user, bytes memberId);

    /// @notice Total collateralised SLOT owned by an account across all KNOTs in a given StakeHouse
    /// @dev Stakehouse address -> user account -> SLOT balance
    mapping(address => mapping(address => uint256)) public totalUserCollateralisedSLOTBalanceInHouse;

    /// @notice Total collateralised SLOT owned by an account for a given KNOT in a Stakehouse
    /// @dev Stakehouse address -> user account -> Knot ID (bls pub key) -> SLOT balance collateralised against the KNOT
    mapping(address => mapping(address => mapping(bytes => uint256))) public totalUserCollateralisedSLOTBalanceForKnot;

    /// @notice List of accounts that have ever owned collateralised SLOT for a given KNOT
    mapping(bytes => address[]) public collateralisedSLOTOwners;

    /// @notice Given a KNOT and account, a flag represents whether the account has been a collateralised SLOT owner in  the past
    /// @dev KNOT ID (bls pub key) -> user account -> Whether it has been a collateralised SLOT owner
    mapping(bytes => mapping(address => bool)) public isCollateralisedOwner;

    /// @notice If a user account has been able to rage quit a KNOT, this flag is set to true to allow ETH2 funds to be claimed
    /// @dev user account -> Knot ID (validator pub key) -> enabled for withdrawal
    mapping(address => mapping(bytes => bool)) public isUserEnabledForKnotWithdrawal;

    /// @notice Once ETH2 funds have been redeemed, this flag is set to true in order to block double withdrawals
    /// @dev user account -> Knot ID (validator pub key) -> has user withdrawn
    mapping(address => mapping(bytes => bool)) public userWithdrawn;

    /// @notice Total number of collateralised SLOT owners for a given KNOT
    /// @param _memberId BLS public key of the KNOT
    function numberOfCollateralisedSlotOwnersForKnot(bytes calldata _memberId) external view returns (uint256) {
        return collateralisedSLOTOwners[_memberId].length;
    }

    /// @notice Fetch a collateralised SLOT owner address for a specific KNOT at a specific index
    function getCollateralisedOwnerAtIndex(bytes calldata _memberId, uint256 _index) external view returns (address) {
        return collateralisedSLOTOwners[_memberId][_index];
    }

    /// @dev Increases the collateralised SLOT balance owned by an account under a given KNOT
    /// @dev This can happen when the KNOT is added to a StakeHouse and also when SLOT is bought after slashing events
    function _increaseCollateralisedBalance(address _stakeHouse, address _user, bytes memory _memberId, uint256 _amount) internal {
        // Maintain a list of historical collateralised SLOT owners
        if (!isCollateralisedOwner[_memberId][_user]) {
            collateralisedSLOTOwners[_memberId].push(_user);
            isCollateralisedOwner[_memberId][_user] = true;
            emit CollateralisedOwnerAddedToKnot(_memberId, _user);
        }

        // Increase the total amount of collateralised SLOT owned by an account across all KNOTs in a given stake house
        totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][_user] += _amount;

        // Increase the total sETH owned by the account for the given KNOT
        totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][_user][_memberId] += _amount;
    }

    /// @dev Decrease the collateralised SLOT balance owned by an account under a given KNOT
    /// @dev This can happen under slashing or rage quit
    function _decreaseCollateralisedBalance(address _stakeHouse, address _user, bytes memory _memberId, uint256 _amount) internal {
        totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][_user] -= _amount;
        totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][_user][_memberId] -= _amount;
    }

    /// @dev Once a rage quit has burnt all of a user's derivatives, this sets a flag that will authorise this account, for the specified KNOT to withdraw ETH
    /// @dev This method takes care of reducing balances as the associated tokens have been burnt
    function _enableUserForKnotWithdrawal(address _user, bytes memory _memberId) internal {
        require(!isUserEnabledForKnotWithdrawal[_user][_memberId], "User already enabled for withdrawal");

        isUserEnabledForKnotWithdrawal[_user][_memberId] = true;

        emit UserEnabledForWithdrawal(_user, _memberId);
    }

    /// @dev This method marks a KNOT as fully withdrawn due to the underlying ETH being unstaked
    function _markUserAsWithdrawn(address _user, bytes memory _memberId) internal {
        require(isUserEnabledForKnotWithdrawal[_user][_memberId], "Not enabled for withdrawal");
        require(!userWithdrawn[_user][_memberId], "User already withdrawn");

        userWithdrawn[_user][_memberId] = true;

        emit UserWithdrawn(_user, _memberId);
    }
}