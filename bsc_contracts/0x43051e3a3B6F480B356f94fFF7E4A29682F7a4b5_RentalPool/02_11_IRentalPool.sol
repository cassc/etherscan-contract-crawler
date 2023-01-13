// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Pool to hold the staked NFTs of one collection that are not currently rented out
interface IRentalPool {
    event NFTStaked(address collection, address owner, uint256 tokenId);

    event NFTUnstaked(address collection, address owner, uint256 tokenId);

    function setMissionManager(address _rentalManager) external;

    function setWalletFactory(address _walletFactory) external;

    function whitelistOwners(address[] calldata _owners) external;

    function removeWhitelistedOwners(address[] calldata _owners) external;

    function verifyAndStake(NFTRental.Mission calldata newMission) external;

    function sendStartingMissionNFT(
        string calldata _uuid,
        address _gamingWallet
    ) external;

    function sendNFTsBack(NFTRental.Mission calldata mission) external;

    function isNFTStaked(
        address collection,
        address owner,
        uint256 tokenId
    ) external view returns (bool isStaked);

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