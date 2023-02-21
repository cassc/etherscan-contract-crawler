// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Pool to hold the staked NFTs of one collection that are not currently rented out
interface IRentalPool {
    event ERC721Staked(address collection, address owner, uint256 tokenId);

    event ERC1155Staked(
        address collection,
        address owner,
        uint256[] tokenIds,
        uint256[] tokenAmounts
    );

    event ERC721Unstaked(address collection, address owner, uint256 tokenId);

    event ERC1155Unstaked(
        address collection,
        address owner,
        uint256[] tokenIds,
        uint256[] tokenAmounts
    );

    function setMissionManager(address _rentalManager) external;

    function setWalletFactory(address _walletFactory) external;

    function setRequireWhitelisted(bool _isRequired) external;

    function whitelistOwners(address[] calldata _owners) external;

    function removeWhitelistedOwners(address[] calldata _owners) external;

    function verifyAndStake(NFTRental.Mission calldata newMission) external;

    function sendStartingMissionNFT(
        string calldata _uuid,
        address _gamingWallet
    ) external;

    function sendNFTsBack(NFTRental.Mission calldata mission) external;

    function isOwnerWhitelisted(address _owner)
        external
        view
        returns (bool isWhitelisted);

    function ownerHasReadyMissionForTenantForDapp(
        address _owner,
        address _tenant,
        string calldata _dappId
    ) external view returns (bool);
}