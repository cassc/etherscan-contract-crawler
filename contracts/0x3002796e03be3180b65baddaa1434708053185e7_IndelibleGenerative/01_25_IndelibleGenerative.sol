// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import "./lib/DynamicBuffer.sol";
import "./lib/HelperLib.sol";
import "./interfaces/IIndeliblePro.sol";

struct LinkedTraitDTO {
    uint256[] traitA;
    uint256[] traitB;
}

struct TraitDTO {
    string name;
    string mimetype;
    uint256 occurrence;
    bytes data;
    bool hide;
    bool useExistingData;
    uint256 existingDataIndex;
}

struct Trait {
    string name;
    string mimetype;
    uint256 occurrence;
    address dataPointer;
    bool hide;
}

struct Layer {
    string name;
    uint256 primeNumber;
    uint256 numberOfTraits;
}

struct BaseSettings {
    uint256 maxPerAddress;
    uint256 publicMintPrice;
    uint256 allowListPrice;
    uint256 maxPerAllowList;
    bytes32 merkleRoot;
    bytes32 tier2MerkleRoot;
    bool isPublicMintActive;
    bool isAllowListActive;
    bool isContractSealed;
    string description;
    string placeholderImage;
}

struct WithdrawRecipient {
    address recipientAddress;
    uint256 percentage;
}

struct RoyaltySettings {
    address royaltyAddress;
    uint96 royaltyAmount;
}

error NotAvailable();
error NotAuthorized();
error InvalidInput();

contract IndelibleGenerative is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    OperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable
{
    using HelperLib for string;
    using DynamicBuffer for bytes;
    using LibPRNG for LibPRNG.PRNG;

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    mapping(uint256 => Layer) private layers;
    mapping(uint256 => mapping(uint256 => Trait)) private traits;
    mapping(uint256 => mapping(uint256 => uint256[])) private linkedTraits;
    mapping(uint256 => bool) private renderTokenOffChain;
    mapping(uint256 => string) private hashOverride;

    uint256 private constant MAX_BATCH_MINT = 20;

    address payable private collectorFeeRecipient;
    uint256 public collectorFee;

    bool private shouldWrapSVG = true;
    address private proContractAddress;
    uint256 private revealSeed;
    uint256 private numberOfLayers;

    string public baseURI;
    uint256 public maxSupply;
    BaseSettings public baseSettings;
    WithdrawRecipient[] public withdrawRecipients;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        BaseSettings calldata _baseSettings,
        RoyaltySettings calldata _royaltySettings,
        WithdrawRecipient[] calldata _withdrawRecipients,
        address _proContractAddress,
        address _collectorFeeRecipient,
        uint256 _collectorFee,
        address _deployer,
        address _operatorFilter
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();

        baseSettings = _baseSettings;
        baseSettings.isPublicMintActive = false;
        baseSettings.isAllowListActive = false;
        baseSettings.isContractSealed = false;
        maxSupply = _maxSupply;
        proContractAddress = _proContractAddress;
        collectorFeeRecipient = payable(_collectorFeeRecipient);
        collectorFee = _collectorFee;

        for (uint256 i = 0; i < _withdrawRecipients.length; ) {
            withdrawRecipients.push(_withdrawRecipients[i]);
            unchecked {
                ++i;
            }
        }

        // reveal art if no placeholder is set
        if (bytes(_baseSettings.placeholderImage).length == 0) {
            revealSeed = uint256(
                keccak256(
                    abi.encodePacked(
                        tx.gasprice,
                        block.number,
                        block.timestamp,
                        block.difficulty,
                        blockhash(block.number - 1),
                        msg.sender
                    )
                )
            );
        }

        _setDefaultRoyalty(
            _royaltySettings.royaltyAddress,
            _royaltySettings.royaltyAmount
        );

        transferOwnership(_deployer);

        OperatorFiltererUpgradeable.__OperatorFilterer_init(
            _operatorFilter,
            _operatorFilter == address(0) ? false : true // only subscribe if a filter is provided
        );
    }

    modifier whenMintActive() {
        if (
            _totalMinted() == maxSupply ||
            (!baseSettings.isPublicMintActive &&
                !baseSettings.isAllowListActive &&
                msg.sender != owner())
        ) {
            revert NotAvailable();
        }
        _;
    }

    modifier whenUnsealed() {
        if (baseSettings.isContractSealed) {
            revert NotAuthorized();
        }
        _;
    }

    function rarityGen(
        uint256 layerIndex,
        uint256 randomInput
    ) internal view returns (uint256) {
        uint256 currentLowerBound = 0;
        for (uint256 i = 0; i < layers[layerIndex].numberOfTraits; i++) {
            uint256 thisPercentage = traits[layerIndex][i].occurrence;
            if (
                randomInput >= currentLowerBound &&
                randomInput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert("");
    }

    function getTokenDataId(uint256 tokenId) internal view returns (uint256) {
        uint256[] memory indices = new uint256[](maxSupply);

        unchecked {
            for (uint256 i; i < maxSupply; i += 1) {
                indices[i] = i;
            }
        }

        LibPRNG.PRNG memory prng;
        prng.seed(revealSeed);
        prng.shuffle(indices);

        return indices[tokenId];
    }

    function tokenIdToHash(
        uint256 tokenId
    ) public view returns (string memory) {
        if (revealSeed == 0 || !_exists(tokenId)) {
            revert NotAvailable();
        }
        if (bytes(hashOverride[tokenId]).length > 0) {
            return hashOverride[tokenId];
        }
        bytes memory hashBytes = DynamicBuffer.allocate(numberOfLayers * 4);
        uint256 tokenDataId = getTokenDataId(tokenId);

        uint256[] memory hash = new uint256[](numberOfLayers);
        bool[] memory modifiedLayers = new bool[](numberOfLayers);
        uint256 traitSeed = revealSeed % maxSupply;

        for (uint256 i = 0; i < numberOfLayers; i++) {
            uint256 traitIndex = hash[i];
            if (modifiedLayers[i] == false) {
                uint256 traitRangePosition = ((tokenDataId + i + traitSeed) *
                    layers[i].primeNumber) % maxSupply;
                traitIndex = rarityGen(i, traitRangePosition);
                hash[i] = traitIndex;
            }

            if (linkedTraits[i][traitIndex].length > 0) {
                hash[linkedTraits[i][traitIndex][0]] = linkedTraits[i][
                    traitIndex
                ][1];
                modifiedLayers[linkedTraits[i][traitIndex][0]] = true;
            }
        }

        for (uint256 i = 0; i < hash.length; i++) {
            if (hash[i] < 10) {
                hashBytes.appendSafe("00");
            } else if (hash[i] < 100) {
                hashBytes.appendSafe("0");
            }
            if (hash[i] > 999) {
                hashBytes.appendSafe("999");
            } else {
                hashBytes.appendSafe(bytes(_toString(hash[i])));
            }
        }

        return string(hashBytes);
    }

    function handleMint(
        uint256 count,
        address recipient
    ) internal whenMintActive {
        uint256 mintPrice = baseSettings.isPublicMintActive
            ? baseSettings.publicMintPrice
            : baseSettings.allowListPrice;
        bool shouldCheckProHolder = count * (mintPrice + collectorFee) !=
            msg.value;

        if (
            count < 1 ||
            _totalMinted() + count > maxSupply ||
            (msg.sender != owner() &&
                ((shouldCheckProHolder &&
                    (!checkProHolder(msg.sender) ||
                        count * mintPrice != msg.value)) ||
                    (baseSettings.isPublicMintActive &&
                        _numberMinted(msg.sender) + count >
                        baseSettings.maxPerAddress)))
        ) {
            revert InvalidInput();
        }

        if (msg.sender != tx.origin) {
            revert NotAuthorized();
        }

        uint256 batchCount = count / MAX_BATCH_MINT;
        uint256 remainder = count % MAX_BATCH_MINT;

        for (uint256 i = 0; i < batchCount; i++) {
            _mint(recipient, MAX_BATCH_MINT);
        }

        if (remainder > 0) {
            _mint(recipient, remainder);
        }

        if (!shouldCheckProHolder && collectorFee > 0) {
            handleCollectorFee(count);
        }
    }

    function handleCollectorFee(uint256 count) internal {
        uint256 totalFee = collectorFee * count;
        (bool sent, ) = collectorFeeRecipient.call{value: totalFee}("");
        if (!sent) {
            revert NotAuthorized();
        }
    }

    function mint(
        uint256 count,
        uint256 max,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant whenMintActive {
        if (!baseSettings.isPublicMintActive && msg.sender != owner()) {
            uint256 _maxPerAllowList = max > 0
                ? max
                : baseSettings.maxPerAllowList;
            if (
                !onAllowList(msg.sender, max, merkleProof) ||
                _numberMinted(msg.sender) + count > _maxPerAllowList
            ) {
                revert InvalidInput();
            }
        }
        handleMint(count, msg.sender);
    }

    function checkProHolder(address collector) public view returns (bool) {
        IIndeliblePro proContract = IIndeliblePro(proContractAddress);
        uint256 tokenCount = proContract.balanceOf(collector);
        return tokenCount > 0;
    }

    function airdrop(
        uint256 count,
        address[] calldata recipients
    ) external payable nonReentrant whenMintActive {
        if (!baseSettings.isPublicMintActive && msg.sender != owner()) {
            revert NotAvailable();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            handleMint(count, recipients[i]);
        }
    }

    function hashToSVG(
        string memory _hash
    ) public view returns (string memory) {
        uint256 thisTraitIndex;

        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe(
            '<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-image:url('
        );

        for (uint256 i = 0; i < numberOfLayers - 1; i++) {
            thisTraitIndex = _hash.subStr((i * 3), (i * 3) + 3).parseInt();
            svgBytes.appendSafe(
                abi.encodePacked(
                    "data:",
                    traits[i][thisTraitIndex].mimetype,
                    ";base64,",
                    Base64.encode(
                        SSTORE2.read(traits[i][thisTraitIndex].dataPointer)
                    ),
                    "),url("
                )
            );
        }

        thisTraitIndex = _hash
            .subStr((numberOfLayers * 3) - 3, numberOfLayers * 3)
            .parseInt();

        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                traits[numberOfLayers - 1][thisTraitIndex].mimetype,
                ";base64,",
                Base64.encode(
                    SSTORE2.read(
                        traits[numberOfLayers - 1][thisTraitIndex].dataPointer
                    )
                ),
                ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svgBytes)
                )
            );
    }

    function hashToMetadata(
        string memory _hash
    ) public view returns (string memory) {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        metadataBytes.appendSafe("[");
        bool afterFirstTrait;

        for (uint256 i = 0; i < numberOfLayers; i++) {
            uint256 thisTraitIndex = _hash
                .subStr((i * 3), (i * 3) + 3)
                .parseInt();
            if (traits[i][thisTraitIndex].hide == false) {
                if (afterFirstTrait) {
                    metadataBytes.appendSafe(",");
                }
                metadataBytes.appendSafe(
                    abi.encodePacked(
                        '{"trait_type":"',
                        layers[i].name,
                        '","value":"',
                        traits[i][thisTraitIndex].name,
                        '"}'
                    )
                );
                if (afterFirstTrait == false) {
                    afterFirstTrait = true;
                }
            }

            if (i == numberOfLayers - 1) {
                metadataBytes.appendSafe("]");
            }
        }

        return string(metadataBytes);
    }

    function onAllowList(
        address addr,
        uint256 max,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        if (max > 0) {
            return
                MerkleProof.verify(
                    merkleProof,
                    baseSettings.merkleRoot,
                    keccak256(abi.encodePacked(addr, max))
                );
        }
        return
            MerkleProof.verify(
                merkleProof,
                baseSettings.merkleRoot,
                keccak256(abi.encodePacked(addr))
            ) ||
            MerkleProof.verify(
                merkleProof,
                baseSettings.tier2MerkleRoot,
                keccak256(abi.encodePacked(addr))
            );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidInput();
        }

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);

        jsonBytes.appendSafe(
            abi.encodePacked(
                '{"name":"',
                name(),
                " #",
                _toString(tokenId),
                '","description":"',
                baseSettings.description,
                '",'
            )
        );

        if (revealSeed == 0) {
            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image":"',
                    baseSettings.placeholderImage,
                    '"}'
                )
            );
        } else {
            string memory tokenHash = tokenIdToHash(tokenId);

            if (bytes(baseURI).length > 0 && renderTokenOffChain[tokenId]) {
                jsonBytes.appendSafe(
                    abi.encodePacked(
                        '"image":"',
                        baseURI,
                        _toString(tokenId),
                        "?dna=",
                        tokenHash,
                        "&networkId=",
                        _toString(block.chainid),
                        '",'
                    )
                );
            } else {
                string memory svgCode = "";
                if (shouldWrapSVG) {
                    string memory svgString = hashToSVG(tokenHash);
                    svgCode = string(
                        abi.encodePacked(
                            "data:image/svg+xml;base64,",
                            Base64.encode(
                                abi.encodePacked(
                                    '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                    svgString,
                                    '"></image></svg>'
                                )
                            )
                        )
                    );
                } else {
                    svgCode = hashToSVG(tokenHash);
                }

                jsonBytes.appendSafe(
                    abi.encodePacked('"image_data":"', svgCode, '",')
                );
            }

            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"attributes":',
                    hashToMetadata(tokenHash),
                    "}"
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(jsonBytes)
                )
            );
    }

    function isRevealed() public view returns (bool) {
        return revealSeed != 0;
    }

    function tokenIdToSVG(uint256 tokenId) public view returns (string memory) {
        return
            revealSeed == 0
                ? baseSettings.placeholderImage
                : hashToSVG(tokenIdToHash(tokenId));
    }

    function traitDetails(
        uint256 layerIndex,
        uint256 traitIndex
    ) public view returns (Trait memory) {
        return traits[layerIndex][traitIndex];
    }

    function traitData(
        uint256 layerIndex,
        uint256 traitIndex
    ) public view returns (bytes memory) {
        return SSTORE2.read(traits[layerIndex][traitIndex].dataPointer);
    }

    function getLinkedTraits(
        uint256 layerIndex,
        uint256 traitIndex
    ) public view returns (uint256[] memory) {
        return linkedTraits[layerIndex][traitIndex];
    }

    function addLayer(
        uint256 index,
        string calldata name,
        uint256 primeNumber,
        TraitDTO[] calldata _traits,
        uint256 _numberOfLayers
    ) public onlyOwner whenUnsealed {
        layers[index] = Layer(name, primeNumber, _traits.length);
        numberOfLayers = _numberOfLayers;
        for (uint256 i = 0; i < _traits.length; i++) {
            address dataPointer;
            if (_traits[i].useExistingData) {
                dataPointer = traits[index][_traits[i].existingDataIndex]
                    .dataPointer;
            } else {
                dataPointer = SSTORE2.write(_traits[i].data);
            }
            traits[index][i] = Trait(
                _traits[i].name,
                _traits[i].mimetype,
                _traits[i].occurrence,
                dataPointer,
                _traits[i].hide
            );
        }
        return;
    }

    function addTrait(
        uint256 layerIndex,
        uint256 traitIndex,
        TraitDTO calldata _trait
    ) public onlyOwner whenUnsealed {
        address dataPointer;
        if (_trait.useExistingData) {
            dataPointer = traits[layerIndex][traitIndex].dataPointer;
        } else {
            dataPointer = SSTORE2.write(_trait.data);
        }
        traits[layerIndex][traitIndex] = Trait(
            _trait.name,
            _trait.mimetype,
            _trait.occurrence,
            dataPointer,
            _trait.hide
        );
        return;
    }

    function setLinkedTraits(
        LinkedTraitDTO[] calldata _linkedTraits
    ) public onlyOwner whenUnsealed {
        for (uint256 i = 0; i < _linkedTraits.length; i++) {
            linkedTraits[_linkedTraits[i].traitA[0]][
                _linkedTraits[i].traitA[1]
            ] = [_linkedTraits[i].traitB[0], _linkedTraits[i].traitB[1]];
        }
    }

    function setMaxPerAddress(uint256 maxPerAddress) external onlyOwner {
        baseSettings.maxPerAddress = maxPerAddress;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;

        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    function setRenderOfTokenId(uint256 tokenId, bool renderOffChain) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotAuthorized();
        }
        renderTokenOffChain[tokenId] = renderOffChain;

        emit MetadataUpdate(tokenId);
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        baseSettings.merkleRoot = merkleRoot;
    }

    function setMaxPerAllowList(uint256 maxPerAllowList) external onlyOwner {
        baseSettings.maxPerAllowList = maxPerAllowList;
    }

    function setAllowListPrice(uint256 allowListPrice) external onlyOwner {
        baseSettings.allowListPrice = allowListPrice;
    }

    function setPublicMintPrice(uint256 publicMintPrice) external onlyOwner {
        baseSettings.publicMintPrice = publicMintPrice;
    }

    function setPlaceholderImage(
        string calldata placeholderImage
    ) external onlyOwner {
        baseSettings.placeholderImage = placeholderImage;
    }

    function setRevealSeed() external onlyOwner {
        if (revealSeed != 0) {
            revert NotAuthorized();
        }
        revealSeed = uint256(
            keccak256(
                abi.encodePacked(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );

        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    function toggleAllowListMint() external onlyOwner {
        baseSettings.isAllowListActive = !baseSettings.isAllowListActive;
    }

    function toggleWrapSVG() external onlyOwner {
        shouldWrapSVG = !shouldWrapSVG;
    }

    function togglePublicMint() external onlyOwner {
        baseSettings.isPublicMintActive = !baseSettings.isPublicMintActive;
    }

    function setHashOverride(
        uint256 tokenId,
        string calldata tokenHash
    ) external whenUnsealed onlyOwner {
        hashOverride[tokenId] = tokenHash;
    }

    function sealContract() external whenUnsealed onlyOwner {
        baseSettings.isContractSealed = true;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 amount = balance;
        uint256 distAmount = 0;
        uint256 totalDistributionPercentage = 0;

        address payable receiver = payable(owner());

        if (withdrawRecipients.length > 0) {
            for (uint256 i = 0; i < withdrawRecipients.length; i++) {
                totalDistributionPercentage =
                    totalDistributionPercentage +
                    withdrawRecipients[i].percentage;
                address payable currRecepient = payable(
                    withdrawRecipients[i].recipientAddress
                );
                distAmount =
                    (amount * (10000 - withdrawRecipients[i].percentage)) /
                    10000;

                Address.sendValue(currRecepient, amount - distAmount);
            }
        }
        balance = address(this).balance;
        Address.sendValue(receiver, balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}