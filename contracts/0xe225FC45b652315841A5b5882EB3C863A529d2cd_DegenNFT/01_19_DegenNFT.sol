// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IDegenNFT} from "src/interfaces/nft/IDegenNFT.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import {CommonError} from "src/library/CommonError.sol";

contract DegenNFT is
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    ERC721AUpgradeable,
    IDegenNFT
{
    uint256 public constant PERCENTAGE_BASE = 10000;

    // Mapping from tokenId to Property
    mapping(uint256 => uint256) internal properties;

    // NFTManager
    address public manager;

    string public baseURI;

    // Mapping tokenId to level
    // bucket => value
    mapping(uint256 => uint256) internal levelBucket;

    address _royaltyReceiver; //   ---|
    uint96 _royaltyPercentage; //  ---|

    mapping(uint256 => bool) internal _isSbt;

    uint256[44] private _gap;

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address owner_ // upgrade owner
    ) public initializerERC721A initializer {
        __ERC721A_init(name_, symbol_);
        __Ownable_init_unchained(owner_);
    }

    function mint(address to, uint256 quantity) external onlyManager {
        _mint(to, quantity);
    }

    function burn(uint256 tokenId) external onlyManager {
        _burn(tokenId);
    }

    function setManager(address manager_) external onlyOwner {
        if (manager_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        manager = manager_;

        emit SetManager(manager_);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }

    function setProperties(
        uint256 tokenId,
        Property memory property_
    ) external onlyManager {
        // encode property
        uint16 property = encodeProperty(property_);
        // storage property
        uint256 bucket = (tokenId - 1) >> 4;
        uint256 pos = (tokenId - 1) % 16;
        uint256 mask = uint256(property) << (pos * 16);
        uint256 data = properties[bucket];
        // clear the data on the tokenId pos
        data &= ~(uint256(type(uint16).max) << (pos * 16));
        properties[bucket] = data | mask;

        emit SetProperties(tokenId, property_);
        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev emit ERC4906 event to trigger all metadata update
     */
    function emitMetadataUpdate() external {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function emitMetadataUpdate(uint256 tokenId) external {
        emit MetadataUpdate(tokenId);
    }

    function setBucket(
        uint256 bucket,
        uint256 compactData
    ) external onlyManager {
        properties[bucket] = compactData;
    }

    function setLevel(uint256 tokenId, uint256 level) external onlyManager {
        uint256 bucket = (tokenId - 1) >> 5;
        uint256 pos = (tokenId - 1) % 32;
        uint256 mask = level << (pos * 8);
        uint256 data = levelBucket[bucket];
        // clear the data on the tokenId pos
        data &= ~(uint256(type(uint8).max) << (pos * 8));
        levelBucket[bucket] = data | mask;

        emit LevelSet(tokenId, level);
    }

    /**
     * @dev set royalty info manually
     * @param receiver receiver address
     * @param percent  percent with 10000 percentBase
     */
    function setRoyaltyInfo(
        address receiver,
        uint96 percent
    ) external onlyOwner {
        _royaltyReceiver = receiver;
        _royaltyPercentage = percent;

        emit RoyaltyInfoSet(receiver, percent);
    }

    function setSbt(SbtSetParam[] calldata sbtSetParams) public onlyOwner {
        uint256 length = sbtSetParams.length;
        for (uint256 i = 0; i < length; ) {
            _isSbt[sbtSetParams[i].tokenId] = sbtSetParams[i].isSbt;

            emit SBTSet(sbtSetParams[i].tokenId, sbtSetParams[i].isSbt);

            unchecked {
                i++;
            }
        }
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function encodeProperty(
        Property memory property_
    ) public pure returns (uint16 property) {
        property = (property << 12) | property_.nameId;
        property = (property << 3) | property_.rarity;
        property = (property << 1) | property_.tokenType;
    }

    function decodeProperty(
        uint16 property
    ) public pure returns (uint16 nameId, uint16 rarity, uint16 tokenType) {
        nameId = (property >> 4) & 0x0fff;
        rarity = (property >> 1) & 0x07;
        tokenType = property & 0x01;
    }

    function getProperty(
        uint256 tokenId
    ) external view returns (Property memory) {
        uint256 bucket = (tokenId - 1) >> 4;
        uint256 compactData = properties[bucket];
        uint16 property = uint16(
            (compactData >> (((tokenId - 1) % 16) * 16)) & 0xffff
        );

        (uint16 nameId, uint16 rarity, uint16 tokenType) = decodeProperty(
            property
        );

        return Property({nameId: nameId, rarity: rarity, tokenType: tokenType});
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return string.concat(super.tokenURI(tokenId), ".json");
    }

    /**
     * @dev royalty info
     * @param tokenId NFT tokenId but it's not related with tokenId
     * @param salePrice sale price
     * @return receiver
     * @return royaltyAmount
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyReceiver;
        royaltyAmount =
            (salePrice * uint256(_royaltyPercentage)) /
            PERCENTAGE_BASE;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == 0x2a55205a; // ERC165 interface ID ERC2981  Royalty
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    function getLevel(uint256 tokenId) external view returns (uint256) {
        uint256 bucket = (tokenId - 1) >> 5;
        uint256 compactData = levelBucket[bucket];
        uint256 level = uint8(
            (compactData >> (((tokenId - 1) % 32) * 8)) & 0xff
        );
        return level;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // tokenId start from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev override to disable no-transferable token transfer
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;

        ) {
            if (_isSbt[tokenId]) {
                revert SbtCannotBeTransferred(tokenId);
            }
            unchecked {
                tokenId++;
            }
        }
    }

    function _checkManager() internal view {
        if (msg.sender != manager) {
            revert OnlyManager();
        }
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }
}