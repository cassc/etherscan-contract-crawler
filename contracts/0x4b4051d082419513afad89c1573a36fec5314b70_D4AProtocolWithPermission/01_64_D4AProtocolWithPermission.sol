// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {DaoMintInfo, UserMintInfo, UserMintCapParam} from "contracts/interface/D4AStructs.sol";
import {NotDaoOwner} from "contracts/interface/D4AErrors.sol";

import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import {IPermissionControl} from "contracts/interface/IPermissionControl.sol";
import {D4AProtocol} from "contracts/D4AProtocol.sol";
import {D4ASettingsBaseStorage} from "contracts/D4ASettings/D4ASettingsBaseStorage.sol";

contract D4AProtocolWithPermission is D4AProtocol, EIP712Upgradeable {
    bytes32 internal constant MINTNFT_TYPEHASH =
        keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)");

    mapping(bytes32 daoId => DaoMintInfo daoMintInfo) internal _daoMintInfos;

    /*////////////////////////////////////////////////
                         Getters                     
    ////////////////////////////////////////////////*/
    function getDaoMintCap(bytes32 daoId) public view returns (uint32) {
        return _daoMintInfos[daoId].daoMintCap;
    }

    function getUserMintInfo(bytes32 daoId, address account) public view returns (uint32 minted, uint32 userMintCap) {
        minted = _daoMintInfos[daoId].userMintInfos[account].minted;
        userMintCap = _daoMintInfos[daoId].userMintInfos[account].mintCap;
    }

    function createCanvas(bytes32 daoId, string calldata canvasUri, bytes32[] calldata proof)
        external
        payable
        nonReentrant
        returns (bytes32)
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (l.permission_control.isCanvasCreatorBlacklisted(daoId, msg.sender)) revert Blacklisted();
        if (!l.permission_control.inCanvasCreatorWhitelist(daoId, msg.sender, proof)) {
            revert NotInWhitelist();
        }
        return _createCanvas(daoId, canvasUri);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        __ReentrancyGuard_init();
        project_num = l.reserved_slots;
        __EIP712_init("D4AProtocolWithPermission", "1");
    }

    error ExceedMaxMintAmount();

    modifier ableToMint(bytes32 daoId, bytes32[] calldata proof, uint256 amount) {
        _checkMintEligibility(daoId, msg.sender, proof, amount);
        _;
    }

    function _checkMintEligibility(bytes32 daoId, address account, bytes32[] calldata proof, uint256 amount)
        internal
        view
    {
        if (!_ableToMint(daoId, account, proof, amount)) revert ExceedMaxMintAmount();
    }

    function mintNFT(
        bytes32 daoId,
        bytes32 _canvas_id,
        string calldata _token_uri,
        bytes32[] calldata proof,
        uint256 _flat_price,
        bytes calldata _signature
    ) external payable nonReentrant returns (uint256) {
        {
            _checkMintEligibility(daoId, msg.sender, proof, 1);
        }
        _verifySignature(_canvas_id, _token_uri, _flat_price, _signature);
        _daoMintInfos[daoId].userMintInfos[msg.sender].minted += 1;
        return _mintNft(_canvas_id, _token_uri, _flat_price);
    }

    function batchMint(
        bytes32 daoId,
        bytes32 canvasId,
        bytes32[] calldata proof,
        MintNftInfo[] calldata mintNftInfos,
        bytes[] calldata signatures
    ) external payable nonReentrant returns (uint256[] memory) {
        uint32 length = uint32(mintNftInfos.length);
        {
            _checkMintEligibility(daoId, msg.sender, proof, length);
            for (uint32 i = 0; i < length;) {
                _verifySignature(canvasId, mintNftInfos[i].tokenUri, mintNftInfos[i].flatPrice, signatures[i]);
                unchecked {
                    ++i;
                }
            }
        }
        _daoMintInfos[daoId].userMintInfos[msg.sender].minted += length;
        return _mintNft(daoId, canvasId, mintNftInfos);
    }

    event MintCapSet(bytes32 indexed daoId, uint32 daoMintCap, UserMintCapParam[] userMintCapParams);

    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        IPermissionControl.Whitelist memory whitelist,
        IPermissionControl.Blacklist memory blacklist,
        IPermissionControl.Blacklist memory unblacklist
    ) public override {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (msg.sender != l.project_proxy && msg.sender != l.owner_proxy.ownerOf(daoId)) {
            revert NotDaoOwner();
        }
        DaoMintInfo storage daoMintInfo = _daoMintInfos[daoId];
        daoMintInfo.daoMintCap = daoMintCap;
        uint256 length = userMintCapParams.length;
        for (uint256 i = 0; i < length;) {
            daoMintInfo.userMintInfos[userMintCapParams[i].minter].mintCap = userMintCapParams[i].mintCap;
            unchecked {
                ++i;
            }
        }

        emit MintCapSet(daoId, daoMintCap, userMintCapParams);

        l.permission_control.modifyPermission(daoId, whitelist, blacklist, unblacklist);
    }

    error Blacklisted();
    error NotInWhitelist();

    function _ableToMint(bytes32 daoId, address account, bytes32[] calldata proof, uint256 amount)
        internal
        view
        returns (bool)
    {
        // check priority
        // 1. blacklist
        // 2. designated mint cap
        // 3. whitelist (merkle tree || ERC721)
        // 4. DAO mint cap
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        IPermissionControl permissionControl = l.permission_control;
        if (permissionControl.isMinterBlacklisted(daoId, account)) {
            revert Blacklisted();
        }
        uint32 daoMintCap;
        uint128 userMinted;
        uint128 userMintCap;
        {
            DaoMintInfo storage daoMintInfo = _daoMintInfos[daoId];
            daoMintCap = daoMintInfo.daoMintCap;
            UserMintInfo memory userMintInfo = daoMintInfo.userMintInfos[account];
            userMinted = userMintInfo.minted;
            userMintCap = userMintInfo.mintCap;
        }

        bool isWhitelistOff;
        {
            IPermissionControl.Whitelist memory whitelist = permissionControl.getWhitelist(daoId);
            isWhitelistOff = whitelist.minterMerkleRoot == bytes32(0) && whitelist.minterNFTHolderPasses.length == 0;
        }

        uint256 expectedMinted = userMinted + amount;
        // no whitelist
        if (isWhitelistOff) {
            return daoMintCap == 0 ? true : expectedMinted <= daoMintCap;
        }

        // whitelist on && not in whitelist
        if (!permissionControl.inMinterWhitelist(daoId, account, proof)) {
            revert NotInWhitelist();
        }

        // designated mint cap
        return userMintCap != 0 ? expectedMinted <= userMintCap : daoMintCap != 0 ? expectedMinted <= daoMintCap : true;
    }

    error InvalidSignature();

    function _verifySignature(
        bytes32 _canvas_id,
        string calldata _token_uri,
        uint256 _flat_price,
        bytes calldata _signature
    ) internal view {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINTNFT_TYPEHASH, _canvas_id, keccak256(bytes(_token_uri)), _flat_price))
        );
        address signer = ECDSAUpgradeable.recover(digest, _signature);
        if (
            !IAccessControlUpgradeable(address(this)).hasRole(keccak256("SIGNER_ROLE"), signer)
                && signer != l.owner_proxy.ownerOf(_canvas_id)
        ) revert InvalidSignature();
    }
}