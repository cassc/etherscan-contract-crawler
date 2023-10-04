// SPDX-License-Identifier: ---DG----

pragma solidity =0.8.21;

interface ERC721 {

    function ownerOf(
        uint256 _tokenId
    )
        external
        view
        returns (address);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external;
}

interface ERC20 {

    function approve(
        address spender,
        uint256 amount
    )
        external 
        returns (bool);
        
    function burn(
        uint256 _amount
    )
        external;
}

interface DGAccessories  {

    function issueTokens(
        address[] calldata _beneficiaries,
        uint256[] calldata _itemIds
    )
        external;

    function encodeTokenId(
        uint256 _itemId,
        uint256 _issuedId
    )
        external
        pure
        returns (uint256 id);

    function decodeTokenId(
        uint256 _tokenId
    )
        external
        pure
        returns (
            uint256 itemId,
            uint256 issuedId
        );

    function items(
        uint256 _id
    )
        external
        view
        returns (
            string memory rarity,
            uint256 maxSupply,
            uint256 totalSupply,
            uint256 price,
            address beneficiary,
            string memory metadata,
            string memory contentHash
        );

    function itemsCount()
        external
        view
        returns (uint256);
}