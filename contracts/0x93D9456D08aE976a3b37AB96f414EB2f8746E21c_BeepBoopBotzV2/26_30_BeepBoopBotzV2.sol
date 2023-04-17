// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC721AQueryableUpgradeable, ERC721AUpgradeable, IERC721AUpgradeable} from "@erc721a-upgradable/extensions/ERC721AQueryableUpgradeable.sol";
import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC2981Upgradeable} from "@oz-upgradeable/token/common/ERC2981Upgradeable.sol";
import {StringsUpgradeable} from "@oz-upgradeable/utils/StringsUpgradeable.sol";
import {OperatorFilterer} from "@closedsea/OperatorFilterer.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {LibBitmap} from "@solady/utils/LibBitmap.sol";
import {IBeepBoopBotzV2} from "./IBeepBoopBotzV2.sol";
import {IBattleZone} from "../interfaces/IBattleZone.sol";
import {IBeepBoop} from "../interfaces/IBeepBoop.sol";

contract BeepBoopBotzV2 is
    IBeepBoopBotzV2,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721AQueryableUpgradeable,
    ERC2981Upgradeable,
    OperatorFilterer
{
    using StringsUpgradeable for uint256;
    using ECDSA for bytes32;
    using LibBitmap for LibBitmap.Bitmap;

    /// @notice Maximum supply for the NFT
    uint256 public constant MAX_SUPPLY = 10000;

    /// @notice Set base URI
    string private _defaultURI;

    /// @notice BattleZone contract
    address public battleZone;

    /// @notice Build a bot build
    mapping(uint256 => uint256) private _botBuildId;

    /// @notice Signer
    address private _signer;

    /// @notice Set evolved base URI
    string private _evolvedURI;

    /// @notice Legacy bot contract
    address public legacyBotContract;

    /// @notice Invalid builds
    LibBitmap.Bitmap private _invalidBuild;

    /// @notice Boop token
    IBeepBoop public beepBoop;

    /// @notice Paused
    bool public evolvePaused;

    /**
     * @dev Initialize the contract
     */
    function initialize(
        string memory defaultURI,
        address battleZoneContract
    ) public initializerERC721A initializer {
        __ERC721A_init("Beep Boop Botz", "BBB");
        __ERC721AQueryable_init();
        __ERC2981_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setDefaultRoyalty(
            address(0xEE547a830A9a54653de3D40A67bd2BC050DAeD81),
            1000
        );
        _registerForOperatorFiltering();
        setBaseURI(defaultURI);
        setBattleZone(battleZoneContract);
        _mint(address(battleZoneContract), MAX_SUPPLY);
    }

    /**
     * @notice Set battlezone contract
     */
    function setBattleZone(address battleZone_) public onlyOwner {
        battleZone = battleZone_;
    }

    /**
     * @notice Set battlezone contract
     */
    function setBeepBoop(address beepBoop_) public onlyOwner {
        beepBoop = IBeepBoop(beepBoop_);
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Evolve a bot
     */
    function evolve(
        uint256 tokenId,
        uint256 buildId,
        bytes calldata signature
    ) public whenEvolveNotPaused {
        require(_botBuildId[tokenId] < buildId, "Already Evolved");
        bytes32 data = keccak256(
            abi.encodePacked(msg.sender, tokenId, buildId)
        );
        address signer = data.toEthSignedMessageHash().recover(signature);
        require(_signer == signer, "Unauthorized");
        IBattleZone bz = IBattleZone(battleZone);
        require(
            bz.ownerOf(address(this), tokenId) == msg.sender ||
                bz.ownerOf(legacyBotContract, tokenId) == msg.sender,
            "Bot Non-Owner"
        );
        require(bz.powerCoreYield(tokenId) != 0, "Bot Not Charged");
        require(!_invalidBuild.get(buildId), "Invalid Build");
        _invalidBuild.set(buildId);
        _botBuildId[tokenId] = buildId;
        emit Evolve(tokenId, buildId);
        emit MetadataUpdate(tokenId);
    }

    /**
     * @notice Cancel the evolve
     */
    function cancelEvolve(
        uint256 tokenId,
        uint256 buildId,
        bytes calldata signature
    ) public whenEvolveNotPaused {
        require(_botBuildId[tokenId] < buildId, "Already Evolved");
        bytes32 data = keccak256(
            abi.encodePacked(msg.sender, tokenId, buildId)
        );
        address signer = data.toEthSignedMessageHash().recover(signature);
        require(_signer == signer, "Unauthorized");
        require(!_invalidBuild.get(buildId), "Already Canceled");
        _invalidBuild.set(buildId);
        emit CancelEvolve(tokenId, buildId);
    }

    /**
     * @notice Toggle Evolve
     */
    function toggleEvolve() public onlyOwner {
        evolvePaused = !evolvePaused;
    }

    /**
     * @dev When evolving is not paused
     */
    modifier whenEvolveNotPaused() {
        require(!evolvePaused, "Evolve Paused");
        _;
    }

    /**
     * @notice Evolve many bots at once
     */
    function evolveMany(
        uint256[] calldata tokenIds,
        uint256[] calldata buildIds,
        bytes[] calldata signatures
    ) public {
        require(tokenIds.length == buildIds.length);
        require(tokenIds.length == signatures.length);
        for (uint256 i; i < tokenIds.length; ) {
            evolve(tokenIds[i], buildIds[i], signatures[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get evolved build
     */
    function getBotEvolvedBuild(uint256 tokenId) public view returns (uint256) {
        return _botBuildId[tokenId];
    }

    /**
     * @notice Get many evolved builds
     */
    function getBotEvolvedBuilds(
        uint256[] memory tokenIds
    ) public view returns (uint256[] memory) {
        uint256[] memory buildIds = new uint256[](tokenIds.length);
        for (uint256 t; t < tokenIds.length; ++t) {
            buildIds[t] = getBotEvolvedBuild(tokenIds[t]);
        }
        return buildIds;
    }

    /**
     * @notice Update the build
     */
    function updateBuildForBots(
        uint256[] calldata botIds,
        uint256 value
    ) public onlyOwner {
        for (uint256 i; i < botIds.length; ) {
            uint256 botId = botIds[i];
            _botBuildId[botId] = value;
            emit MetadataUpdate(botId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set the signer
     */
    function setSigner(address signer) public onlyOwner {
        _signer = signer;
    }

    /**
     * @notice Pre-approve the battlezone contract to save users fees
     */
    function isApprovedForAll(
        address owner,
        address operator
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        if (operator == address(battleZone)) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function setApprovalForAll(
        address operator,
        bool _approved
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, _approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
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
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
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
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
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
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _defaultURI = uri;
    }

    function setEvolvedURI(string memory uri) public onlyOwner {
        _evolvedURI = uri;
    }

    function setLegacyBotContract(address contract_) public onlyOwner {
        legacyBotContract = contract_;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory uri = _botBuildId[tokenId] != 0
            ? _evolvedURI
            : _defaultURI;
        return
            bytes(uri).length != 0
                ? string(abi.encodePacked(uri, tokenId.toString(), ".json"))
                : "";
    }

    function updateRoyalty(
        address receiver,
        uint96 numerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }
}