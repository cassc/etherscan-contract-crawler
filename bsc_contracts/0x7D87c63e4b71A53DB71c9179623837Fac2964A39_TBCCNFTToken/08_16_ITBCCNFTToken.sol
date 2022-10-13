// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ITBCCNFTToken {
    /**
     * @notice Mint NFT
     * @param _mintAmount: NFT amount
     */
    function mintNFT(
        uint256 _mintAmount
    ) external payable;

    /**
     * @notice Mint NFT for Address
     * @param _mintAmount: NFT amount
     * @param _receiver: receiver address
     * @dev Callable by owner
     */
    function mintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) external;

    /**
     * @notice Getting NFT for Wallet
     * @param _owner: wallet Address
     */
    function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory);

    /**
     * @notice Setting new NFT cost
     * @param _cost: new cost
     * @dev Callable by owner
     */
    function setCost(
        uint256 _cost
    ) external;

    /**
     * @notice Setting new max supply
     * @param _maxSupply: new max supply
     * @dev Callable by owner
     */
    function setMaxSupply(
        uint256 _maxSupply
    ) external;

    /**
     * @notice Setting new IRI Prefix
     * @param _uriPrefix: new prefix
     * @dev Callable by owner
     */
    function setUriPrefix(
        string memory _uriPrefix
    ) external;

    /**
     * @notice Setting new IRI suffix
     * @param _uriSuffix: new suffix
     * @dev Callable by owner
     */
    function setUriSuffix(
        string memory _uriSuffix
    ) external;

    /**
     * @notice Setting new IRI name
     * @param _uriName: new name
     * @dev Callable by owner
     */
    function setUriName(
        string memory _uriName
    ) external;

    /**
     * @notice Setting contract pause
     * @param _state: pause state
     * @dev Callable by owner
     */
    function setPaused(
        bool _state
    ) external;

    /**
     * @notice withdraw
     * @dev Callable by owner
     */
    function withdraw() external;

    /**
     * @notice withdraw TBCC
     * @dev Callable by owner
     */
    function withdrawTBCC()  external;
}