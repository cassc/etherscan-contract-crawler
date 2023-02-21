// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Management contract for NFT rentals.
// This mostly stores rental agreements and does the transfer with the wallet contracts
interface IMissionManager {
    event MissionPosted(NFTRental.Mission mission);

    event MissionCanceled(NFTRental.Mission mission);

    event MissionStarted(NFTRental.Mission mission);

    event MissionTerminating(NFTRental.Mission mission);

    event MissionTerminated(NFTRental.Mission mission);

    function setWalletFactory(address _walletFactoryAdr) external;

    function oasisClaimForMission(
        address gamingWallet,
        address gameContract,
        bytes calldata data_
    ) external returns (bytes memory);

    function postMissions(NFTRental.Mission[] calldata mission) external;

    function cancelMissions(string[] calldata _uuid) external;

    function startMission(string calldata _uuid) external;

    function stopMission(string calldata _uuid) external;

    function terminateMission(string calldata _uuid) external;

    function terminateMissionFallback(string calldata _uuid) external;

    function getOngoingMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission calldata mission);

    function getReadyMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission memory mission);

    function tenantHasReadyMissionForDappForOwner(
        address _tenant,
        string calldata _dappId,
        address _owner
    ) external view returns (bool);

    function getTenantOngoingMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function getTenantReadyMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function tenantHasOngoingMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function tenantHasReadyMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function getTenantReadyMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function getTenantOngoingMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function isMissionPosted(string calldata _uuid)
        external
        view
        returns (bool);

    function batchMissionsDates(string[] calldata _uuid)
        external
        view
        returns (NFTRental.MissionDates[] memory);
}