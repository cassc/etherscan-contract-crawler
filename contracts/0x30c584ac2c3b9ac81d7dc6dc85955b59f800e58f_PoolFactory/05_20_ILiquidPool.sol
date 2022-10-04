// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface ILiquidPool {

    function depositFunds(
        uint256 _amount,
        address _depositor
    )
        external
        returns (uint256);

    function withdrawFunds(
        uint256 _shares,
        address _user
    )
        external
        returns (uint256);

    function borrowFunds(
        address _borrowAddress,
        uint256 _borrowAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external;

    function borrowMoreFunds(
        address _borrowAddress,
        uint256 _borrowAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external;

    function paybackFunds(
        uint256 _payAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        returns (uint256);

    function liquidateNFT(
        address _liquidator,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        returns (uint256);

    function getLoanOwner(
        address _nft,
        uint256 _tokenID
    )
        external
        view
        returns (address);

    function withdrawFee()
        external;

    function poolToken()
        external
        view
        returns (address);

    function calculateWithdrawAmount(
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function lockFeeDestination()
        external;

    function changeFeeDestinationAddress(
        address _newFeeDestinationAddress
    )
        external;

    function expandPool(
        address _nftAddress
    )
        external;

    function addCollection(
        address _nftAddress
    )
        external;
}
