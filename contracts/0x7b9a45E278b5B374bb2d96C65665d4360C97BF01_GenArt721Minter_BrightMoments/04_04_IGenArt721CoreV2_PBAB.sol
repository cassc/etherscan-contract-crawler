// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.5.0;

interface IGenArt721CoreV2_PBAB {
    /**
     * @notice Token ID `_tokenId` minted on project ID `_projectId` to `_to`.
     * @dev NatSpec for events not supported in Solidity ^0.5.0
     */
    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId
    );

    // getter function of public variable
    function admin() external view returns (address);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(uint256 tokenId)
        external
        view
        returns (uint256 projectId);

    function isWhitelisted(address sender) external view returns (bool);

    function projectIdToCurrencySymbol(uint256 _projectId)
        external
        view
        returns (string memory);

    function projectIdToCurrencyAddress(uint256 _projectId)
        external
        view
        returns (address);

    function projectIdToArtistAddress(uint256 _projectId)
        external
        view
        returns (address payable);

    function projectIdToPricePerTokenInWei(uint256 _projectId)
        external
        view
        returns (uint256);

    function projectIdToAdditionalPayee(uint256 _projectId)
        external
        view
        returns (address payable);

    function projectIdToAdditionalPayeePercentage(uint256 _projectId)
        external
        view
        returns (uint256);

    function projectTokenInfo(uint256 _projectId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool,
            address,
            uint256,
            string memory,
            address
        );

    function renderProviderAddress() external view returns (address payable);

    function renderProviderPercentage() external view returns (uint256);

    function mint(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);

    function getRoyaltyData(uint256 _tokenId)
        external
        view
        returns (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        );
}