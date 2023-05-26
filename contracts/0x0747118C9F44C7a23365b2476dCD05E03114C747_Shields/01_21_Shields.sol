// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './interfaces/ICategories.sol';
import './interfaces/IShields.sol';
import './interfaces/IEmblemWeaver.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract Shields is ERC721, IShields, Ownable {
    event ShieldBuilt(
        uint256 tokenId,
        uint16 field,
        uint16 hardware,
        uint16 frame,
        uint24[4] colors,
        ShieldBadge shieldBadge
    );

    IEmblemWeaver public immutable emblemWeaver;

    uint256 constant makerBadgeThreshold = 5;

    uint256 constant makerPremintThreshold = 100;
    uint256 constant granteePremintThreshold = 500;
    uint256 constant standardMintMax = 5000;
    uint256 constant individualMintMax = 5;

    uint256 constant makerReservedHardware = 120;

    uint256 public constant mythicFee = 0.02 ether;
    uint256 public constant specialFee = 0.08 ether;

    bool public publicMintActive = false;
    uint256 public publicMintPrice;

    uint256 internal _nextId;

    mapping(uint256 => Shield) private _shields;
    // transient variable that's immediately cleared after checking for duplicate colors
    mapping(uint24 => bool) private _checkDuplicateColors;
    // record shieldHashes so that duplicate shields cannot be built
    mapping(bytes32 => bool) public shieldHashes;


    modifier publicMintPriceSet() {
        require(publicMintPrice > 0, 'Shields: public mint price not yet set');
        _;
    }

    modifier publicMintIsActive() {
        require(publicMintActive, 'Shields: public mint not active yet');
        _;
    }

    modifier publicMintIsNotActive() {
        require(!publicMintActive, 'Shields: public mint is already active');
        _;
    }

    modifier validMintCount(uint8 count) {
        require(_nextId + count <= standardMintMax + 1, 'Shields: public mint max exceeded');
        require(count <= individualMintMax, 'Shields: can only mint up to 5 per transaction');
        _;
    }

    modifier publicMintPaid(uint8 count) {
        require(msg.value == publicMintPrice * count, 'Shields: invalid mint fee');
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == ERC721.ownerOf(tokenId), 'Shields: only owner can build Shield');
        _;
    }

    modifier shieldNotBuilt(uint256 tokenId) {
        require(!_shields[tokenId].built, 'Shields: Shield already built');
        _;
    }

    modifier validHardware(uint256 tokenId, uint16 hardware) {
        if (hardware == makerReservedHardware) {
            require(tokenId <= makerBadgeThreshold, 'Shields: Three Shields hardware reserved for Maker Badge');
        }
        _;
    }

    modifier validColors(uint16 field, uint24[4] memory colors) {
        validateColors(colors, field);
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        IEmblemWeaver _emblemWeaver,
        address makerBadgeRecipient,
        address granteeBadgeRecipient
    ) ERC721(name_, symbol_) Ownable() {
        emblemWeaver = _emblemWeaver;

        for (uint256 i = 1; i <= makerPremintThreshold; i++) {
            _mint(makerBadgeRecipient, i);
        }

        for (uint256 j = makerPremintThreshold + 1; j <= granteePremintThreshold; j++) {
            _mint(granteeBadgeRecipient, j);
        }

        _nextId = granteePremintThreshold + 1;
    }

    // ============ OWNER INTERFACE ============

    function collectFees() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}(new bytes(0));
        require(success, 'Shields: ether transfer failed');
    }

    function setPublicMintActive() external onlyOwner publicMintPriceSet {
        publicMintActive = true;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner publicMintIsNotActive {
      publicMintPrice = _publicMintPrice;
    }

    // ============ PUBLIC INTERFACE ============

    function mint(address to, uint8 count)
        external
        payable
        publicMintIsActive
        validMintCount(count)
        publicMintPaid(count)
    {
        for (uint8 i = 0; i < count; i++) {
            _mint(to, _nextId++);
        }
    }

    function build(
        uint16 field,
        uint16 hardware,
        uint16 frame,
        uint24[4] memory colors,
        uint256 tokenId
    )
        external
        payable
        override
        onlyTokenOwner(tokenId)
        shieldNotBuilt(tokenId)
        validHardware(tokenId, hardware)
        validColors(field, colors)
    {
        // shield must be unique
        bytes32 shieldHash = keccak256(abi.encode(field, hardware, colors));
        require(!shieldHashes[shieldHash], 'Shields: unique Shield already built');
        shieldHashes[shieldHash] = true;

        // Construct Shield
        Shield memory shield = Shield({
            built: true,
            field: field,
            hardware: hardware,
            frame: frame,
            colors: colors,
            shieldBadge: calculateShieldBadge(tokenId)
        });
        _shields[tokenId] = shield;

        // Calculate Fee
        {
            uint256 fee;
            ICategories.FieldCategories fieldType = emblemWeaver
                .fieldGenerator()
                .generateField(shield.field, shield.colors)
                .fieldType;
            ICategories.HardwareCategories hardwareType = emblemWeaver
                .hardwareGenerator()
                .generateHardware(shield.hardware)
                .hardwareType;
            uint256 frameFee = emblemWeaver.frameGenerator().generateFrame(shield.frame).fee;
            if (fieldType == ICategories.FieldCategories.MYTHIC) {
                fee += mythicFee;
            }
            if (hardwareType == ICategories.HardwareCategories.SPECIAL) {
                fee += specialFee;
            }
            fee += frameFee;
            require(msg.value == fee, 'Shields: invalid building fee');
        }

        emit ShieldBuilt(tokenId, field, hardware, frame, colors, calculateShieldBadge(tokenId));
    }

    // ============ PUBLIC VIEW FUNCTIONS ============

    function totalSupply() public view returns (uint256) {
        return _nextId - 1;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Shields: URI query for nonexistent token');
        Shield memory shield = _shields[tokenId];

        if (!shield.built) {
            return emblemWeaver.generateShieldBadgeURI(calculateShieldBadge(tokenId));
        } else {
            return emblemWeaver.generateShieldURI(shield);
        }
    }

    function shields(uint256 tokenId)
        external
        view
        override
        returns (
            uint16 field,
            uint16 hardware,
            uint16 frame,
            uint24 color1,
            uint24 color2,
            uint24 color3,
            uint24 color4,
            ShieldBadge shieldBadge
        )
    {
        require(_exists(tokenId), 'Shield: tokenID does not exist');
        Shield memory shield = _shields[tokenId];
        return (
            shield.field,
            shield.hardware,
            shield.frame,
            shield.colors[0],
            shield.colors[1],
            shield.colors[2],
            shield.colors[3],
            shield.shieldBadge
        );
    }

    // ============ INTERNAL INTERFACE ============

    function calculateShieldBadge(uint256 tokenId) internal pure returns (ShieldBadge) {
        if (tokenId <= makerBadgeThreshold) {
            return ShieldBadge.MAKER;
        } else {
            return ShieldBadge.STANDARD;
        }
    }

    function validateColors(uint24[4] memory colors, uint16 field) internal {
        if (field == 0) {
            checkExistsDupsMax(colors, 1);
        } else if (field <= 242) {
            checkExistsDupsMax(colors, 2);
        } else if (field <= 293) {
            checkExistsDupsMax(colors, 3);
        } else {
            checkExistsDupsMax(colors, 4);
        }
    }

    function checkExistsDupsMax(uint24[4] memory colors, uint8 nColors) private {
        for (uint8 i = 0; i < nColors; i++) {
            require(_checkDuplicateColors[colors[i]] == false, 'Shields: all colors must be unique');
            require(emblemWeaver.fieldGenerator().colorExists(colors[i]), 'Shields: color does not exist');
            _checkDuplicateColors[colors[i]] = true;
        }
        for (uint8 i = 0; i < nColors; i++) {
            _checkDuplicateColors[colors[i]] = false;
        }
        for (uint8 i = nColors; i < 4; i++) {
            require(colors[i] == 0, 'Shields: max colors exceeded for field');
        }
    }
}