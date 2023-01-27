// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// Interfaces =====================================================================================
import {IERC20Upgradeable} from "openzeppelin/token/ERC20/IERC20Upgradeable.sol";
import {IERC165Upgradeable} from "openzeppelin/interfaces/IERC165Upgradeable.sol";
import {IERC2981Upgradeable} from "openzeppelin/interfaces/IERC2981Upgradeable.sol";

/// Libraries ======================================================================================
import {MerkleProofUpgradeable} from "openzeppelin/utils/cryptography/MerkleProofUpgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {StringsUpgradeable} from "openzeppelin/utils/StringsUpgradeable.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// Types ==========================================================================================
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";

import {OwnableUpgradeable} from "openzeppelin/access/OwnableUpgradeable.sol";
import {ERC721EnumerableUpgradeable} from "openzeppelin/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin/security/ReentrancyGuardUpgradeable.sol";

/// Storage ==========================================================================================
import {
    TexturePunxCoreStorage,
    TexturePunxPaymentStorage,
    TexturePunxTraitStorage,
    TexturePunxMintingStorage
} from "src/TexturePunxStorage.sol";

/// Errors ===========================================================================================
import {TexturePunxErrors} from "src/TexturePunxErrors.sol";

contract TexturePunx is 
    OwnableUpgradeable, 
    ERC721EnumerableUpgradeable, 
    IERC2981Upgradeable, 
    ReentrancyGuardUpgradeable {
    /// Dependencies ===================================================================================

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using FixedPointMathLib for uint256;
    using StringsUpgradeable for uint256;

    /// Constants ======================================================================================

    uint64 public constant MAX_SUPPLY = 10_000;

    uint64 public constant PUNX_BASE_PRICE = 0.10 ether;
    uint64 public constant PUNX_PREMIUM_PRICE = 0.05 ether;
    uint64 public constant PUNX_LIMITED_PRICE = 0.10 ether;
    uint64 public constant PUNX_LIMITED_COUNT = 500;

    string private constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" width="700" height="700" viewBox="0 -0.5 24 24" shape-rendering="crispEdges">';
    string private constant svgEnd = '</svg>';
    
    /// MODIFIERS ======================================================================================

    modifier tokenExists(uint256 tokenId_) {
        if (!_exists(tokenId_))
            revert TexturePunxErrors.TokenDoesNotExist();
        _;
    }

    modifier validMint(bytes32 dna_) {
        _;
        if (totalSupply() >= MAX_SUPPLY - TexturePunxMintingStorage.layout().reservedSupply)
            revert TexturePunxErrors.QuantityExceedsMaxSupply();
        _validateAndRegisterSerialization(dna_);
    }

    modifier validWhitelistMint(uint64 mintRound_, bytes32 dna_, bytes32[] calldata merkleProof_) {
        TexturePunxMintingStorage.WhitelistRound memory round_ = TexturePunxMintingStorage.layout().round[mintRound_];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProofUpgradeable.verify(merkleProof_, round_.merkelRoot, leaf))
            revert TexturePunxErrors.NotOnWhitelist();
        if (TexturePunxMintingStorage.layout().mintRound[mintRound_][msg.sender] >= round_.mintAllowance)
            revert TexturePunxErrors.AlreadyMinted();
        if (msg.value < whitelistPrice(mintRound_, dna_))
            revert TexturePunxErrors.NotEnoughETH();

        // Log Mint
        TexturePunxMintingStorage.layout().mintRound[mintRound_][msg.sender] += 1;

        _;
    }

    /// Initializer ====================================================================================

    function __initialize_texturePunx_v1(
        address controller_, 
        address payable mintForwarder_, 
        address payable royaltyForwarder_
    ) external initializer {

        // Initialize all dependencies
        __Ownable_init();
        __ReentrancyGuard_init();

        // Initialize the base nft contract
        __ERC721_init("Texture Punx", "PUNX");

        // Initialze the nft enumerability 
        __ERC721Enumerable_init();


        // Initialize storage dependencies
        TexturePunxCoreStorage.init();
        TexturePunxMintingStorage.init();

        // Set payment information
        TexturePunxPaymentStorage.layout().mintForwarder = mintForwarder_;
        TexturePunxPaymentStorage.layout().royaltyForwarder = royaltyForwarder_;

        // Transfer ownership to controller
        transferOwnership(controller_);
    }

    receive() payable external {}

    /// Public Accessor Functions ======================================================================

    function DESCRIPTION() external view returns (string memory) {
        return TexturePunxCoreStorage.layout().DESCRIPTION;
    }

    function isPublicSaleActive() external view returns (bool) {
        return TexturePunxMintingStorage.layout().isPublicSaleActive;
    }
    
    function round(uint64 index_) external view returns (TexturePunxMintingStorage.WhitelistRound memory) {
        if (index_ >= TexturePunxMintingStorage.layout().nextRound) revert TexturePunxErrors.IndexOutOfBounds();
        return TexturePunxMintingStorage.layout().round[index_];
    }
    
    function currentRound() external view returns (uint64) {
        return TexturePunxMintingStorage.layout().nextRound - 1;
    }
    
    function mintRound(uint64 _round, address _address) external view returns (uint64) {
        return TexturePunxMintingStorage.layout().mintRound[_round][_address];
    }

    /// Mint Functions =================================================================================

    function publicMint(bytes32 dna_)
    external payable
    validMint(dna_)
    nonReentrant
    {
        if (!TexturePunxMintingStorage.layout().isPublicSaleActive)
            revert TexturePunxErrors.PublicSaleNotActive();
        if (msg.value < _calculatePrice(dna_))
            revert TexturePunxErrors.NotEnoughETH();

        // Mint NFT
        _safeMint(msg.sender, totalSupply());
    }

    function whitelistMint(uint64 mintRound_, bytes32 dna_, bytes32[] calldata merkleProof_) 
    external payable
    validMint(dna_) 
    validWhitelistMint(mintRound_, dna_, merkleProof_)
    nonReentrant
    {
        if (mintRound_ == 0) revert TexturePunxErrors.InvalidMintRound();
        
        // Mint NFT
        _safeMint(msg.sender, totalSupply());
    }

    function ethCoreDevMint(bytes32 dna_, bytes32[] calldata merkleProof_) 
    external payable
    validMint(dna_) 
    validWhitelistMint(0, dna_, merkleProof_)
    nonReentrant
    {
        if (TexturePunxMintingStorage.layout().reservedSupply == 0)
            revert TexturePunxErrors.QuantityExceedsReservedSupply();

        // Decrement reserved suppy count
        TexturePunxMintingStorage.layout().reservedSupply -= 1;

        // Mint NFT
        _safeMint(msg.sender, totalSupply());
    }

    function mintPromotional(address receiver_, bytes32 dna_)
    external onlyOwner
    validMint(dna_) 
    {
        // Mint NFT
        _safeMint(receiver_, totalSupply());
    }

    function mintReserved(address receiver_, bytes32 dna_)
    external onlyOwner
    validMint(dna_) 
    {
        if (TexturePunxMintingStorage.layout().reservedSupply == 0)
            revert TexturePunxErrors.QuantityExceedsReservedSupply();

        // Decrement reserved suppy count
        TexturePunxMintingStorage.layout().reservedSupply -= 1;

        // Mint NFT
        _safeMint(receiver_, totalSupply());
    }

    function isTraitAvailable(uint8 categoryIndex_, uint8 traitIndex_) external view returns (bool) {
        TexturePunxTraitStorage.TraitDescription storage ts = TexturePunxTraitStorage.layout().traits[categoryIndex_][traitIndex_];
        return (ts.rarity == TexturePunxTraitStorage.TraitRarity.LIMITED) ? ts.uses <= PUNX_LIMITED_COUNT : true;
    }

    function isUniqueSerialization(bytes32 dna_) external view returns (bool) {
        // Make sure non trait indexes are zero
        for (uint8 categoryIndex_ = TexturePunxTraitStorage.layout().categoryCount; categoryIndex_ < 32; categoryIndex_ += 1) {
            if (dna_[categoryIndex_] != 0x0)
                revert TexturePunxErrors.InvalidSerialization_SpecifiedValueForInvalidParams();
        }

        // Make sure it is unique
        if (TexturePunxCoreStorage.layout().registeredPunx[dna_]) 
            revert TexturePunxErrors.InvalidSerialization_NotUnique();
        
        // Check each trait
        for (uint8 categoryIndex_ = 0; categoryIndex_ < TexturePunxTraitStorage.layout().categoryCount; categoryIndex_ += 1) {
            uint8 traitIndex_ = uint8(dna_[categoryIndex_]);
            if (traitIndex_ >= TexturePunxTraitStorage.layout().traitCount[categoryIndex_]) 
                revert TexturePunxErrors.InvalidSerialization_UndefinedTrait(categoryIndex_);

            TexturePunxTraitStorage.TraitDescription storage ts = TexturePunxTraitStorage.layout().traits[categoryIndex_][traitIndex_];
            if (ts.rarity == TexturePunxTraitStorage.TraitRarity.LIMITED) {
                if (ts.uses > PUNX_LIMITED_COUNT)
                    revert TexturePunxErrors.InvalidSerialization_TraitExceedsMaxUses(categoryIndex_, traitIndex_);
            } 
        }
        return true;
    }

    function mintPrice(bytes32 dna_) external view returns (uint256 price_) {
        return _calculatePrice(dna_);
    }

    function whitelistRound() external view returns (uint64 roundNumber_) {
        return TexturePunxMintingStorage.layout().nextRound - 1;
    }

    function whitelistPrice(uint64 mintRound_, bytes32 dna_) public view returns (uint256 price_) {
        TexturePunxMintingStorage.WhitelistRoundPricing _price = TexturePunxMintingStorage.layout().round[mintRound_].price;
        if (_price == TexturePunxMintingStorage.WhitelistRoundPricing.FREE) {
            return 0;
        } 
        
        if (_price == TexturePunxMintingStorage.WhitelistRoundPricing.VIP) {
            price_ = _calculatePrice(dna_);
            price_ -= PUNX_BASE_PRICE;
            return price_;
        } 
        
        return _calculatePrice(dna_);
    }

    function _validateAndRegisterSerialization(bytes32 dna_) internal {
        // Make sure non trait indexes are zero
        for (uint8 categoryIndex_ = TexturePunxTraitStorage.layout().categoryCount; categoryIndex_ < 32; categoryIndex_ += 1) {
            if (dna_[categoryIndex_] != 0x0)
                revert TexturePunxErrors.InvalidSerialization_SpecifiedValueForInvalidParams();
        }

        // Make sure it is unique
        if (TexturePunxCoreStorage.layout().registeredPunx[dna_]) 
            revert TexturePunxErrors.InvalidSerialization_NotUnique();
        
        // Check each trait
        for (uint8 categoryIndex_ = 0; categoryIndex_ < TexturePunxTraitStorage.layout().categoryCount; categoryIndex_ += 1) {
            uint8 traitIndex_ = uint8(dna_[categoryIndex_]);
            if (traitIndex_ >= TexturePunxTraitStorage.layout().traitCount[categoryIndex_]) 
                revert TexturePunxErrors.InvalidSerialization_UndefinedTrait(categoryIndex_);

            TexturePunxTraitStorage.TraitDescription storage ts = TexturePunxTraitStorage.layout().traits[categoryIndex_][traitIndex_];
            if (ts.rarity == TexturePunxTraitStorage.TraitRarity.LIMITED) {
                if (ts.uses > PUNX_LIMITED_COUNT)
                    revert TexturePunxErrors.InvalidSerialization_TraitExceedsMaxUses(categoryIndex_, traitIndex_);
                ts.uses += 1;
            } 
        }

        // Log punx
        TexturePunxCoreStorage.layout().serializedPunx[totalSupply() - 1] = dna_;
        TexturePunxCoreStorage.layout().registeredPunx[dna_] = true;
    }

    function _calculatePrice(bytes32 dna_) internal view returns (uint256 price_) {
        // Initialize price to base
        price_ = PUNX_BASE_PRICE;

        // Three free premium 
        uint8 _premiumCount = 4;

        // Add the price for each
        for (uint8 categoryIndex_ = 0; categoryIndex_ < TexturePunxTraitStorage.layout().categoryCount; categoryIndex_ += 1) {
            uint8 traitIndex_ = uint8(dna_[categoryIndex_]);
            if (traitIndex_ >= TexturePunxTraitStorage.layout().traitCount[categoryIndex_]) continue;

            TexturePunxTraitStorage.TraitRarity rarity_ = TexturePunxTraitStorage.layout().traits[categoryIndex_][traitIndex_].rarity;
            price_ += (rarity_ == TexturePunxTraitStorage.TraitRarity.BASIC) 
                ? 0 
                : (rarity_ == TexturePunxTraitStorage.TraitRarity.PREMIUM) 
                    ? (
                        ((_premiumCount > 0 ? (_premiumCount -= 1) : 0) > 0) 
                            ? 0 
                            : PUNX_PREMIUM_PRICE
                    )
                    : PUNX_LIMITED_PRICE;
        }
        return price_;
    }

    /* ========== FUNCTION ========== */

    function setIsPublicSaleActive(bool isPublicSaleActive_) external onlyOwner {
        TexturePunxMintingStorage.layout().isPublicSaleActive = isPublicSaleActive_;
    }

    function setReservedSupply(uint64 reservedSupply_) external onlyOwner {
        TexturePunxMintingStorage.layout().reservedSupply = reservedSupply_;
    }

    function incrementWhitelistRound(
        bytes32 newRoot_, 
        uint64 mintAllowance_, 
        TexturePunxMintingStorage.WhitelistRoundPricing mintPrice_
    ) external onlyOwner {
        uint64 index = (TexturePunxMintingStorage.layout().nextRound += 1) - 1;

        TexturePunxMintingStorage.layout().round[index].merkelRoot = newRoot_;

        TexturePunxMintingStorage.layout().round[index].mintAllowance = mintAllowance_;
        TexturePunxMintingStorage.layout().round[index].price = mintPrice_;

        TexturePunxMintingStorage.layout().round[index].mintRound = index;
    }

    function mintsAvailable(uint64 mintRound_) view external returns (uint64) {
        if (mintRound_ >= TexturePunxMintingStorage.layout().nextRound) revert TexturePunxErrors.IndexOutOfBounds();
        return TexturePunxMintingStorage.layout().round[mintRound_].mintAllowance - TexturePunxMintingStorage.layout().mintRound[mintRound_][msg.sender];
    }

    /// Trait initialization functions =================================================================

    function setDescription(string memory description_) external onlyOwner {
        TexturePunxCoreStorage.layout().DESCRIPTION = description_;
    }

    function setCategory(uint8 categoryIndex_, string memory name_, bool required_) external onlyOwner {
        if (categoryIndex_ >  TexturePunxTraitStorage.layout().categoryCount) revert TexturePunxErrors.InvalidCategoryIndex();
        if (categoryIndex_ == TexturePunxTraitStorage.layout().categoryCount) {
            TexturePunxTraitStorage.layout().categoryCount += 1;
            TexturePunxTraitStorage.layout().traitCount.push(0);
        }
        TexturePunxTraitStorage.layout().categories[categoryIndex_] = TexturePunxTraitStorage.TraitCategory(
            {
                name: name_,
                required: required_
            }
        );
    }

    function setTraitDescription(uint8 categoryIndex_, uint8 traitIndex_, string memory name_, TexturePunxTraitStorage.TraitRarity rarity_) external onlyOwner {
        if (categoryIndex_ >= TexturePunxTraitStorage.layout().categoryCount) revert TexturePunxErrors.InvalidCategoryIndex();

        if (traitIndex_ >  TexturePunxTraitStorage.layout().traitCount[categoryIndex_]) revert TexturePunxErrors.InvalidTraitIndex();
        if (traitIndex_ == TexturePunxTraitStorage.layout().traitCount[categoryIndex_]) TexturePunxTraitStorage.layout().traitCount[categoryIndex_] += 1;
        TexturePunxTraitStorage.layout().traits[categoryIndex_][traitIndex_] = TexturePunxTraitStorage.TraitDescription(
            {
                name: name_,
                rarity: rarity_,
                uses: 0
            }
        );
    }

    function setTraitSVG(uint8 categoryIndex_, uint8 traitIndex_, bytes calldata svg_) external onlyOwner {
        if (categoryIndex_ >= TexturePunxTraitStorage.layout().categoryCount) revert TexturePunxErrors.InvalidCategoryIndex();
        if (traitIndex_ >= TexturePunxTraitStorage.layout().traitCount[categoryIndex_]) revert TexturePunxErrors.InvalidTraitIndex();        

        TexturePunxTraitStorage.layout().svgs[
            _hashTraitName(
                TexturePunxTraitStorage.layout().categories[categoryIndex_].name, 
                TexturePunxTraitStorage.layout().traits[categoryIndex_][traitIndex_].name
            )
        ] = svg_;
    }

    function setBackgroundSVG(bytes calldata svg_) external onlyOwner {
        TexturePunxTraitStorage.layout().background = svg_;
    }

    /// Internal render functions ======================================================================

    function _build(uint256 tokenId_) internal view returns (string memory properties, string memory svg) {
        // Grab the trait / dna for the punx
        bytes32 dna_ = TexturePunxCoreStorage.layout().serializedPunx[tokenId_];

        return (
            _properties(dna_), 
            _render(dna_)
        );
    }
    
    function _render(bytes32 dna_) public view returns (string memory svg) {
        bytes memory resp = abi.encodePacked(svgStart);
        resp = bytes.concat(resp, TexturePunxTraitStorage.layout().background);

        for (uint8 categoryIndex_ = 0; categoryIndex_ < TexturePunxTraitStorage.layout().categoryCount; categoryIndex_ += 1) {
            if (dna_[categoryIndex_] == 0x00 && !TexturePunxTraitStorage.layout().categories[categoryIndex_].required) continue;
            resp = bytes.concat(
                resp, 
                abi.encodePacked(
                    getTraitSVG(categoryIndex_, uint8(dna_[categoryIndex_]))
                )
            );       
        }

        return string(
            bytes.concat(
                resp, 
                abi.encodePacked(svgEnd)
            )
        );
    }
    
    function _properties(bytes32 dna_) internal view returns (string memory properties) {
        bytes memory resp;

        for (uint8 categoryIndex_ = 0; categoryIndex_ < TexturePunxTraitStorage.layout().categoryCount; categoryIndex_ += 1) {
            if (uint8(dna_[categoryIndex_]) == 0 && !TexturePunxTraitStorage.layout().categories[categoryIndex_].required) continue;
            resp = bytes.concat(
                resp, 
                abi.encodePacked(
                    _packProperty(
                        TexturePunxTraitStorage.layout().categories[categoryIndex_].name, 
                        TexturePunxTraitStorage.layout().traits[categoryIndex_][uint8(dna_[categoryIndex_])].name, 
                        categoryIndex_ == 0 // TexturePunxTraitStorage.layout().categoryCount - 1
                    )
                )
            );       
        }

        return string(resp);
    }
            
    function _packProperty(string memory name_, string memory trait_, bool first_) public pure returns (string memory svg) {
        string memory comma_ = ","; 
        if (first_) {
            comma_ = ""; 
        }
        return string(
            abi.encodePacked(
                comma_,
                '{"trait_type":"',
                name_,
                '","value":"',
                trait_,
                '"}'
            )
        );
    }

    /// Trait accessor functions =======================================================================

    function getDNA(uint256 tokenId_) external view returns (bytes32) {
        return TexturePunxCoreStorage.layout().serializedPunx[tokenId_];
    }

    function getCategory(uint8 categoryIndex_) external view returns (TexturePunxTraitStorage.TraitCategory memory) {
        if (categoryIndex_ >=  TexturePunxTraitStorage.layout().categoryCount) revert TexturePunxErrors.IndexOutOfBounds();
        return TexturePunxTraitStorage.layout().categories[categoryIndex_];
    }

    function getTraitDescription(uint8 categoryIndex_, uint8 traitIndex_) external view returns (TexturePunxTraitStorage.TraitDescription memory) {
        if (categoryIndex_ >=  TexturePunxTraitStorage.layout().categoryCount) revert TexturePunxErrors.IndexOutOfBounds();
        if (traitIndex_ >=  TexturePunxTraitStorage.layout().traitCount[categoryIndex_]) revert TexturePunxErrors.IndexOutOfBounds();
        return TexturePunxTraitStorage.layout().traits[categoryIndex_][traitIndex_];
    }

    function getTraitSVG(uint8 categoryIndex_, uint8 traitIndex_) public view returns (bytes memory) {
        if (categoryIndex_ >=  TexturePunxTraitStorage.layout().categoryCount) revert TexturePunxErrors.IndexOutOfBounds();
        if (traitIndex_ >=  TexturePunxTraitStorage.layout().traitCount[categoryIndex_]) revert TexturePunxErrors.IndexOutOfBounds();
        
        return TexturePunxTraitStorage.layout().svgs[
            _hashTraitName(
                TexturePunxTraitStorage.layout().categories[categoryIndex_].name, 
                TexturePunxTraitStorage.layout().traits[categoryIndex_][traitIndex_].name
            )
        ];
    }

    function getTraitByName(string memory categoryName_, string memory traitName_) internal view returns (bytes memory) {
        return TexturePunxTraitStorage.layout().svgs[_hashTraitName(categoryName_, traitName_)];
    }

    function _hashTraitName(string memory categoryName_, string memory traitName_) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("texture.punx.", categoryName_, ".", traitName_));
    }

    function getSerialization(uint256 tokenId_) external view returns (bytes32) {
        if (tokenId_ >= totalSupply()) 
            revert TexturePunxErrors.TokenDoesNotExist();
        return TexturePunxCoreStorage.layout().serializedPunx[tokenId_];
    }

    /// Function overrides =============================================================================

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId_) public view virtual override tokenExists(tokenId_) returns (string memory) {
        (string memory properties, string memory svg) = _build(tokenId_);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                base64(
                    abi.encodePacked(
                        '{"name":"#', 
                        tokenId_.toString(),
                        '","description":"', 
                        TexturePunxCoreStorage.layout().DESCRIPTION, 
                        '","traits":[', 
                        properties, 
                        '],"image":"data:image/svg+xml;base64,',
                        base64(abi.encodePacked(svg)),
                        '"}'
                    )
                )
            )
        );
    }

    function withdraw() public {
        (bool success_,) = TexturePunxPaymentStorage.layout().mintForwarder.call{value : address(this).balance}("");
        if (!success_) revert TexturePunxErrors.WithdrawTransferFailed();
    }

    function withdrawTokens(IERC20Upgradeable token) public {
        token.safeTransfer(
            TexturePunxPaymentStorage.layout().mintForwarder, 
            token.balanceOf(address(this))
        );
    }

    /// @dev See {IERC165-introspection}.
    function supportsInterface(bytes4 interfaceId_)
    public view virtual override(ERC721EnumerableUpgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return
            interfaceId_ == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    /// @dev See {IERC165-royaltyInfo}.
    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
    external view override
    tokenExists(tokenId_)
    returns (address receiver, uint256 royaltyAmount)
    {
        return (TexturePunxPaymentStorage.layout().royaltyForwarder, salePrice_.mulDivDown(50, 1000));
    }

    /// Base64 encoding ================================================================================

    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}