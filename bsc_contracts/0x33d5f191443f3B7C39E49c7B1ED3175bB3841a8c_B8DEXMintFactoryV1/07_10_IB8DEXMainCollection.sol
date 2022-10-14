// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IB8DEXMainCollection {

    /**
     * @notice Get nftId for a specific tokenId.
     *
     * @param _tokenId: token Id
     */
    function getNftId(
        uint256 _tokenId
    )
    external
    view
    returns (uint8);

    /**
     * @notice Get the associated nftName for a specific collectionId.
     *
     * @param _nftId: NFT Id
     */
    function getNftName(
        uint8 _nftId
    )
    external
    view
    returns (string memory);

    /**
     * @notice Get the associated nftName for a unique tokenId.
     *
     * @param _tokenId: token Id
     */
    function getNFTNameOfTokenId(
        uint256 _tokenId
    )
    external
    view
    returns (string memory);

    /**
     * @notice Mint NFTs. Only the owner can call it.
     *
     * @param _to: receiver address
     * @param _tokenURI: token URI
     * @param _nftId: NFT Id
     */
    function mint(
        address _to,
        string calldata _tokenURI,
        uint8 _nftId
    )
    external
    returns (uint256);

    /**
     * @notice Set a unique name for each collectionId. It is supposed to be called once.
     *
     * @param _nftId: NFT Id
     * @param _name: NFT name
     */
    function setNFTName(
        uint8 _nftId,
        string calldata _name
    )
    external;

    /**
     * @notice Burn a NFT token. Callable by owner only.
     *
     * @param _tokenId: token Id
     */
    function burn(
        uint256 _tokenId
    )
    external;

    /**
     * @notice Transfer ownership to new address
     *
     * @param _newOwner: new Owner address
     */
    function transferOwnership(
        address _newOwner
    )
    external;

    /**
     * @notice return total supply NFTs
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice return NFT URI
     *
     * @param _tokenId: token Id
     */
    function tokenURI(
        uint256 _tokenId
    )
    external
    view
    returns (string memory);
}