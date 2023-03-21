pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface ISavETHManager {
    /// @notice Allows any account to create a savETH index in order to group KNOTs together that earn exclusive dETH rewards. The index will be owned by _owner
    /// @param _owner Address that will own the new index. ID of the index is auto generated and assigned to this account
    function createIndex(address _owner) external returns (uint256);

    /// @notice Allow an owner of an index to approve another account to transfer ownership (like a marketplace)
    /// @param _indexId ID of the index being approved
    /// @param _spender Authorised spender or zero address to clear approval
    function approveForIndexOwnershipTransfer(
        uint256 _indexId,
        address _spender
    ) external;

    /// @notice Transfer ownership of an index of KNOTs to a new owner
    /// @param _indexId ID of the index having ownership transferred
    /// @param _to Account receiving ownership of the index
    function transferIndexOwnership(uint256 _indexId, address _to) external;

    /// @notice Allows an index owner or KNOT spender to transfer ownership of a KNOT to another index
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _blsPublicKey of the KNOT
    /// @param _newIndexId ID of the index receiving the KNOT
    function transferKnotToAnotherIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        uint256 _newIndexId
    ) external;

    /// @notice Allows an index owner to approve a marketplace to transfer ownership of a KNOT from one index to another
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _blsPublicKey of the KNOT
    /// @param _spender Account that can transfer the knot that is isolated within an index
    function approveSpendingOfKnotInIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _spender
    ) external;

    /// @notice Move a KNOT that is part of an index into the open index in order to get access to the savETH <> dETH
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _blsPublicKey of the KNOT
    /// @param _recipient Address receiving savETH
    function addKnotToOpenIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _recipient
    ) external;

    /// @notice Given a KNOT that is part of the open index, allow a savETH holder to isolate the KNOT into their own index gaining exclusive rights to the network inflation rewards
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _blsPublicKey KNOT ID within the StakeHouse
    /// @param _targetIndexId ID of the index that the KNOT will be added to
    function isolateKnotFromOpenIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        uint256 _targetIndexId
    ) external;

    /// @notice In a single transaction, add knot to open index and withdraw dETH in registry
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _blsPublicKey KNOT ID that belongs to an index
    /// @param _recipient Recipient of dETH tokens
    function addKnotToOpenIndexAndWithdraw(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _recipient
    ) external;

    /// @notice In a single transaction, deposit dETH and isolate a knot into an index
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _blsPublicKey KNOT ID that requires adding to an index
    /// @param _indexId ID of the index that the KNOT is being added into
    function depositAndIsolateKnotIntoIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        uint256 _indexId
    ) external;

    /// @notice Allows a SaveETH holder to exchange some or all of their SaveETH for dETH
    /// @param _amount of SaveETH to burn
    function withdraw(address _recipient, uint128 _amount) external;

    /// @notice Deposit dETH in exchange for SaveETH
    /// @param _amount of dETH being deposited
    function deposit(address _recipient, uint128 _amount) external;

    /// @notice Total number of dETH rewards minted for knot from inflation rewards
    function dETHRewardsMintedForKnot(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Approved spender that can transfer ownership of a KNOT from one index to another (a marketplace for example)
    function approvedKnotSpender(bytes calldata _blsPublicKey) external view returns (address);

    /// @notice Approved spender that can transfer ownership of an entire index (a marketplace for example)
    function approvedIndexSpender(uint256 _indexId) external view returns (address);

    /// @notice Given an index identifier, returns the owner of the index or zero address if index not created
    function indexIdToOwner(uint256 _indexId) external view returns (address);

    /// @notice Total dETH isolated for a knot associated with an index. Returns zero if knot is not part of an index
    function knotDETHBalanceInIndex(uint256 _indexId, bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice ID of KNOT associated index. Zero if part of open index or non zero if part of a user-owned index
    function associatedIndexIdForKnot(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Returns true if KNOT is part of the open index where they can spend their savETH. Otherwise they are part of a user owned index
    function isKnotPartOfOpenIndex(bytes calldata _blsPublicKey) external view returns (bool);

    /// @notice Total number of dETH deposited into the open index that is not part of user owned indices
    function dETHUnderManagementInOpenIndex() external view returns (uint256);

    /// @notice Total number of dETH minted across all KNOTs
    function dETHInCirculation() external view returns (uint256);

    /// @notice Total amount of dETH isolated in user owned indices
    function totalDETHInIndices() external view returns (uint256);

    /// @notice Helper to convert dETH to savETH based on the current exchange rate
    function dETHToSavETH(uint256 _amount) external view returns (uint256);

    /// @notice Helper to convert savETH to dETH based on the current exchange rate
    function savETHToDETH(uint256 _amount) external view returns (uint256);

    /// @notice Address of the dETH token
    function dETHToken() external view returns (address);

    /// @notice Address of the savETH token
    function savETHToken() external view returns (address);
}