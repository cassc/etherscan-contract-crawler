// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./SSTORE2.sol";
import "./DynamicBuffer.sol";
import "./HelperLib.sol";

interface IOnChainKevin {
    function balanceOf(address owner) external view returns (uint256);
}

contract IndelibleERC721A is ERC721A, ReentrancyGuard, Ownable {
    using HelperLib for uint256;
    using DynamicBuffer for bytes;

    struct TraitDTO {
        string name;
        string mimetype;
        bytes data;
    }
    
    struct Trait {
        string name;
        string mimetype;
    }

    struct ContractData {
        string name;
        string description;
        string image;
        string banner;
        string website;
        uint256 royalties;
        string royaltiesRecipient;
    }

    mapping(uint256 => uint256) internal _tokenIdToRandomBytes;
    mapping(uint256 => address[]) internal _traitDataPointers;
    mapping(uint256 => mapping(uint256 => Trait)) internal _traitDetails;
    mapping(uint256 => bool) internal _renderTokenOffChain;
    mapping(address => uint256) internal _freeMints;

    uint256 private constant MAX_TOKENS = 5000;
    uint256 private constant NUM_LAYERS = 9;
    uint256 private constant MAX_BATCH_MINT = 20;
    uint256[][NUM_LAYERS] private TIERS;
    string[] private LAYER_NAMES = [unicode"Lasers", unicode"Mouth", unicode"Head", unicode"Face", unicode"Nose", unicode"Eyes", unicode"Shirt", unicode"Skin", unicode"Background"];
    bool private shouldWrapSVG = true;
    address private ockContractAddress = 0x17B19C70bfcA098da3f2eFeF6e7FA3a1C42F5429;
    uint256 public maxPerAddress = 100;
    uint256 public maxFreePerAddress = 1;
    uint256 public mintPrice = 0.005 ether;
    string public baseURI = "";
    bool public isMintingPaused = true;
    ContractData public contractData = ContractData(unicode"Long Live Kevin", unicode"On-chain animated Kevins and the first collection released using Indelible Labs. Zero utility. Just a fun proof of concept.", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/85e11fb3-5fae-4062-b40f-698436b0c0cb", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/85e11fb3-5fae-4062-b40f-698436b0c0cb", "", 1000, "0xEA208Da933C43857683C04BC76e3FD331D7bfdf7");

    constructor() ERC721A(unicode"Long Live Kevin", unicode"LLKEVIN") {
        TIERS[0] = [50,70,90,200,300,400,3890];
TIERS[1] = [100,200,200,300,400,500,500,600,700,700,800];
TIERS[2] = [18,24,50,90,118,150,200,250,250,300,300,350,350,400,400,400,450,450,450];
TIERS[3] = [36,82,83,98,106,145,200,250,300,350,400,400,450,450,500,550,600];
TIERS[4] = [500,800,850,900,950,1000];
TIERS[5] = [493,557,600,700,800,900,950];
TIERS[6] = [100,110,120,130,198,230,269,325,327,349,430,446,450,469,500,547];
TIERS[7] = [53,2072,2875];
TIERS[8] = [50,70,117,163,300,400,400,500,600,700,800,900];
    }

    modifier whenPublicMintActive() {
        require(isPublicMintActive(), "Public sale not open");
        _;
    }

    function rarityGen(uint256 _randinput, uint256 _rarityTier)
        internal
        view
        returns (uint256)
    {
        uint256 currentLowerBound = 0;
        for (uint256 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint256 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    function hashFromRandomBytes(
        uint256 _randomBytes,
        uint256 _tokenId,
        uint256 _startingTokenId
    ) internal view returns (string memory) {
        require(_exists(_tokenId), "Invalid token");
        // This will generate a NUM_LAYERS * 3 character string.
        bytes memory hashBytes = DynamicBuffer.allocate(NUM_LAYERS * 4);

        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            uint256 _randinput = uint256(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _randomBytes,
                            _tokenId,
                            _startingTokenId,
                            _tokenId + i
                        )
                    )
                ) % MAX_TOKENS
            );

            uint256 rarity = rarityGen(_randinput, i);

            if (rarity < 10) {
                hashBytes.appendSafe("00");
            } else if (rarity < 100) {
                hashBytes.appendSafe("0");
            }
            if (rarity > 999) {
                hashBytes.appendSafe("999");
            } else {
                hashBytes.appendSafe(bytes(_toString(rarity)));
            }
        }

        return string(hashBytes);
    }

    function mint(uint256 _count) external payable nonReentrant whenPublicMintActive returns (uint256) {
        uint256 totalMinted = _totalMinted();
        require(totalMinted + _count <= MAX_TOKENS, "All tokens are gone");
        require(_count > 0, "Invalid token count");
        if (msg.value == 0 && mintPrice > 0) {
            IOnChainKevin ockContract = IOnChainKevin(ockContractAddress);
            require(ockContract.balanceOf(msg.sender) > 0, "Not allowed a free mint.");
            require(_freeMints[msg.sender] + _count <= maxFreePerAddress, "Exceeded max free mints allowed.");
        } else {
            require(_count * mintPrice == msg.value, "Incorrect amount of ether sent");
        }
        require(balanceOf(msg.sender) + _count <= maxPerAddress, "Exceeded max mints allowed.");

        uint256 batchCount = _count / MAX_BATCH_MINT;
        uint256 remainder = _count % MAX_BATCH_MINT;

        uint256 randomBytes = uint256(
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

        for (uint256 i = 0; i < batchCount; i++) {
            if (i == 0) {
                _tokenIdToRandomBytes[totalMinted] = randomBytes;
            } else {
                _tokenIdToRandomBytes[totalMinted + (i * MAX_BATCH_MINT)] = randomBytes;
            }
    
            _mint(msg.sender, MAX_BATCH_MINT);
        }

        if (remainder > 0) {
            if (batchCount == 0) {
                _tokenIdToRandomBytes[totalMinted] = randomBytes;
            } else {
                _tokenIdToRandomBytes[totalMinted + (batchCount * MAX_BATCH_MINT)] = randomBytes;
            }

            _mint(msg.sender, remainder);
        }

        if (msg.value == 0 && mintPrice > 0) {
            _freeMints[msg.sender] = _count;
        }

        return totalMinted;
    }

    function isPublicMintActive() public view returns (bool) {
        return _totalMinted() < MAX_TOKENS && isMintingPaused == false;
    }

    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        uint256 thisTraitIndex;
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe(
            abi.encodePacked(
                '<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-image:url('
            )
        );

        for (uint256 i = 0; i < NUM_LAYERS - 1; i++) {
            thisTraitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            svgBytes.appendSafe(
                abi.encodePacked(
                    "data:",
                    _traitDetails[i][thisTraitIndex].mimetype,
                    ";base64,",
                    Base64.encode(SSTORE2.read(_traitDataPointers[i][thisTraitIndex])),
                    "),url("
                )
            );
        }

        thisTraitIndex = HelperLib.parseInt(
            HelperLib._substring(_hash, (NUM_LAYERS * 3) - 3, NUM_LAYERS * 3)
        );

        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                _traitDetails[NUM_LAYERS - 1][thisTraitIndex].mimetype,
                ";base64,",
                Base64.encode(SSTORE2.read(_traitDataPointers[NUM_LAYERS - 1][thisTraitIndex])),
                ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
            )
        );

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svgBytes)
            )
        );
    }

    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        metadataBytes.appendSafe("[");

        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            uint256 thisTraitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            metadataBytes.appendSafe(
                abi.encodePacked(
                    '{"trait_type":"',
                    LAYER_NAMES[i],
                    '","value":"',
                    _traitDetails[i][thisTraitIndex].name,
                    '"}'
                )
            );
            
            if (i == NUM_LAYERS - 1) {
                metadataBytes.appendSafe("]");
            } else {
                metadataBytes.appendSafe(",");
            }
        }

        return string(metadataBytes);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Invalid token");
        require(_traitDataPointers[0].length > 0,  "Traits have not been added");

        string memory tokenHash = tokenIdToHash(_tokenId);

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);
        jsonBytes.appendSafe(unicode"{\"name\":\"Long Live Kevin #");

        jsonBytes.appendSafe(
            abi.encodePacked(
                _toString(_tokenId),
                "\",\"description\":\"",
                contractData.description,
                "\","
            )
        );

        if (bytes(baseURI).length > 0 && _renderTokenOffChain[_tokenId]) {
            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image":"',
                    baseURI,
                    _toString(_tokenId),
                    "?dna=",
                    tokenHash,
                    '&network=mainnet",'
                )
            );
        } else {
            string memory svgCode = "";
            if (shouldWrapSVG) {
                svgCode = string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                hashToSVG(tokenHash),
                                '"></image></svg>'
                            )
                        )
                    )
                );
                jsonBytes.appendSafe(
                    abi.encodePacked(
                        '"svg_image_data":"',
                        hashToSVG(tokenHash),
                        '",'
                    )
                );
            } else {
                svgCode = hashToSVG(tokenHash);
            }

            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image_data":"',
                    svgCode,
                    '",'
                )
            );
        }

        jsonBytes.appendSafe(
            abi.encodePacked(
                '"attributes":',
                hashToMetadata(tokenHash),
                "}"
            )
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(jsonBytes)
            )
        );
    }

    function contractURI()
        public
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        contractData.name,
                        '","description":"',
                        contractData.description,
                        '","image":"',
                        contractData.image,
                        '","banner":"',
                        contractData.banner,
                        '","external_link":"',
                        contractData.website,
                        '","seller_fee_basis_points":',
                        _toString(contractData.royalties),
                        ',"fee_recipient":"',
                        contractData.royaltiesRecipient,
                        '"}'
                    )
                )
            )
        );
    }

    function tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        // decrement to find first token in batch
        for (uint256 i = 0; i < MAX_BATCH_MINT; i++) {
            if (_tokenIdToRandomBytes[_tokenId - i] > 0) {
                return hashFromRandomBytes(_tokenIdToRandomBytes[_tokenId - i], _tokenId, _tokenId - i);
            }
        }
        revert();
    }

    function tokenIdToSVG(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return hashToSVG(tokenIdToHash(_tokenId));
    }

    function traitDetails(uint256 _layerIndex, uint256 _traitIndex)
        public
        view
        returns (Trait memory)
    {
        return _traitDetails[_layerIndex][_traitIndex];
    }

    function traitData(uint256 _layerIndex, uint256 _traitIndex)
        public
        view
        returns (string memory)
    {
        return string(SSTORE2.read(_traitDataPointers[_layerIndex][_traitIndex]));
    }

    function addLayer(uint256 _layerIndex, TraitDTO[] memory traits)
        public
        onlyOwner
    {
        require(TIERS[_layerIndex].length == traits.length, "Traits size does not match tiers for this index");
        address[] memory dataPointers = new address[](traits.length);
        for (uint256 i = 0; i < traits.length; i++) {
            dataPointers[i] = SSTORE2.write(traits[i].data);
            _traitDetails[_layerIndex][i] = Trait(traits[i].name, traits[i].mimetype);
        }
        _traitDataPointers[_layerIndex] = dataPointers;
        return;
    }

    function addTrait(uint256 _layerIndex, uint256 _traitIndex, TraitDTO memory trait)
        public
        onlyOwner
    {
        _traitDetails[_layerIndex][_traitIndex] = Trait(trait.name, trait.mimetype);
        address[] memory dataPointers = _traitDataPointers[_layerIndex];
        dataPointers[_traitIndex] = SSTORE2.write(trait.data);
        _traitDataPointers[_layerIndex] = dataPointers;
        return;
    }

    function changeContractData(ContractData memory _contractData) external onlyOwner {
        contractData = _contractData;
    }

    function changeOCKContractAddress(address _contractAddress) external onlyOwner {
        ockContractAddress = _contractAddress;
    }

    function changeMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    function changeBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function changeRenderOfTokenId(uint256 _tokenId, bool _renderOffChain) external {
        require(msg.sender == ownerOf(_tokenId), "Only the token owner can change the render method");
        _renderTokenOffChain[_tokenId] = _renderOffChain;
    }

    function toggleWrapSVG() external onlyOwner {
        shouldWrapSVG = !shouldWrapSVG;
    }

    function toggleMinting() external onlyOwner {
        isMintingPaused = !isMintingPaused;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}