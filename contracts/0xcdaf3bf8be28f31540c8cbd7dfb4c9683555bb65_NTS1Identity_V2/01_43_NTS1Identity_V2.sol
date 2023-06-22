// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721Enumerable} from "openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721EnumerableUpgradeable} from "openzeppelin-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC721Upgradeable, ERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {UpdatableOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/UpdatableOperatorFiltererUpgradeable.sol";

import {IByteContract} from "bytes/interfaces/IByteContract.sol";

import {NTConfig, NTComponent} from "./NTConfig.sol";

contract NTS1Identity_V2 is
    Initializable,
    UUPSUpgradeable,
    ERC2981Upgradeable,
    ERC721EnumerableUpgradeable,
    UpdatableOperatorFiltererUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint8 constant BOUGHT_IDENTITIES_FLAG = 0x01;

    mapping(address => bool) public admins;
    NTConfig public config;
    uint8 stateFlags;
    uint16 boughtIdentityOffset;
    uint16 currentId;
    uint72 identityCost;

    function initialize(
        uint16 boughtIdentityOffset_,
        address config_,
        address registry,
        address subscriptionOrRegistrantToCopy
    ) external initializer {
        __ERC721_init("Neo Tokyo: Identities V2", "NEOTI");
        __ERC2981_init();
        __ReentrancyGuard_init();
        __UpdatableOperatorFiltererUpgradeable_init(
            registry,
            subscriptionOrRegistrantToCopy,
            true
        );
        __Ownable_init();

        config = NTConfig(config_);
        boughtIdentityOffset = boughtIdentityOffset_;

        identityCost = 2000 ether;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC2981Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function mintIdentity() public nonReentrant {
        require(
            hasFlag(stateFlags, BOUGHT_IDENTITIES_FLAG),
            "Identities cannot be bought yet"
        );
        _chargeBytes(identityCost);
        _safeMint(_msgSender(), ++currentId + boughtIdentityOffset);
    }

    function migrateAsset(address sender, uint256 tokenId) public nonReentrant {
        require(
            _msgSender() == config.migrator(),
            "msg.sender must be migrator"
        );

        NTS1Identity_V2 v1Contract;

        if (tokenId < 2501) {
            v1Contract = NTS1Identity_V2(
                config.findComponent(NTComponent.S1_IDENTITY, false)
            );
        } else {
            v1Contract = NTS1Identity_V2(
                config.findComponent(NTComponent.S1_BOUGHT_IDENTITY, false)
            );
        }

        require(
            v1Contract.ownerOf(tokenId) == sender,
            "You do not own this token"
        );

        v1Contract.transferFrom(sender, address(this), tokenId);
        _safeMint(sender, tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 2000 && tokenId < 2251, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }

    function riddleClaim(
        address _to,
        uint256 tokenId
    ) public nonReentrant onlyOwner {
        require(tokenId > 2250 && tokenId < 2281, "Token ID invalid");
        _safeMint(_to, tokenId);
    }

    function handClaim(
        address _to,
        uint256 tokenId
    ) public nonReentrant onlyOwner {
        require(tokenId > 2280 && tokenId < 2288, "Token ID invalid");
        _safeMint(_to, tokenId);
    }

    function adminClaim(uint256 tokenId, address receiver) public nonReentrant {
        require(admins[msg.sender], "Only admins can adminClaim");
        require(!_exists(tokenId), "Token already exists");
        _safeMint(receiver, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return config.tokenURI(tokenId);
    }

    function getCredits(uint256 tokenId) external view returns (string memory) {
        return config.getCredits(tokenId);
    }

    function getClass(uint256 tokenId) public view returns (string memory) {
        return config.getClass(tokenId);
    }

    function getRace(uint256 tokenId) public view returns (string memory) {
        return config.getRace(tokenId);
    }

    function getStrength(uint256 tokenId) public view returns (string memory) {
        return config.getStrength(tokenId);
    }

    function getIntelligence(
        uint256 tokenId
    ) public view returns (string memory) {
        return config.getIntelligence(tokenId);
    }

    function getAttractiveness(
        uint256 tokenId
    ) public view returns (string memory) {
        return config.getAttractiveness(tokenId);
    }

    function getTechSkill(uint256 tokenId) public view returns (string memory) {
        return config.getTechSkill(tokenId);
    }

    function getCool(uint256 tokenId) public view returns (string memory) {
        return config.getCool(tokenId);
    }

    function getEyes(uint256 tokenId) public view returns (string memory) {
        return config.getEyes(tokenId);
    }

    function getGender(uint256 tokenId) public view returns (string memory) {
        return config.getGender(tokenId);
    }

    function getAbility(uint256 tokenId) public view returns (string memory) {
        return config.getAbility(tokenId);
    }

    function owner()
        public
        view
        override(OwnableUpgradeable, UpdatableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function toggleAdmin(address adminToToggle) public onlyOwner {
        admins[adminToToggle] = !admins[adminToToggle];
    }

    function setConfig(address config_) external onlyOwner {
        config = NTConfig(config_);
    }

    //_newRoyalty is in basis points out of 10,000
    function adjustDefaultRoyalty(
        address _receiver,
        uint96 _newRoyalty
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _newRoyalty);
    }

    //_newRoyalty is in basis points out of 10,000
    function adjustSingleTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _newRoyalty
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _newRoyalty);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setIdentityCost(uint72 _cost) public onlyOwner {
        identityCost = _cost;
    }

    function setBoughtIdentitiesActive() public onlyOwner {
        stateFlags ^= BOUGHT_IDENTITIES_FLAG;
    }

    function hasFlag(uint8 flags, uint8 flag) internal pure returns (bool) {
        return flags & flag != 0;
    }

    function _chargeBytes(uint256 price) private {
        IByteContract bytes_ = IByteContract(NTConfig(config).bytesContract());
        bytes_.burn(_msgSender(), price);
    }
}