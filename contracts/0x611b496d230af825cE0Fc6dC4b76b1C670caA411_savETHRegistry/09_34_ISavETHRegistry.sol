pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

interface ISavETHRegistry {
    /// @notice KNOT transferred from one index to another
    event KnotTransferredToAnotherIndex(bytes memberId, uint256 indexed newIndexId);

    /// @notice Account approved to move KNOT from one index to another
    event ApprovedSpenderForKnotInIndex(bytes memberId, address indexed spender);

    /// @notice KNOT moved from index into open index
    event KnotAddedToOpenIndex(bytes memberId, address indexed indexOwner, uint256 savETHSent);

    /// @notice KNOT moved from index into open index to withdraw dETH immediately
    event KnotAddedToOpenIndexAndDETHWithdrawn(bytes memberId);

    /// @notice dETH inflation rewards minted to KNOT part of index
    event dETHAddedToKnotInIndex(bytes memberId, uint256 dETH);

    /// @notice dETH withdrawn
    event dETHWithdrawnFromOpenIndex(uint256 amount);

    /// @notice dETH inflation rewards minted to know part of open index
    event dETHReservesAddedToOpenIndex(bytes memberId, uint256 amount);

    /// @notice KNOT has exercised redemption rights
    event RageQuitKnot(bytes memberId);

    /// @notice dETH brought back to registry
    event dETHDepositedIntoRegistry(address indexed depositor, uint256 amount);

    /// @notice KNOT added to index
    event KnotInsertedIntoIndex(bytes memberId, uint256 indexed indexId);

    /// @notice New index created
    event IndexCreated(uint256 indexed indexId);

    /// @notice Ownership of index given to new address
    event IndexOwnershipTransferred(uint256 indexId);

    /// @notice Account authorised to transfer ownership of index
    event ApprovedSpenderForIndexTransfer(uint256 indexed indexId, address indexed spender);

    /// @notice Allow an owner of an index to approve another account to transfer ownership (like a marketplace)
    /// @param _indexId ID of the index being approved
    /// @param _owner of the index
    /// @param _spender Authorised spender or zero address to clear approval
    function approveForIndexOwnershipTransfer(
        uint256 _indexId,
        address _owner,
        address _spender
    ) external;

    /// @notice Transfer ownership of the entire sub-index of KNOTs from one ETH account to another so long as the new owner does not already own an index
    /// @param _indexId ID of the index receiving a new owner
    /// @param _currentOwnerOrSpender Account initiating the index transfer which must either be the index owner or approved spender
    /// @param _newOwner New account receiving ownership of the index and all sub KNOTs
    function transferIndexOwnership(
        uint256 _indexId,
        address _currentOwnerOrSpender,
        address _newOwner
    ) external;

    /// @notice Allows an index owner or approved KNOT spender to transfer ownership of a KNOT from one index to another
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _memberId of the KNOT
    /// @param _indexOwnerOrSpender Account initiating the transfer which is either index owner or spender of the KNOT
    /// @param _newIndexId ID of the index receiving the KNOT
    function transferKnotToAnotherIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwnerOrSpender,
        uint256 _newIndexId
    ) external;

    /// @notice Allows an index owner to approve a marketplace to transfer a knot to another index
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _memberId of the KNOT
    /// @param _indexOwner Address of the index owner who is the only account allowed to do this operation
    /// @param _spender Account that is auth to do the transfer. Set to address(0) to reset the allowance
    function approveSpendingOfKnotInIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner,
        address _spender
    ) external;

    /// @notice Bring a KNOT that is part of an index into the open index in order to get access to the savETH <> dETH
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _memberId of the KNOT
    /// @param _owner Address of the index owner
    /// @param _recipient Address that will receive savETH
    function addKnotToOpenIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _owner,
        address _recipient
    ) external;

    /// @notice Given a KNOT that is part of the open index, allow a savETH holder to isolate the KNOT from the index gaining exclusive rights to the network staking rewards
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _memberId KNOT ID within the StakeHouse
    /// @param _savETHOwner Caller that has the savETH funds required for isolation
    /// @param _indexId ID of the index receiving the isolated funds
    function isolateKnotFromOpenIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _savETHOwner,
        uint256 _indexId
    ) external;

    /// @notice In a single transaction, add knot to open index and withdraw dETH in registry
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _memberId KNOT ID that belongs to an index
    /// @param _indexOwner Owner of the index
    /// @param _recipient Recipient of dETH tokens
    function addKnotToOpenIndexAndWithdraw(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner,
        address _recipient
    ) external;

    /// @notice In a single transaction, deposit dETH and isolate a knot into an index
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _memberId KNOT ID that requires adding to an index
    /// @param _dETHOwner Address that owns dETH required for isolation
    /// @param _indexId ID of the index that the KNOT is being added into
    function depositAndIsolateKnotIntoIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _dETHOwner,
        uint256 _indexId
    ) external;

    /// @notice Allows a SaveETH holder to exchange some or all of their SaveETH for dETH
    /// @param _savETHOwner Address of the savETH owner withdrawing dETH from registry
    /// @param _recipient Recipient of the dETH which can be user burning their savETH tokens or anyone else
    /// @param _amount of SaveETH to burn
    function withdraw(address _savETHOwner, address _recipient, uint128 _amount) external;

    /// @notice Deposit dETH in exchange for SaveETH
    /// @param _dETHOwner Address of the dETH owner depositing dETH into the registry
    /// @param _savETHRecipient Recipient of the savETH which can be anyone
    /// @param _amount of dETH being deposited
    function deposit(address _dETHOwner, address _savETHRecipient,  uint128 _amount) external;
}