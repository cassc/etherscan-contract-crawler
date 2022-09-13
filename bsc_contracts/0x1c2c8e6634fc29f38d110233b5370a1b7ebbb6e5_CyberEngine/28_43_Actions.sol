// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";

import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { IEssenceNFT } from "../interfaces/IEssenceNFT.sol";
import { ISubscribeMiddleware } from "../interfaces/ISubscribeMiddleware.sol";
import { IEssenceMiddleware } from "../interfaces/IEssenceMiddleware.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";
import { IProfileMiddleware } from "../interfaces/IProfileMiddleware.sol";

import { DataTypes } from "./DataTypes.sol";
import { Constants } from "./Constants.sol";
import { LibString } from "./LibString.sol";
import { CyberNFTBase } from "../base/CyberNFTBase.sol";

library Actions {
    /**
     * @dev Watch ProfileNFT contract for events, see comments in IProfileNFTEvents.sol for the
     * following events
     */
    event DeploySubscribeNFT(
        uint256 indexed profileId,
        address indexed subscribeNFT
    );
    event RegisterEssence(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string name,
        string symbol,
        string essenceTokenURI,
        address essenceMw,
        bytes prepareReturnData
    );
    event DeployEssenceNFT(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address indexed essenceNFT
    );
    event CollectEssence(
        address indexed collector,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        uint256 tokenId,
        bytes preData,
        bytes postData
    );
    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] preDatas,
        bytes[] postDatas
    );

    event SetSubscribeData(
        uint256 indexed profileId,
        string tokenURI,
        address mw,
        bytes prepareReturnData
    );

    event SetEssenceData(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string tokenURI,
        address mw,
        bytes prepareReturnData
    );

    event CreateProfile(
        address indexed to,
        uint256 indexed profileId,
        string handle,
        string avatar,
        string metadata
    );

    event SetPrimaryProfile(address indexed user, uint256 indexed profileId);

    event SetOperatorApproval(
        uint256 indexed profileId,
        address indexed operator,
        bool prevApproved,
        bool approved
    );

    function subscribe(
        DataTypes.SubscribeData calldata data,
        mapping(uint256 => DataTypes.SubscribeStruct)
            storage _subscribeByProfileId,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById
    ) external returns (uint256[] memory result) {
        require(data.profileIds.length > 0, "NO_PROFILE_IDS");
        require(
            data.profileIds.length == data.preDatas.length &&
                data.preDatas.length == data.postDatas.length,
            "LENGTH_MISMATCH"
        );

        result = new uint256[](data.profileIds.length);

        for (uint256 i = 0; i < data.profileIds.length; i++) {
            address subscribeNFT = _subscribeByProfileId[data.profileIds[i]]
                .subscribeNFT;
            address subscribeMw = _subscribeByProfileId[data.profileIds[i]]
                .subscribeMw;
            // lazy deploy subscribe NFT
            if (subscribeNFT == address(0)) {
                subscribeNFT = _deploySubscribeNFT(
                    data.subBeacon,
                    data.profileIds[i],
                    _subscribeByProfileId,
                    _profileById
                );
                emit DeploySubscribeNFT(data.profileIds[i], subscribeNFT);
            }
            if (subscribeMw != address(0)) {
                require(
                    ICyberEngine(data.engine).isSubscribeMwAllowed(subscribeMw),
                    "SUBSCRIBE_MW_NOT_ALLOWED"
                );

                ISubscribeMiddleware(subscribeMw).preProcess(
                    data.profileIds[i],
                    data.sender,
                    subscribeNFT,
                    data.preDatas[i]
                );
            }
            result[i] = ISubscribeNFT(subscribeNFT).mint(data.sender);
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).postProcess(
                    data.profileIds[i],
                    data.sender,
                    subscribeNFT,
                    data.postDatas[i]
                );
            }
        }
        emit Subscribe(
            data.sender,
            data.profileIds,
            data.preDatas,
            data.postDatas
        );
    }

    function collect(
        DataTypes.CollectData calldata data,
        mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
            storage _essenceByIdByProfileId
    ) external returns (uint256 tokenId) {
        require(
            bytes(
                _essenceByIdByProfileId[data.profileId][data.essenceId].tokenURI
            ).length != 0,
            "ESSENCE_NOT_REGISTERED"
        );
        address essenceNFT = _essenceByIdByProfileId[data.profileId][
            data.essenceId
        ].essenceNFT;
        address essenceMw = _essenceByIdByProfileId[data.profileId][
            data.essenceId
        ].essenceMw;

        // lazy deploy essence NFT
        if (essenceNFT == address(0)) {
            essenceNFT = _deployEssenceNFT(
                data.profileId,
                data.essenceId,
                data.essBeacon,
                _essenceByIdByProfileId
            );
        }
        // run middleware before collecting essence
        if (essenceMw != address(0)) {
            require(
                ICyberEngine(data.engine).isEssenceMwAllowed(essenceMw),
                "ESSENCE_MW_NOT_ALLOWED"
            );

            IEssenceMiddleware(essenceMw).preProcess(
                data.profileId,
                data.essenceId,
                data.collector,
                essenceNFT,
                data.preData
            );
        }
        tokenId = IEssenceNFT(essenceNFT).mint(data.collector);
        if (essenceMw != address(0)) {
            IEssenceMiddleware(essenceMw).postProcess(
                data.profileId,
                data.essenceId,
                data.collector,
                essenceNFT,
                data.postData
            );
        }
        emit CollectEssence(
            data.collector,
            data.profileId,
            data.essenceId,
            tokenId,
            data.preData,
            data.postData
        );
    }

    function registerEssence(
        DataTypes.RegisterEssenceData calldata data,
        address engine,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
            storage _essenceByIdByProfileId
    ) external returns (uint256) {
        require(
            data.essenceMw == address(0) ||
                ICyberEngine(engine).isEssenceMwAllowed(data.essenceMw),
            "ESSENCE_MW_NOT_ALLOWED"
        );

        require(bytes(data.name).length != 0, "EMPTY_NAME");
        require(bytes(data.symbol).length != 0, "EMPTY_SYMBOL");
        require(bytes(data.essenceTokenURI).length != 0, "EMPTY_URI");

        uint256 id = ++_profileById[data.profileId].essenceCount;
        _essenceByIdByProfileId[data.profileId][id].name = data.name;
        _essenceByIdByProfileId[data.profileId][id].symbol = data.symbol;
        _essenceByIdByProfileId[data.profileId][id].tokenURI = data
            .essenceTokenURI;
        _essenceByIdByProfileId[data.profileId][id].transferable = data
            .transferable;
        bytes memory returnData;
        if (data.essenceMw != address(0)) {
            _essenceByIdByProfileId[data.profileId][id].essenceMw = data
                .essenceMw;
            returnData = IEssenceMiddleware(data.essenceMw).setEssenceMwData(
                data.profileId,
                id,
                data.initData
            );
        }

        // if the user chooses to deploy essence NFT at registration
        if (data.deployAtRegister) {
            _deployEssenceNFT(
                data.profileId,
                id,
                data.essBeacon,
                _essenceByIdByProfileId
            );
        }

        emit RegisterEssence(
            data.profileId,
            id,
            data.name,
            data.symbol,
            data.essenceTokenURI,
            data.essenceMw,
            returnData
        );
        return id;
    }

    function setSubscribeData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata data,
        address engine,
        mapping(uint256 => DataTypes.SubscribeStruct)
            storage _subscribeByProfileId
    ) external {
        require(
            mw == address(0) || ICyberEngine(engine).isSubscribeMwAllowed(mw),
            "SUB_MW_NOT_ALLOWED"
        );
        _subscribeByProfileId[profileId].subscribeMw = mw;
        bytes memory returnData;
        if (mw != address(0)) {
            returnData = ISubscribeMiddleware(mw).setSubscribeMwData(
                profileId,
                data
            );
        }
        _subscribeByProfileId[profileId].tokenURI = uri;
        emit SetSubscribeData(profileId, uri, mw, returnData);
    }

    function setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data,
        address engine,
        mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
            storage _essenceByIdByProfileId
    ) external {
        require(
            mw == address(0) || ICyberEngine(engine).isEssenceMwAllowed(mw),
            "ESSENCE_MW_NOT_ALLOWED"
        );
        require(
            bytes(_essenceByIdByProfileId[profileId][essenceId].name).length !=
                0,
            "ESSENCE_DOES_NOT_EXIST"
        );

        _essenceByIdByProfileId[profileId][essenceId].essenceMw = mw;
        bytes memory returnData;
        if (mw != address(0)) {
            returnData = IEssenceMiddleware(mw).setEssenceMwData(
                profileId,
                essenceId,
                data
            );
        }
        _essenceByIdByProfileId[profileId][essenceId].tokenURI = uri;
        emit SetEssenceData(profileId, essenceId, uri, mw, returnData);
    }

    function generateTokenURI(
        uint256 tokenId,
        address nftDescriptor,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(uint256 => DataTypes.SubscribeStruct)
            storage _subscribeByProfileId
    ) external view returns (string memory) {
        require(address(nftDescriptor) != address(0), "NFT_DESCRIPTOR_NOT_SET");
        address subscribeNFT = _subscribeByProfileId[tokenId].subscribeNFT;
        uint256 subscribers;
        if (subscribeNFT != address(0)) {
            subscribers = CyberNFTBase(subscribeNFT).totalSupply();
        }

        return
            IProfileNFTDescriptor(nftDescriptor).tokenURI(
                DataTypes.ConstructTokenURIParams({
                    tokenId: tokenId,
                    handle: _profileById[tokenId].handle,
                    subscribers: subscribers
                })
            );
    }

    function _deploySubscribeNFT(
        address subBeacon,
        uint256 profileId,
        mapping(uint256 => DataTypes.SubscribeStruct)
            storage _subscribeByProfileId,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById
    ) private returns (address) {
        string memory name = string(
            abi.encodePacked(
                _profileById[profileId].handle,
                Constants._SUBSCRIBE_NFT_NAME_SUFFIX
            )
        );
        string memory symbol = string(
            abi.encodePacked(
                LibString.toUpper(_profileById[profileId].handle),
                Constants._SUBSCRIBE_NFT_SYMBOL_SUFFIX
            )
        );
        address subscribeNFT = address(
            new BeaconProxy{ salt: bytes32(profileId) }(
                subBeacon,
                abi.encodeWithSelector(
                    ISubscribeNFT.initialize.selector,
                    profileId,
                    name,
                    symbol
                )
            )
        );

        _subscribeByProfileId[profileId].subscribeNFT = subscribeNFT;
        return subscribeNFT;
    }

    function _deployEssenceNFT(
        uint256 profileId,
        uint256 essenceId,
        address essBeacon,
        mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
            storage _essenceByIdByProfileId
    ) private returns (address) {
        bytes memory initData = abi.encodeWithSelector(
            IEssenceNFT.initialize.selector,
            profileId,
            essenceId,
            _essenceByIdByProfileId[profileId][essenceId].name,
            _essenceByIdByProfileId[profileId][essenceId].symbol,
            _essenceByIdByProfileId[profileId][essenceId].transferable
        );
        address essenceNFT = address(
            new BeaconProxy{ salt: bytes32(profileId) }(essBeacon, initData)
        );
        _essenceByIdByProfileId[profileId][essenceId].essenceNFT = essenceNFT;
        emit DeployEssenceNFT(profileId, essenceId, essenceNFT);

        return essenceNFT;
    }

    function createProfilePreProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata preData,
        address ENGINE
    ) external returns (address profileMw) {
        profileMw = ICyberEngine(ENGINE).getProfileMwByNamespace(address(this));

        if (profileMw != address(0)) {
            require(
                ICyberEngine(ENGINE).isProfileMwAllowed(profileMw),
                "PROFILE_MW_NOT_ALLOWED"
            );

            IProfileMiddleware(profileMw).preProcess{ value: msg.value }(
                params,
                preData
            );
        }
    }

    function createProfilePostProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata postData,
        DataTypes.CreateProfilePostProcessData calldata data,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(uint256 => string) storage _metadataById,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash,
        mapping(address => uint256) storage _addressToPrimaryProfile,
        mapping(uint256 => mapping(address => bool)) storage _operatorApproval
    ) external {
        _profileById[data.tokenID].handle = params.handle;
        _profileById[data.tokenID].avatar = params.avatar;
        _metadataById[data.tokenID] = params.metadata;
        _profileIdByHandleHash[data.handleHash] = data.tokenID;

        emit CreateProfile(
            params.to,
            data.tokenID,
            params.handle,
            params.avatar,
            params.metadata
        );

        if (_addressToPrimaryProfile[params.to] == 0) {
            setPrimaryProfile(
                params.to,
                data.tokenID,
                _addressToPrimaryProfile
            );
        }

        if (params.operator != address(0)) {
            require(params.to != params.operator, "INVALID_OPERATOR");
            setOperatorApproval(
                data.tokenID,
                params.operator,
                true,
                _operatorApproval
            );
        }
        if (data.profileMw != address(0)) {
            IProfileMiddleware(data.profileMw).postProcess(params, postData);
        }
    }

    function setPrimaryProfile(
        address owner,
        uint256 profileId,
        mapping(address => uint256) storage _addressToPrimaryProfile
    ) public {
        _addressToPrimaryProfile[owner] = profileId;
        emit SetPrimaryProfile(owner, profileId);
    }

    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved,
        mapping(uint256 => mapping(address => bool)) storage _operatorApproval
    ) public {
        require(operator != address(0), "ZERO_ADDRESS");
        bool prev = _operatorApproval[profileId][operator];
        _operatorApproval[profileId][operator] = approved;
        emit SetOperatorApproval(profileId, operator, prev, approved);
    }
}