//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExhibitionable {
    struct Exhibit {
        address contractAddress;
        uint256 tokenId;
    }

    /**
     * @notice Triggered when a a new exhibit has been set
     * @param _tokenId                   Token identifier which is setting an exhibit
     * @param _exhibitContractAddress    The new exhibit contract address
     * @param _exhibitTokenId            The token identifier of the exhibit
     */
    event ExhibitSet(
        uint256 indexed _tokenId,
        address indexed _exhibitContractAddress,
        uint256 _exhibitTokenId
    );

    /**
     * @notice Set an exhibit for a tokenId
     * @param _tokenId                   Token identifier which is setting an exhibit
     * @param _exhibitContractAddress    The new exhibit contract address
     * @param _exhibitTokenId            The token identifier of the exhibit
     */
    function setExhibit(
        uint256 _tokenId,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    ) external;

    /**
     * @notice Return true if the exhibit is owned by exhibtor
     * @param _exhibitor                 Exhibitor claiming ownership
     * @param _exhibitContractAddress    The new exhibit contract address
     * @param _exhibitTokenId            The token identifier of the exhibit
     */
    function exhibitIsOwnedBy(
        address _exhibitor,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    ) external view returns (bool);

    /**
     * @notice Remove the exhibit for a tokenId
     * @param _tokenId                   The token identifier of the exhibit
     */
    function clearExhibit(uint256 _tokenId) external;

    /**
     * @notice Get the exhibit for a tokenId
     * @param _tokenId                   The token identifier of the exhibit
     */
    function getExhibit(uint256 _tokenId) external view returns (Exhibit memory);

    /**
     * @notice Get the exhibit token URI for a tokenId
     * @param _tokenId                   The token identifier of the exhibit
     */
    function getExhibitTokenURI(uint256 _tokenId) external view returns (string memory);
}