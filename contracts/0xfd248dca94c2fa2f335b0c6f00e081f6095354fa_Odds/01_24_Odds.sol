// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";
import {ICantBeEvil} from "@a16z/contracts/licenses/ICantBeEvil.sol";

interface ChromieSquiggle {
    function showTokenHashes(uint256 _tokenId) external view returns (bytes32[] memory);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

interface ITributeStorage {
    function getItem(uint256 id) external view returns (string memory);
}

contract Odds is EIP712, DefaultOperatorFilterer, ERC721Royalty, Ownable, CantBeEvil(LicenseVersion.PUBLIC) {
    error MintingPaused();
    error SupplyReached();
    error ActionAlreadyUsed();
    error BadSignature();
    error SignatureExpired();

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    address immutable _squiggleAddress;
    address immutable _tributeStorageAddress;
    uint256 immutable MAX_SQUIGGLE_ID = 10000;

    bool public mintingPaused = false;
    address public _firstMinter;
    address private _manager;
    address private _verifier;

    string private _liveMetadataPrefix;
    string private _liveImagePrefix;
    bool private _liveChangesLocked = false;

    enum MintKind {
        Owner,
        Custom,
        CustomReserved
    }

    // values below 10k mean that ODDS is based on a squiggle, otherwise it's custom
    mapping(uint256 => bytes32) private _tokenIdToSquiggleData;
    mapping(bytes32 => uint256) private _squiggleDataToTokenId;

    uint256 public _totalExtraSweaters = 0;
    uint256 public _totalMinted = 0;
    uint256 public _totalReserved = 0;

    uint256 public _maxSweaters = 1000; // shared pool
    uint256 public _maxTokens = 900; // pool A
    uint256 public _maxReserved = 100; // pool B

    constructor(
        string memory name,
        string memory symbol,
        address firstMinter,
        address squiggleAddress,
        address tributeStorageAddress
    ) ERC721(name, symbol) EIP712(name, symbol) {
        _setDefaultRoyalty(0xD2C3286e050C8569695f2c7d27E1d770ab42d6c0, 750);
        _firstMinter = firstMinter;
        _squiggleAddress = squiggleAddress;
        _tributeStorageAddress = tributeStorageAddress;
        _manager = msg.sender;
        _verifier = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Royalty, CantBeEvil)
        returns (bool)
    {
        return interfaceId == type(ICantBeEvil).interfaceId || super.supportsInterface(interfaceId);
    }

    //////////////////////////////// Royalty overrides

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //////////////////////////////// Limits and other manager functions

    function setLimits(uint256 maxSweaters, uint256 maxTokens, uint256 maxReserved) external onlyOwner {
        _maxSweaters = maxSweaters;
        _maxTokens = maxTokens;
        _maxReserved = maxReserved;
    }

    function setFirstMinter(address firstMinter) external onlyOwner {
        if (_totalMinted > 0) {
            revert();
        }
        _firstMinter = firstMinter;
    }

    function setOperators(address manager, address verifier) external onlyOwner {
        _manager = manager;
        _verifier = verifier;
    }

    function setMintingPaused(bool value) external onlyManager {
        mintingPaused = value;
    }

    function lockLivePrefixes() external onlyOwner {
        _liveChangesLocked = true;
    }

    function setLivePrefixes(string memory liveMetadataPrefix, string memory liveImagePrefix) external onlyOwner {
        if (_liveChangesLocked) {
            revert();
        }

        _liveMetadataPrefix = liveMetadataPrefix;
        _liveImagePrefix = liveImagePrefix;

        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    function setExtraClaimed(uint256 value) external onlyManager {
        _totalExtraSweaters = value;
    }

    //////////////////////////////// Minting function
    function signedMint(address to, uint8 mintKind, bytes32 squiggleData, uint256 expiresAt, bytes calldata signature)
        external
        payable
        verifySignature(mintKind, squiggleData, expiresAt, signature)
    {
        if (mintingPaused || (msg.sender != _firstMinter && _totalMinted == 0)) {
            revert MintingPaused();
        }

        if (_squiggleDataToTokenId[squiggleData] > 0) revert ActionAlreadyUsed();
        uint256 tokenId = 1 + _totalMinted + _totalReserved;

        _tokenIdToSquiggleData[tokenId] = squiggleData;
        _squiggleDataToTokenId[squiggleData] = tokenId;

        if (_totalMinted + _totalReserved >= totalSupply()) revert SupplyReached();

        if (mintKind == uint8(MintKind.CustomReserved)) {
            if (_totalReserved >= _maxReserved) revert SupplyReached();
            _totalReserved += 1;
        } else {
            if (_totalMinted >= _maxTokens) revert SupplyReached();
            _totalMinted += 1;
        }

        super._mint(to, tokenId);
    }

    bytes32 public constant SIGNED_ACTION_TYPEHASH =
        keccak256("SignedAction(uint8 mintKind,bytes32 squiggleData,uint256 expiresAt,uint256 price)");

    modifier verifySignature(uint8 mintKind, bytes32 squiggleData, uint256 expiresAt, bytes calldata signature) {
        if (block.timestamp > expiresAt) revert SignatureExpired();

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(SIGNED_ACTION_TYPEHASH, mintKind, squiggleData, expiresAt, msg.value))
        );

        if (_verifier != ECDSA.recover(digest, signature)) {
            revert BadSignature();
        }

        _;
    }

    ////////////////////////////////
    modifier onlyManager() {
        require(msg.sender == _manager, "caller is not the manager");
        _;
    }

    function contractURI() external pure returns (string memory) {
        bytes memory dataURI = '{"name": "ODDS",'
            '"description": "ODDS by Tribute Brand X Chromie Squiggle X Waste Yarn Project",'
            '"seller_fee_basis_points": 750,' '"fee_recipient": "0xD2C3286e050C8569695f2c7d27E1d770ab42d6c0",'
            '"external_link": "https://tribute-brand.com"' "}";

        return string(abi.encodePacked("data:application/json;charset=utf-8,", dataURI));
    }

    function _publicRemaining() external view virtual returns (uint256) {
        return _maxSweaters - _totalMinted - _totalReserved - _totalExtraSweaters;
    }

    function _reservedRemaining() internal view virtual returns (uint256) {
        return _maxReserved - _totalReserved;
    }

    function _reservedSupply() internal view virtual returns (uint256) {
        return _maxReserved;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _maxSweaters - _totalExtraSweaters;
    }

    function tokenHashUsed(bytes32 tokenHash) external view virtual returns (bool) {
        return _squiggleDataToTokenId[tokenHash] > 0;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory result) {
        if (!_exists(tokenId)) {
            revert();
        }

        bytes32 squiggleData = _tokenIdToSquiggleData[tokenId];

        if (bytes(_liveMetadataPrefix).length > 0) {
            return string.concat(_liveMetadataPrefix, Strings.toString(tokenId), ".json");
        }

        string memory nameSuffix = "";
        string memory renderInfix = "";

        bool is_original = uint256(squiggleData) < MAX_SQUIGGLE_ID;

        if (is_original) {
            nameSuffix = string.concat("[CHROMIE SQUIGGLE #", Strings.toString(uint256(squiggleData)), "]");
            bytes32 _tokenHash = ChromieSquiggle(_squiggleAddress).showTokenHashes(uint256(squiggleData))[0];

            renderInfix = string.concat(
                Strings.toHexString(uint256(_tokenHash), 32),
                "'; let tokenId = ",
                Strings.toString(uint256(squiggleData))
            );

            squiggleData = _tokenHash;
        } else {
            nameSuffix = string.concat("[#", Strings.toString(tokenId), "]");
            renderInfix = string.concat(Strings.toHexString(uint256(squiggleData), 32), "'; let tokenId = -1");
        }

        // traits
        bool reverse = uint8(squiggleData[30]) < 128;
        bool slinky = uint8(squiggleData[31]) < 35;
        bool pipe = uint8(squiggleData[22]) < 32;
        bool bold = uint8(squiggleData[23]) < 15;
        bool ribbed = uint8(squiggleData[24]) < 30;
        bool fuzzy = pipe && !slinky;

        string memory _type;
        string memory _upperType;

        if (fuzzy) {
            _type = "Fuzzy";
            _upperType = "FUZZY";
        } else if (pipe) {
            _type = "Pipe";
            _upperType = "PIPE";
        } else if (slinky) {
            _type = "Slinky";
            _upperType = "SLINKY";
        } else if (bold) {
            _type = "Bold";
            _upperType = "BOLD";
        } else if (ribbed) {
            _type = "Ribbed";
            _upperType = "RIBBED";
        } else {
            _type = "Normal";
            _upperType = "NORMAL";
        }

        uint8 startColor = uint8(squiggleData[29]);
        uint256 segments = 12 + 8 * uint256(uint8(squiggleData[26])) / 255;
        uint256 steps = slinky ? 50 : (fuzzy ? 1000 : 200);
        uint256 spread = uint8(squiggleData[28]) < 3 ? 1 : 5 + 45 * uint256(uint8(squiggleData[28])) / 255;

        string memory _spectrum = "Normal";

        // Full Spectrum: steps = 200 AND spread: 14 or 15 AND segments: 18 or 19
        // Perfect Spectrum: steps = 200 AND spread: 11 AND segments: 14
        // Hyper: spread = 0.5
        // Normal: other combinations

        if (spread == 1) {
            _spectrum = "HyperRainbow";
        } else if (steps == 200 && spread == 11 && segments == 14) {
            _spectrum = "Perfect Spectrum";
        } else if (steps == 200 && ((spread == 14 && segments == 18) || (spread == 15 && segments == 19))) {
            _spectrum = "Full Spectrum";
        }

        string memory animationBase64 = Base64.encode(
            abi.encodePacked(
                "<html><head><meta charset='utf-8'/><script>let tokenHash = '",
                renderInfix,
                ";</script></head>",
                ITributeStorage(_tributeStorageAddress).getItem(1)
            )
        );

        string memory imageTrait = "";

        if (bytes(_liveImagePrefix).length > 0) {
            imageTrait = string.concat('"image": "', _liveImagePrefix, Strings.toString(tokenId), '.png",');
        }

        return string.concat(
            "data:application/json;charset=utf-8," '{"name":"',
            _upperType,
            " ODD ",
            nameSuffix,
            '", "token_hash": "',
            Strings.toHexString(uint256(squiggleData), 32),
            '", "description": "ODDS by Tribute Brand X Chromie Squiggle X Waste Yarn Project", "external_link":"https://tribute-brand.com/", "attributes": ['
            '{"trait_type": "ODD Type", "value": "',
            is_original ? "Original" : "Generated",
            '"}, {"trait_type": "Color Direction", "value": "',
            reverse ? "Reverse" : "Forward",
            '"}, {"trait_type": "Color Spread", "value": "',
            spread == 1 ? "0.5" : Strings.toString(spread),
            '"}, {"trait_type": "Spectrum", "value": "',
            _spectrum,
            '"}, {"trait_type": "Steps Between", "value": "',
            Strings.toString(steps),
            '"}, {"trait_type": "Type", "value": "',
            _type,
            '"}, {"trait_type": "Start Color", "display_type": "Level", "max_value": 255, "value": ',
            Strings.toString(startColor),
            '}, {"trait_type": "Segments", "display_type": "Level", "max_value": 20, "value": ',
            Strings.toString(segments),
            "}],",
            imageTrait,
            '"animation_url": "data:text/html;charset=utf-8;base64,',
            animationBase64,
            '"}'
        );
    }

    function withdraw(address _receiver) public onlyOwner {
        (bool os,) = payable(_receiver).call{value: address(this).balance}("");
        require(os, "Withdraw unsuccesful");
    }
}