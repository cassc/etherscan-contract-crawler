// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IRentalPool.sol";
import "IMissionManager.sol";
import "IWalletFactory.sol";
import "NFTRental.sol";
import "EnumerableSet.sol";
import "IERC721.sol";
import "AccessManager.sol";

contract RentalPool is AccessManager, IRentalPool {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => mapping(address => EnumerableSet.UintSet))
        private stakedNFTs;
    mapping(address => mapping(address => mapping(string => bool)))
        public ownerHasReadyMissionForTenantForDapp;
    mapping(address => bool) public whitelistedOwners;

    address public missionManager;
    address public walletFactory;

    modifier onlyMissionManager() {
        require(
            msg.sender == missionManager,
            "Only mission manager is authorized"
        );
        _;
    }

    constructor(IRoleRegistry _roleRegistry) {
        setRoleRegistry(_roleRegistry);
    }

    function setMissionManager(address _missionManager)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        require(missionManager == address(0), "Mission manager already set");
        missionManager = _missionManager;
    }

    function setWalletFactory(address _walletFactory)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        walletFactory = _walletFactory;
    }

    function whitelistOwners(address[] calldata _owners)
        external
        override
        onlyRole(Roles.MISSION_CONFIGURATOR)
    {
        for (uint32 i = 0; i < _owners.length; i++) {
            whitelistedOwners[_owners[i]] = true;
        }
    }

    function removeWhitelistedOwners(address[] calldata _owners)
        external
        override
        onlyRole(Roles.MISSION_CONFIGURATOR)
    {
        for (uint32 i = 0; i < _owners.length; i++) {
            whitelistedOwners[_owners[i]] = false;
        }
    }

    function verifyAndStake(NFTRental.Mission calldata newMission)
        external
        override
        onlyMissionManager
    {
        require(
            whitelistedOwners[newMission.owner],
            "Owner is not whitelisted"
        );
        _verifyParam(
            newMission.dappId,
            newMission.collections,
            newMission.tokenIds
        );
        require(
            !ownerHasReadyMissionForTenantForDapp[newMission.owner][
                newMission.tenant
            ][newMission.dappId],
            "Owner already have ready mission for tenant and dapp"
        );
        _stakeNFT(
            newMission.owner,
            newMission.collections,
            newMission.tokenIds
        );
        ownerHasReadyMissionForTenantForDapp[newMission.owner][
            newMission.tenant
        ][newMission.dappId] = true;
    }

    function sendStartingMissionNFT(
        string calldata _uuid,
        address _gamingWallet
    ) external override onlyMissionManager {
        NFTRental.Mission memory curMission = IMissionManager(missionManager)
            .getReadyMission(_uuid);
        require(
            IWalletFactory(walletFactory).verifyCollectionForUniqueDapp(
                curMission.dappId,
                curMission.collections
            ),
            "Collection not linked to Dapp"
        );
        _transferAndUnstakeNFTs(
            curMission.owner,
            _gamingWallet,
            curMission.collections,
            curMission.tokenIds
        );
        delete ownerHasReadyMissionForTenantForDapp[curMission.owner][
            curMission.tenant
        ][curMission.dappId];
    }

    function sendNFTsBack(NFTRental.Mission calldata curMission)
        external
        override
        onlyMissionManager
    {
        _transferAndUnstakeNFTs(
            curMission.owner,
            curMission.owner,
            curMission.collections,
            curMission.tokenIds
        );
        delete ownerHasReadyMissionForTenantForDapp[curMission.owner][
            curMission.tenant
        ][curMission.dappId];
    }

    function isNFTStaked(
        address _collection,
        address _owner,
        uint256 _tokenId
    ) external view override returns (bool isStaked) {
        return stakedNFTs[_owner][_collection].contains(_tokenId);
    }

    function isOwnerWhitelisted(address _owner)
        external
        view
        returns (bool isWhitelisted)
    {
        return whitelistedOwners[_owner];
    }

    function _transferAndUnstakeNFTs(
        address _owner,
        address _recipient,
        address[] memory _collections,
        uint256[][] memory _tokenIds
    ) internal {
        uint256 collectionsLength = _collections.length;
        for (uint32 i; i < collectionsLength; i++) {
            uint256 tokenIdsLength = _tokenIds[i].length;
            for (uint32 j; j < tokenIdsLength; j++) {
                IERC721(_collections[i]).transferFrom(
                    address(this),
                    _recipient,
                    _tokenIds[i][j]
                );
                stakedNFTs[_owner][_collections[i]].remove(_tokenIds[i][j]);
                emit NFTUnstaked(_collections[i], _owner, _tokenIds[i][j]);
            }
        }
    }

    function _stakeNFT(
        address _owner,
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal {
        for (uint32 i; i < _tokenIds.length; i++) {
            for (uint32 j; j < _tokenIds[i].length; j++) {
                IERC721(_collections[i]).transferFrom(
                    _owner,
                    address(this),
                    _tokenIds[i][j]
                );
                stakedNFTs[_owner][_collections[i]].add(_tokenIds[i][j]);
                emit NFTStaked(_collections[i], _owner, _tokenIds[i][j]);
            }
        }
    }

    function _verifyParam(
        string calldata _dappId,
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal view {
        require(
            _collections.length == _tokenIds.length,
            "Incorrect lengths collections and tokenIds"
        );
        require(_tokenIds[0][0] != 0, "At least one NFT required");
        require(
            IWalletFactory(walletFactory).verifyCollectionForUniqueDapp(
                _dappId,
                _collections
            ),
            "Collections correspond to multiple dapp"
        );
    }
}