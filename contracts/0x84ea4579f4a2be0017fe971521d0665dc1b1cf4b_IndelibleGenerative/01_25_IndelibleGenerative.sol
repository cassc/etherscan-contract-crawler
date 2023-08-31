// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import "./lib/DynamicBuffer.sol";
import "./lib/HelperLib.sol";
import "./interfaces/IIndelibleSecurity.sol";
import "./ICommon.sol";

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

struct Settings {
    uint256 maxPerAddress;
    uint256 publicMintPrice;
    uint256 mintStart;
    bool isContractSealed;
    string description;
    string placeholderImage;
}

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
    mapping(address => uint256) private latestBlockNumber;

    address private indelibleSecurity;
    address payable private collectorFeeRecipient;
    uint256 public collectorFee;

    bool private shouldWrapSVG = true;
    uint256 private revealSeed;
    uint256 private numberOfLayers;
    uint256 private signatureLifespan;

    string public baseURI;
    uint256 public maxSupply;
    Settings public settings;
    WithdrawRecipient[] public withdrawRecipients;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        Settings calldata _settings,
        RoyaltySettings calldata _royaltySettings,
        WithdrawRecipient[] calldata _withdrawRecipients,
        FactorySettings calldata _factorySettings
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();

        settings = _settings;
        settings.isContractSealed = false;
        maxSupply = _maxSupply;
        collectorFeeRecipient = payable(_factorySettings.collectorFeeRecipient);
        collectorFee = _factorySettings.collectorFee;
        indelibleSecurity = _factorySettings.indelibleSecurity;
        signatureLifespan = _factorySettings.signatureLifespan;

        for (uint256 i = 0; i < _withdrawRecipients.length; ) {
            withdrawRecipients.push(_withdrawRecipients[i]);
            unchecked {
                ++i;
            }
        }

        // reveal art if no placeholder is set
        if (bytes(_settings.placeholderImage).length == 0) {
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

        transferOwnership(_factorySettings.deployer);

        OperatorFiltererUpgradeable.__OperatorFilterer_init(
            _factorySettings.operatorFilter,
            _factorySettings.operatorFilter != address(0) // only subscribe if a filter is provided
        );
    }

    modifier whenUnsealed() {
        if (settings.isContractSealed) {
            revert NotAuthorized();
        }
        _;
    }

    function rarityGen(
        uint256 layerIndex,
        uint256 randomInput
    ) internal view returns (uint256) {
        uint256 currentLowerBound = 0;
        for (uint256 i = 0; i < layers[layerIndex].numberOfTraits; ) {
            uint256 thisPercentage = traits[layerIndex][i].occurrence;
            if (
                randomInput >= currentLowerBound &&
                randomInput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
            unchecked {
                ++i;
            }
        }

        revert("");
    }

    function getTokenDataId(uint256 tokenId) internal view returns (uint256) {
        uint256[] memory indices = new uint256[](maxSupply);

        for (uint256 i; i < maxSupply; ) {
            indices[i] = i;
            unchecked {
                ++i;
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

        for (uint256 i = 0; i < numberOfLayers; ) {
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
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < hash.length; ) {
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
            unchecked {
                ++i;
            }
        }

        return string(hashBytes);
    }

    function handleMint(
        uint256 quantity,
        address recipient,
        uint256 totalCollectorFee
    ) internal {
        if (quantity < 1 || _totalMinted() + quantity > maxSupply) {
            revert InvalidInput();
        }

        if (msg.sender != tx.origin) {
            revert NotAuthorized();
        }

        uint256 batchQuantity = quantity / 20;
        uint256 remainder = quantity % 20;

        for (uint256 i = 0; i < batchQuantity; ) {
            _mint(recipient, 20);
            unchecked {
                ++i;
            }
        }

        if (remainder > 0) {
            _mint(recipient, remainder);
        }

        if (totalCollectorFee > 0) {
            sendCollectorFee(totalCollectorFee);
        }
    }

    function publicMint(uint256 quantity, address to) internal {
        if (
            msg.sender != owner() &&
            (settings.mintStart == 0 || settings.mintStart >= block.timestamp)
        ) {
            revert NotAvailable();
        }

        bool hasCorrectValue = msg.sender == owner()
            ? quantity * collectorFee == msg.value
            : quantity * (settings.publicMintPrice + collectorFee) == msg.value;
        bool hasCorrectQuantity = settings.maxPerAddress == 0 ||
            _numberMinted(to) + quantity <= settings.maxPerAddress;

        if (
            (msg.sender != owner() && !hasCorrectQuantity) || !hasCorrectValue
        ) {
            revert InvalidInput();
        }

        handleMint(quantity, to, quantity * collectorFee);
    }

    function mint(uint256 quantity) external payable nonReentrant {
        publicMint(quantity, msg.sender);
    }

    function airdrop(
        uint256 quantity,
        address to
    ) external payable nonReentrant {
        publicMint(quantity, to);
    }

    function airdrop(
        uint256 quantity,
        address[] calldata to
    ) external payable nonReentrant {
        for (uint256 i = 0; i < to.length; ) {
            publicMint(quantity, to[i]);
            unchecked {
                ++i;
            }
        }
    }

    function signatureMint(
        Signature calldata signature,
        uint256 _nonce,
        uint256 _quantity,
        uint256 _maxPerAddress,
        uint256 _mintPrice,
        uint256 _collectorFee
    ) external payable nonReentrant {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _nonce,
                address(this),
                msg.sender,
                _quantity,
                _maxPerAddress,
                _mintPrice,
                _collectorFee,
                block.chainid
            )
        );

        IIndelibleSecurity securityContract = IIndelibleSecurity(
            indelibleSecurity
        );
        address signerAddress = securityContract.signerAddress();

        if (verifySignature(messageHash, signature) != signerAddress) {
            revert NotAuthorized();
        }

        bool hasCorrectValue = _quantity * (_mintPrice + _collectorFee) ==
            msg.value;
        bool hasCorrectQuantity = _maxPerAddress == 0 ||
            _numberMinted(msg.sender) + _quantity <= _maxPerAddress;
        bool hasCorrectNonce = _nonce > latestBlockNumber[msg.sender] &&
            _nonce + signatureLifespan > block.number;

        if (!hasCorrectValue || !hasCorrectQuantity || !hasCorrectNonce) {
            revert InvalidInput();
        }

        latestBlockNumber[msg.sender] = block.number;
        handleMint(_quantity, msg.sender, _quantity * _collectorFee);
    }

    function verifySignature(
        bytes32 messageHash,
        Signature calldata signature
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory prefixedMessage = abi.encodePacked(prefix, messageHash);
        bytes32 hashedMessage = keccak256(prefixedMessage);
        return ecrecover(hashedMessage, signature.v, signature.r, signature.s);
    }

    function sendCollectorFee(uint256 totalFee) internal {
        (bool sent, ) = collectorFeeRecipient.call{value: totalFee}("");
        if (!sent) {
            revert NotAuthorized();
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

        for (uint256 i = 0; i < numberOfLayers - 1; ) {
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
            unchecked {
                ++i;
            }
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

        for (uint256 i = 0; i < numberOfLayers; ) {
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

            unchecked {
                ++i;
            }
        }

        return string(metadataBytes);
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
                settings.description,
                '",'
            )
        );

        if (revealSeed == 0) {
            jsonBytes.appendSafe(
                abi.encodePacked('"image":"', settings.placeholderImage, '"}')
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

    function didMintEnd() public view returns (bool) {
        return _totalMinted() == maxSupply;
    }

    function isRevealed() public view returns (bool) {
        return revealSeed != 0;
    }

    function tokenIdToSVG(uint256 tokenId) public view returns (string memory) {
        return
            revealSeed == 0
                ? settings.placeholderImage
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
        for (uint256 i = 0; i < _traits.length; ) {
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
            unchecked {
                ++i;
            }
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
        for (uint256 i = 0; i < _linkedTraits.length; ) {
            linkedTraits[_linkedTraits[i].traitA[0]][
                _linkedTraits[i].traitA[1]
            ] = [_linkedTraits[i].traitB[0], _linkedTraits[i].traitB[1]];
            unchecked {
                ++i;
            }
        }
    }

    function setMaxPerAddress(uint256 maxPerAddress) external onlyOwner {
        settings.maxPerAddress = maxPerAddress;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;

        if (_totalMinted() > 0) {
            emit BatchMetadataUpdate(0, _totalMinted() - 1);
        }
    }

    function setRenderOfTokenId(uint256 tokenId, bool renderOffChain) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotAuthorized();
        }
        renderTokenOffChain[tokenId] = renderOffChain;

        emit MetadataUpdate(tokenId);
    }

    function setPublicMintPrice(uint256 publicMintPrice) external onlyOwner {
        settings.publicMintPrice = publicMintPrice;
    }

    function setPlaceholderImage(
        string calldata placeholderImage
    ) external onlyOwner {
        settings.placeholderImage = placeholderImage;
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

    function toggleWrapSVG() external onlyOwner {
        shouldWrapSVG = !shouldWrapSVG;
    }

    function setMintStart(uint256 mintStart) external whenUnsealed onlyOwner {
        settings.mintStart = mintStart;
    }

    function setHashOverride(
        uint256 tokenId,
        string calldata tokenHash
    ) external whenUnsealed onlyOwner {
        hashOverride[tokenId] = tokenHash;
    }

    function sealContract() external whenUnsealed onlyOwner {
        settings.isContractSealed = true;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 amount = balance;
        uint256 distAmount = 0;

        address payable receiver = payable(owner());

        if (withdrawRecipients.length > 0) {
            for (uint256 i = 0; i < withdrawRecipients.length; ) {
                address payable currRecepient = payable(
                    withdrawRecipients[i].recipientAddress
                );
                distAmount =
                    (amount * (10000 - withdrawRecipients[i].percentage)) /
                    10000;

                AddressUpgradeable.sendValue(
                    currRecepient,
                    amount - distAmount
                );
                unchecked {
                    ++i;
                }
            }
        }
        balance = address(this).balance;
        AddressUpgradeable.sendValue(receiver, balance);
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