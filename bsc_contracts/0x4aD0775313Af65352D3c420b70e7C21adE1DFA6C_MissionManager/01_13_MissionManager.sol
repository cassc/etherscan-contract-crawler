// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "Initializable.sol";
import "IMissionManager.sol";
import "IRentalPool.sol";
import "IWalletFactory.sol";
import "IGamingWallet.sol";
import "NFTRental.sol";
import "AccessManager.sol";

contract MissionManager is Initializable, AccessManager, IMissionManager {
    IRentalPool public rentalPool;
    IWalletFactory public walletFactory;

    mapping(string => NFTRental.Mission) public readyMissions;
    mapping(string => NFTRental.Mission) public ongoingMissions;
    mapping(string => NFTRental.MissionDates) public missionDates;
    mapping(address => string[]) public tenantOngoingMissionUuid;
    mapping(address => string[]) public tenantReadyMissionUuid;

    modifier onlyRentalPool() {
        require(
            msg.sender == address(rentalPool),
            "Only Rental Pool is authorized"
        );
        _;
    }

    function initialize(IRoleRegistry _roleRegistry, address _rentalPoolAddress)
        external
        initializer
    {
        AccessManager.setRoleRegistry(_roleRegistry);
        rentalPool = IRentalPool(_rentalPoolAddress);
    }

    function setWalletFactory(address _walletFactoryAdr)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        walletFactory = IWalletFactory(_walletFactoryAdr);
    }

    function oasisClaimForMission(
        address _gamingWallet,
        address _gameContract,
        bytes calldata data_
    ) external override onlyRole(Roles.REVENUE_MANAGER) returns (bytes memory) {
        IGamingWallet gamingWallet = IGamingWallet(_gamingWallet);
        bytes memory returnData = gamingWallet.oasisClaimForward(
            _gameContract,
            data_
        );
        return returnData;
    }

    function postMissions(NFTRental.Mission[] calldata mission)
        external
        override
    {
        for (uint256 i = 0; i < mission.length; i++) {
            require(
                msg.sender == mission[i].owner,
                "Sender is not mission owner"
            );
            require(
                !tenantHasOngoingMissionForDapp(
                    mission[i].tenant,
                    mission[i].dappId
                ),
                "Tenant already have ongoing mission for dapp"
            );
            require(
                !isMissionPosted(mission[i].uuid),
                "Uuid has already been used"
            );
            rentalPool.verifyAndStake(mission[i]);
            readyMissions[mission[i].uuid] = mission[i];
            tenantReadyMissionUuid[mission[i].tenant].push(mission[i].uuid);
            missionDates[mission[i].uuid] = NFTRental.MissionDates({
                postDate: block.timestamp,
                startDate: 0,
                cancelDate: 0,
                stopDate: 0
            });
            emit MissionPosted(mission[i]);
        }
    }

    function cancelMissions(string[] calldata _uuid) external override {
        for (uint256 i = 0; i < _uuid.length; i++) {
            NFTRental.Mission memory curMission = readyMissions[_uuid[i]];
            require(msg.sender == curMission.owner, "Not mission owner");
            rentalPool.sendNFTsBack(curMission);
            _rmReadyMissionUuid(curMission.tenant, _uuid[i]);
            missionDates[_uuid[i]].cancelDate = block.timestamp;
            emit MissionCanceled(curMission);
        }
    }

    function startMission(string calldata _uuid) external override {
        NFTRental.Mission memory missionToStart = readyMissions[_uuid];
        require(msg.sender == missionToStart.tenant, "Not mission tenant");
        require(
            !tenantHasOngoingMissionForDapp(msg.sender, missionToStart.dappId),
            "Tenant already have ongoing mission for dapp"
        );
        _createWalletIfRequired();
        address _gamingWalletAddress = walletFactory.getGamingWallet(
            msg.sender
        );
        rentalPool.sendStartingMissionNFT(
            missionToStart.uuid,
            _gamingWalletAddress
        );
        tenantOngoingMissionUuid[msg.sender].push(_uuid);
        ongoingMissions[missionToStart.uuid] = missionToStart;
        _rmReadyMissionUuid(msg.sender, _uuid);
        delete readyMissions[missionToStart.uuid];
        missionDates[missionToStart.uuid].startDate = block.timestamp;
        emit MissionStarted(missionToStart);
    }

    function stopMission(string calldata _uuid) external override {
        NFTRental.Mission memory curMission = ongoingMissions[_uuid];
        require(msg.sender == curMission.owner, "Not mission owner");
        missionDates[curMission.uuid].stopDate = block.timestamp;
        emit MissionTerminating(curMission);
    }

    function terminateMission(string calldata _uuid)
        external
        override
        onlyRole(Roles.MISSION_TERMINATOR)
    {
        require(missionDates[_uuid].stopDate > 0, "Mission is not terminating");
        _terminateMission(_uuid);
    }

    function terminateMissionFallback(string calldata _uuid) external override {
        require(
            block.timestamp >= missionDates[_uuid].stopDate + 15 days,
            "15 days should pass"
        );
        NFTRental.Mission memory curMission = ongoingMissions[_uuid];
        require(msg.sender == curMission.owner, "Not mission owner");
        _terminateMission(_uuid);
    }

    function getOngoingMission(string calldata _uuid)
        external
        view
        override
        returns (NFTRental.Mission memory mission)
    {
        return ongoingMissions[_uuid];
    }

    function getReadyMission(string calldata _uuid)
        external
        view
        override
        returns (NFTRental.Mission memory mission)
    {
        return readyMissions[_uuid];
    }

    function tenantHasReadyMissionForDappForOwner(
        address _tenant,
        string calldata _dappId,
        address _owner
    ) external view override returns (bool) {
        return
            rentalPool.ownerHasReadyMissionForTenantForDapp(
                _owner,
                _tenant,
                _dappId
            );
    }

    function getTenantOngoingMissionUuid(address _tenant)
        public
        view
        override
        returns (string[] memory ongoingMissionsUuids)
    {
        return tenantOngoingMissionUuid[_tenant];
    }

    function getTenantReadyMissionUuid(address _tenant)
        public
        view
        override
        returns (string[] memory readyMissionsUuids)
    {
        return tenantReadyMissionUuid[_tenant];
    }

    function tenantHasOngoingMissionForDapp(
        address _tenant,
        string memory _dappId
    ) public view override returns (bool hasMissionForDapp) {
        string[] memory tenantMissionsUuid = tenantOngoingMissionUuid[_tenant];
        for (uint32 i; i < tenantMissionsUuid.length; i++) {
            NFTRental.Mission memory curMission = ongoingMissions[
                tenantMissionsUuid[i]
            ];
            if (
                keccak256(bytes(curMission.dappId)) == keccak256(bytes(_dappId))
            ) {
                return true;
            }
        }
        return false;
    }

    function tenantHasReadyMissionForDapp(
        address _tenant,
        string memory _dappId
    ) public view override returns (bool hasMissionForDapp) {
        string[] memory tenantMissionsUuid = tenantReadyMissionUuid[_tenant];
        for (uint32 i; i < tenantMissionsUuid.length; i++) {
            NFTRental.Mission memory curMission = readyMissions[
                tenantMissionsUuid[i]
            ];
            if (
                keccak256(bytes(curMission.dappId)) == keccak256(bytes(_dappId))
            ) {
                return true;
            }
        }
        return false;
    }

    function getTenantReadyMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) public view override returns (uint256 uuidPosition) {
        string[] memory list = tenantReadyMissionUuid[_tenant];
        for (uint32 i; i < list.length; i++) {
            if (keccak256(bytes(list[i])) == keccak256(bytes(_uuid))) {
                return i;
            }
        }
        return list.length + 1;
    }

    function getTenantOngoingMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) public view override returns (uint256 uuidPosition) {
        string[] memory list = tenantOngoingMissionUuid[_tenant];
        for (uint32 i; i < list.length; i++) {
            if (keccak256(bytes(list[i])) == keccak256(bytes(_uuid))) {
                return i;
            }
        }
        return list.length + 1;
    }

    function isMissionPosted(string calldata _uuid)
        public
        view
        override
        returns (bool)
    {
        return missionDates[_uuid].postDate > 0;
    }

    function batchMissionsDates(string[] calldata _uuid)
        public
        view
        override
        returns (NFTRental.MissionDates[] memory)
    {
        NFTRental.MissionDates[]
            memory missionsDates = new NFTRental.MissionDates[](_uuid.length);
        for (uint256 i = 0; i < _uuid.length; i++) {
            missionsDates[i] = missionDates[_uuid[i]];
        }
        return missionsDates;
    }

    function _createWalletIfRequired() internal {
        if (!walletFactory.hasGamingWallet(msg.sender)) {
            walletFactory.createWallet(msg.sender);
        }
    }

    function _rmMissionUuid(address _tenant, string calldata _uuid) internal {
        uint256 index = getTenantOngoingMissionUuidIndex(_tenant, _uuid);
        uint256 ongoingMissionLength = tenantOngoingMissionUuid[_tenant].length;
        tenantOngoingMissionUuid[_tenant][index] = tenantOngoingMissionUuid[
            _tenant
        ][ongoingMissionLength - 1];
        tenantOngoingMissionUuid[_tenant].pop();
        delete ongoingMissions[_uuid];
    }

    function _rmReadyMissionUuid(address _tenant, string calldata _uuid)
        internal
    {
        uint256 index = getTenantReadyMissionUuidIndex(_tenant, _uuid);
        uint256 readyMissionLength = tenantReadyMissionUuid[_tenant].length;
        tenantReadyMissionUuid[_tenant][index] = tenantReadyMissionUuid[
            _tenant
        ][readyMissionLength - 1];
        tenantReadyMissionUuid[_tenant].pop();
        delete readyMissions[_uuid];
    }

    function _terminateMission(string calldata _uuid) internal {
        NFTRental.Mission memory curMission = ongoingMissions[_uuid];
        address tenant = curMission.tenant;
        address gamingWalletAddress = walletFactory.getGamingWallet(tenant);
        IGamingWallet(gamingWalletAddress).bulkReturnAsset(
            curMission.owner,
            curMission.collections,
            curMission.tokenIds
        );
        _rmMissionUuid(tenant, _uuid);
        emit MissionTerminated(curMission);
    }

    function _requireStakedNFT(
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal view {
        for (uint32 j = 0; j < _tokenIds.length; j++) {
            for (uint32 k = 0; k < _tokenIds[j].length; k++) {
                require(
                    rentalPool.isNFTStaked(
                        _collections[j],
                        msg.sender,
                        _tokenIds[j][k]
                    ) == true,
                    "NFT is not staked"
                );
            }
        }
    }

    function _verifyParam(
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal pure {
        require(
            _collections.length == _tokenIds.length,
            "Incorrect lengths in tokenIds and collections"
        );
        require(_tokenIds[0][0] != 0, "At least one NFT required");
    }
}