// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

interface IPositionNFTs {

    function ownerOf(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function getOwner(
        uint256 _nftId
    )
        external
        view
        returns (address);


    function totalSupply()
        external
        view
        returns (uint256);

    function reserved(
        address _owner
    )
        external
        view
        returns (uint256);

    function reservePosition()
        external;

    function mintPosition()
        external;

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        view
        returns (uint256);

    function mintPositionForUser(
        address _user
    )
        external
        returns (uint256);

    function reservePositionForUser(
        address _user
    )
        external
        returns (uint256);

    function getApproved(
        uint256 _nftId
    )
        external
        returns (address);
}