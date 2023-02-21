// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IRentalPool.sol";
import "IMissionManager.sol";
import "IWalletFactory.sol";
import "NFTRental.sol";
import "EnumerableSet.sol";
import "IERC721.sol";
import "IERC1155.sol";
import "IERC165.sol";
import "ERC1155Holder.sol";
import "AccessManager.sol";

contract RentalPool is AccessManager, IRentalPool, ERC1155Holder {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes4 internal constant ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    mapping(address => mapping(address => mapping(string => bool)))
        public ownerHasReadyMissionForTenantForDapp;
    mapping(address => bool) public whitelistedOwners;
    bool public requireWhitelisted = false;

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

    function setRequireWhitelisted(bool isRequired)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        requireWhitelisted = isRequired;
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
            whitelistedOwners[newMission.owner] || !requireWhitelisted,
            "Owner is not whitelisted"
        );
        _verifyParam(
            newMission.dappId,
            newMission.collections,
            newMission.tokenIds,
            newMission.tokenAmounts
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
            newMission.tokenIds,
            newMission.tokenAmounts
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
            curMission.tokenIds,
            curMission.tokenAmounts
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
            curMission.tokenIds,
            curMission.tokenAmounts
        );
        delete ownerHasReadyMissionForTenantForDapp[curMission.owner][
            curMission.tenant
        ][curMission.dappId];
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
        uint256[][] memory _tokenIds,
        uint256[][] memory _tokenAmounts
    ) internal {
        uint256 collectionsLength = _collections.length;
        for (uint32 i; i < collectionsLength; i++) {
            uint256 tokenIdsLength = _tokenIds[i].length;
            if (
                IERC165(_collections[i]).supportsInterface(ERC721_INTERFACE_ID)
            ) {
                for (uint32 j; j < tokenIdsLength; j++) {
                    IERC721(_collections[i]).transferFrom(
                        address(this),
                        _recipient,
                        _tokenIds[i][j]
                    );
                    emit ERC721Unstaked(
                        _collections[i],
                        _owner,
                        _tokenIds[i][j]
                    );
                }
            } else if (
                IERC165(_collections[i]).supportsInterface(ERC1155_INTERFACE_ID)
            ) {
                IERC1155(_collections[i]).safeBatchTransferFrom(
                    address(this),
                    _recipient,
                    _tokenIds[i],
                    _tokenAmounts[i],
                    ""
                );
                emit ERC1155Unstaked(
                    _collections[i],
                    _owner,
                    _tokenIds[i],
                    _tokenAmounts[i]
                );
            }
        }
    }

    function _stakeNFT(
        address _owner,
        address[] calldata _collections,
        uint256[][] calldata _tokenIds,
        uint256[][] calldata _tokenAmounts
    ) internal {
        for (uint32 i; i < _collections.length; i++) {
            if (
                IERC165(_collections[i]).supportsInterface(ERC721_INTERFACE_ID)
            ) {
                for (uint32 j; j < _tokenIds[i].length; j++) {
                    IERC721(_collections[i]).transferFrom(
                        _owner,
                        address(this),
                        _tokenIds[i][j]
                    );
                    emit ERC721Staked(_collections[i], _owner, _tokenIds[i][j]);
                }
            } else if (
                IERC165(_collections[i]).supportsInterface(ERC1155_INTERFACE_ID)
            ) {
                IERC1155(_collections[i]).safeBatchTransferFrom(
                    _owner,
                    address(this),
                    _tokenIds[i],
                    _tokenAmounts[i],
                    ""
                );
                emit ERC1155Staked(
                    _collections[i],
                    _owner,
                    _tokenIds[i],
                    _tokenAmounts[i]
                );
            }
        }
    }

    function _verifyParam(
        string calldata _dappId,
        address[] calldata _collections,
        uint256[][] calldata _tokenIds,
        uint256[][] calldata _tokenAmounts
    ) internal view {
        require(
            _collections.length == _tokenIds.length,
            "Incorrect lengths collections and tokenIds"
        );
        require(
            _tokenIds.length == _tokenAmounts.length,
            "Incorrect lengths tokenIds and tokenAmounts"
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