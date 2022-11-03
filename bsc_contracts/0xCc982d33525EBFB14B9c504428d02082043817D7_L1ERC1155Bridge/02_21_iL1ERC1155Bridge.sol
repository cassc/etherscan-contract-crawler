// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @title iL1ERC1155Bridge
 */
interface iL1ERC1155Bridge {

    event DepositInitiated (
        address indexed _l1Contract,
        address indexed _l2Contract,
        address indexed _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes _data
    );

    event DepositBatchInitiated (
        address indexed _l1Contract,
        address indexed _l2Contract,
        address indexed _from,
        address _to,
        uint256[] _tokenIds,
        uint256[] _amounts,
        bytes _data
    );

    event WithdrawalFinalized (
        address indexed _l1Contract,
        address indexed _l2Contract,
        address indexed _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes _data
    );

    event WithdrawalBatchFinalized (
        address indexed _l1Contract,
        address indexed _l2Contract,
        address indexed _from,
        address _to,
        uint256[] _tokenIds,
        uint256[] _amounts,
        bytes _data
    );

    event WithdrawalFailed (
        address indexed _l1Contract,
        address indexed _l2Contract,
        address indexed _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes _data
    );

    event WithdrawalBatchFailed (
        address indexed _l1Contract,
        address indexed _l2Contract,
        address indexed _from,
        address _to,
        uint256[] _tokenIds,
        uint256[] _amounts,
        bytes _data
    );

    function deposit(
        address _l1Contract,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data,
        uint32 _l2Gas
    )
        external;

    function depositBatch(
        address _l1Contract,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes calldata _data,
        uint32 _l2Gas
    )
        external;

    function depositTo(
        address _l1Contract,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data,
        uint32 _l2Gas
    )
        external;

    function depositBatchTo(
        address _l1Contract,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes calldata _data,
        uint32 _l2Gas
    )
        external;

    function finalizeWithdrawal(
        address _l1Contract,
        address _l2Contract,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    )
        external;

    function finalizeWithdrawalBatch(
        address _l1Contract,
        address _l2Contract,
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes calldata _data
    )
        external;
}