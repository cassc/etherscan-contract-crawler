// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @title iL2ERC1155Bridge
 */
interface iL2ERC1155Bridge {

    // add events
    event WithdrawalInitiated (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes _data
    );

    event WithdrawalBatchInitiated (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256[] _tokenIds,
        uint256[] _amounts,
        bytes _data
    );

    event DepositFinalized (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes _data
    );

    event DepositBatchFinalized (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256[] _tokenIds,
        uint256[] _amounts,
        bytes _data
    );

    event DepositFailed (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes _data
    );

    event DepositBatchFailed (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256[] _tokenIds,
        uint256[] _amounts,
        bytes _data
    );

    function withdraw(
        address _l2Contract,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data,
        uint32 _l1Gas
    )
        external;

    function withdrawBatch(
        address _l2Contract,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes calldata _data,
        uint32 _l1Gas
    )
        external;

    function withdrawTo(
        address _l2Contract,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data,
        uint32 _l1Gas
    )
        external;

    function withdrawBatchTo(
        address _l2Contract,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes calldata _data,
        uint32 _l1Gas
    )
        external;

    function finalizeDeposit(
        address _l1Contract,
        address _l2Contract,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    )
        external;


    function finalizeDepositBatch(
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