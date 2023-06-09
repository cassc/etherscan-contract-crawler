// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../extensions/ERC721AX.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "./lib/DynamicBuffer.sol";
import "./lib/HelperLib.sol";
import "./interfaces/IIndeliblePro.sol";

contract Indelible is ERC721AX, DefaultOperatorFilterer, ReentrancyGuard, Ownable {
    using HelperLib for uint;
    using DynamicBuffer for bytes;
    using LibPRNG for *;

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    
    struct LinkedTraitDTO {
        uint[] traitA;
        uint[] traitB;
    }
    
    struct TraitDTO {
        string name;
        string mimetype;
        bytes data;
        bool hide;
        bool useExistingData;
        uint existingDataIndex;
    }
    
    struct Trait {
        string name;
        string mimetype;
        bool hide;
    }
    
    struct ContractData {
        string name;
        string description;
        string image;
        string banner;
        string website;
        uint royalties;
        string royaltiesRecipient;
    }
    
    struct WithdrawRecipient {
        string name;
        string imageUrl;
        address recipientAddress;
        uint percentage;
    }

    mapping(uint => address[]) private _traitDataPointers;
    mapping(uint => mapping(uint => Trait)) private _traitDetails;
    mapping(uint => bool) private _renderTokenOffChain;
    mapping(uint => mapping(uint => uint[])) private _linkedTraits;
    
    address payable private immutable COLLECTOR_FEE_RECIPIENT = payable(0x29FbB84b835F892EBa2D331Af9278b74C595EDf1);
    uint public constant COLLECTOR_FEE = 0.000777 ether;
    uint private constant MAX_BATCH_MINT = 20;
    bytes32 private constant TIER_2_MERKLE_ROOT = 0xc425bc76658f762cc9bd3d856807a86589547ec178563509d317aa3a8a6f7ac0;

    uint[] private primeNumbers = [
        963410908066983680191871627575590268614639698853355414475467,
        935919214672529529254699379456068172547564622727740728385203,
        752418160701043808365139710144653623245409393563454484133021,
        668657002110143242634345628894400250523693660459153690697319,
        197636338835913099229515612260127815566058069514897730698607,
        773144458924271516429415765228637679419660582975860746246683,
        153761362786647109825322724558215431057092100535325989154943
    ];
    uint[][7] private tiers;
    string[] private layerNames = [unicode"Clothes", unicode"Hat", unicode"Eyes", unicode"Mouth", unicode"Earrings", unicode"Fur", unicode"Background"];
    bool private shouldWrapSVG = true;
    address private indelibleProContractAddress = 0xf3DAEb3772B00dFB3BBb1Ad4fB3494ea6b9Be4fE;
    string private backgroundColor = "transparent";
    uint private randomSeed;
    bytes32 private merkleRoot = 0xc6193aa8e271e27a235241caa7e5693511c0fc317fd0932ca604e81a949827a1;
    string private networkId = "1";
    string private placeholderImage = "";

    bool public isContractSealed;
    uint public maxSupply = 10000;
    uint public maxPerAddress = 5;
    uint public publicMintPrice = 0.010 ether;
    string public baseURI;
    bool public isPublicMintActive;
    uint public allowListPrice = 0.000 ether;
    uint public maxPerAllowList = 5;
    bool public isAllowListActive;

    ContractData public contractData = ContractData(unicode"Eth Monkey", unicode"10,000 Monkeys created on-chain using OnChainMonkey traits", "https://files.indelible.xyz/profile/111b04c4-0bce-47b7-af5f-fca0ef9caa63", "https://files.indelible.xyz/banner/111b04c4-0bce-47b7-af5f-fca0ef9caa63", "", 500, "0x30F82240D3b1a87cf1c98BAF036ca1002360FE3F");
    WithdrawRecipient[] public withdrawRecipients;

    constructor() ERC721A(unicode"Eth Monkey", unicode"ETHMONK") {
        tiers[0] = [2194,400,359,330,285,260,253,243,237,236,234,234,228,227,223,221,215,213,206,198,193,189,185,180,171,158,155,143,139,136,129,126,125,116,112,111,110,102,96,88,65,60,59,56];
        tiers[1] = [2149,621,465,420,383,376,358,351,345,330,264,254,241,229,229,226,217,216,192,188,171,155,153,147,146,129,125,122,116,100,97,92,85,83,81,72,72];
        tiers[2] = [1642,841,739,698,677,654,552,492,415,401,383,327,315,313,277,254,254,216,198,126,95,80,51];
        tiers[3] = [2080,1423,832,700,503,428,400,400,350,264,242,232,228,228,203,161,153,115,110,107,106,88,85,84,80,79,65,61,52,47,35,33,26];
        tiers[4] = [6796,982,884,584,421,216,117];
        tiers[5] = [1349,1344,1265,753,684,668,551,531,495,433,364,356,300,271,207,162,158,75,34];
        tiers[6] = [1520,1326,1219,1197,1194,1192,1186,1166];
        
        randomSeed = uint(
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

    modifier whenMintActive() {
        require(isMintActive(), "Minting is not active");
        _;
    }

    modifier whenUnsealed() {
        require(!isContractSealed, "Contract is sealed");
        _;
    }

    receive() external payable {
        require(isPublicMintActive, "Public minting is not active");
        handleMint(msg.value / publicMintPrice, msg.sender);
    }

    function rarityGen(uint randinput, uint rarityTier)
        internal
        view
        returns (uint)
    {
        uint currentLowerBound = 0;
        for (uint i = 0; i < tiers[rarityTier].length; i++) {
            uint thisPercentage = tiers[rarityTier][i];
            if (
                randinput >= currentLowerBound &&
                randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    function getTokenDataId(uint tokenId) internal view returns (uint) {
        uint[] memory indices = new uint[](maxSupply);

        unchecked {
            for (uint i; i < maxSupply; i += 1) {
                indices[i] = i;
            }
        }

        LibPRNG.PRNG memory prng;
        prng.seed(randomSeed);
        prng.shuffle(indices);

        return indices[tokenId];
    }

    function tokenIdToHash(
        uint tokenId
    ) public view returns (string memory) {
        require(randomSeed != 0, "Collection has not revealed");
        require(_exists(tokenId), "Invalid token");
        bytes memory hashBytes = DynamicBuffer.allocate(tiers.length * 4);
        uint tokenDataId = getTokenDataId(tokenId);

        uint[] memory hash = new uint[](tiers.length);
        bool[] memory modifiedLayers = new bool[](tiers.length);
        uint traitSeed = randomSeed % maxSupply;

        for (uint i = 0; i < tiers.length; i++) {
            uint traitIndex = hash[i];
            if (modifiedLayers[i] == false) {
                uint traitRangePosition = ((tokenDataId + i + traitSeed) * primeNumbers[i]) % maxSupply;
                traitIndex = rarityGen(traitRangePosition, i);
                hash[i] = traitIndex;
            }

            if (_linkedTraits[i][traitIndex].length > 0) {
                hash[_linkedTraits[i][traitIndex][0]] = _linkedTraits[i][traitIndex][1];
                modifiedLayers[_linkedTraits[i][traitIndex][0]] = true;
            }
        }

        for (uint i = 0; i < hash.length; i++) {
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

    function handleMint(uint count, address recipient) internal whenMintActive {
        uint totalMinted = _totalMinted();
        require(count > 0, "Invalid token count");
        require(totalMinted + count <= maxSupply, "All tokens are gone");
        uint mintPrice = isPublicMintActive ? publicMintPrice : allowListPrice;
        bool shouldCheckProHolder = count * (mintPrice + COLLECTOR_FEE) != msg.value;

        if (isPublicMintActive && msg.sender != owner()) {
            if (shouldCheckProHolder) {
                require(checkProHolder(msg.sender), "Missing collector's fee.");
                require(count * publicMintPrice == msg.value, "Incorrect amount of ether sent");
            } else {
                require(count * (publicMintPrice + COLLECTOR_FEE) == msg.value, "Incorrect amount of ether sent");
            }
            require(_numberMinted(msg.sender) + count <= maxPerAddress, "Exceeded max mints allowed");
            require(msg.sender == tx.origin, "EOAs only");
        }

        uint batchCount = count / MAX_BATCH_MINT;
        uint remainder = count % MAX_BATCH_MINT;

        for (uint i = 0; i < batchCount; i++) {
            _mint(recipient, MAX_BATCH_MINT);
        }

        if (remainder > 0) {
            _mint(recipient, remainder);
        }

        if (!shouldCheckProHolder && COLLECTOR_FEE > 0) {
            handleCollectorFee(count);
        }
    }

    function handleCollectorFee(uint count) internal {
        uint256 totalFee = COLLECTOR_FEE * count;
        (bool sent, ) = COLLECTOR_FEE_RECIPIENT.call{value: totalFee}("");
        require(sent, "Failed to send collector fee");
    }

    function mint(uint count, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        whenMintActive
    {
        if (!isPublicMintActive && msg.sender != owner()) {
            bool shouldCheckProHolder = count * (allowListPrice + COLLECTOR_FEE) != msg.value;
            if (shouldCheckProHolder) {
                require(checkProHolder(msg.sender), "Missing collector's fee.");
                require(count * allowListPrice == msg.value, "Incorrect amount of ether sent");
            } else {
                require(count * (allowListPrice + COLLECTOR_FEE) == msg.value, "Incorrect amount of ether sent");
            }
            require(onAllowList(msg.sender, merkleProof), "Not on allow list");
            require(_numberMinted(msg.sender) + count <= maxPerAllowList, "Exceeded max mints allowed");
        }
        handleMint(count, msg.sender);
    }

    function checkProHolder(address collector) public view returns (bool) {
        IIndeliblePro proContract = IIndeliblePro(indelibleProContractAddress);
        uint256 tokenCount = proContract.balanceOf(collector);
        return tokenCount > 0;
    }

    function airdrop(uint count, address[] calldata recipients)
        external
        payable
        nonReentrant
        whenMintActive
    {
        require(isPublicMintActive || msg.sender == owner(), "Public minting is not active");
        
        for (uint i = 0; i < recipients.length; i++) {
            handleMint(count, recipients[i]);
        }
    }

    function isMintActive() public view returns (bool) {
        return _totalMinted() < maxSupply && (isPublicMintActive || isAllowListActive || msg.sender == owner());
    }

    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        uint thisTraitIndex;
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe('<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-color:');
        svgBytes.appendSafe(
            abi.encodePacked(
                backgroundColor,
                ";background-image:url("
            )
        );

        for (uint i = 0; i < tiers.length - 1; i++) {
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
            HelperLib._substring(_hash, (tiers.length * 3) - 3, tiers.length * 3)
        );
            
        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                _traitDetails[tiers.length - 1][thisTraitIndex].mimetype,
                ";base64,",
                Base64.encode(SSTORE2.read(_traitDataPointers[tiers.length - 1][thisTraitIndex])),
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
        bool afterFirstTrait;

        for (uint i = 0; i < tiers.length; i++) {
            uint thisTraitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            if (_traitDetails[i][thisTraitIndex].hide == false) {
                if (afterFirstTrait) {
                    metadataBytes.appendSafe(",");
                }
                metadataBytes.appendSafe(
                    abi.encodePacked(
                        '{"trait_type":"',
                        layerNames[i],
                        '","value":"',
                        _traitDetails[i][thisTraitIndex].name,
                        '"}'
                    )
                );
                if (afterFirstTrait == false) {
                    afterFirstTrait = true;
                }
            }

            if (i == tiers.length - 1) {
                metadataBytes.appendSafe("]");
            }
        }

        return string(metadataBytes);
    }

    function onAllowList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(addr))) || MerkleProof.verify(merkleProof, TIER_2_MERKLE_ROOT, keccak256(abi.encodePacked(addr)));
    }

    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Invalid token");

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);

        jsonBytes.appendSafe(
            abi.encodePacked(
                '{"name":"',
                contractData.name,
                " #",
                _toString(tokenId),
                '","description":"',
                contractData.description,
                '",'
            )
        );

        if (randomSeed == 0) {
            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image":"',
                    placeholderImage,
                    '"}'
                )
            );
        } else {
            string memory tokenHash = tokenIdToHash(tokenId);
            
            if (bytes(baseURI).length > 0 && _renderTokenOffChain[tokenId]) {
                jsonBytes.appendSafe(
                    abi.encodePacked(
                        '"image":"',
                        baseURI,
                        _toString(tokenId),
                        "?dna=",
                        tokenHash,
                        '&networkId=',
                        networkId,
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
        }

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

    function isRevealed()
        public
        view
        returns (bool)
    {
        return randomSeed != 0;
    }

    function tokenIdToSVG(uint tokenId)
        public
        view
        returns (string memory)
    {
        return randomSeed == 0 ? placeholderImage : hashToSVG(tokenIdToHash(tokenId));
    }

    function traitDetails(uint layerIndex, uint traitIndex)
        public
        view
        returns (Trait memory)
    {
        return _traitDetails[layerIndex][traitIndex];
    }

    function traitData(uint layerIndex, uint traitIndex)
        public
        view
        returns (bytes memory)
    {
        return SSTORE2.read(_traitDataPointers[layerIndex][traitIndex]);
    }

    function getLinkedTraits(uint layerIndex, uint traitIndex)
        public
        view
        returns (uint[] memory)
    {
        return _linkedTraits[layerIndex][traitIndex];
    }

    function addLayer(uint layerIndex, TraitDTO[] calldata traits)
        public
        onlyOwner
        whenUnsealed
    {
        require(tiers[layerIndex].length == traits.length, "Traits length is incorrect");
        address[] memory dataPointers = new address[](traits.length);
        for (uint i = 0; i < traits.length; i++) {
            if (traits[i].useExistingData) {
                dataPointers[i] = dataPointers[traits[i].existingDataIndex];
            } else {
                dataPointers[i] = SSTORE2.write(traits[i].data);
            }
            _traitDetails[layerIndex][i] = Trait(traits[i].name, traits[i].mimetype, traits[i].hide);
        }
        _traitDataPointers[layerIndex] = dataPointers;
        return;
    }

    function addTrait(uint layerIndex, uint traitIndex, TraitDTO calldata trait)
        public
        onlyOwner
        whenUnsealed
    {
        _traitDetails[layerIndex][traitIndex] = Trait(trait.name, trait.mimetype, trait.hide);
        address[] memory dataPointers = _traitDataPointers[layerIndex];
        if (trait.useExistingData) {
            dataPointers[traitIndex] = dataPointers[trait.existingDataIndex];
        } else {
            dataPointers[traitIndex] = SSTORE2.write(trait.data);
        }
        _traitDataPointers[layerIndex] = dataPointers;
        return;
    }

    function setLinkedTraits(LinkedTraitDTO[] calldata linkedTraits)
        public
        onlyOwner
        whenUnsealed
    {
        for (uint i = 0; i < linkedTraits.length; i++) {
            _linkedTraits[linkedTraits[i].traitA[0]][linkedTraits[i].traitA[1]] = [linkedTraits[i].traitB[0],linkedTraits[i].traitB[1]];
        }
    }

    function setContractData(ContractData calldata data) external onlyOwner whenUnsealed {
        contractData = data;
    }

    function setMaxPerAddress(uint max) external onlyOwner {
        maxPerAddress = max;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;

        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    function setBackgroundColor(string calldata color) external onlyOwner whenUnsealed {
        backgroundColor = color;
    }

    function setRenderOfTokenId(uint tokenId, bool renderOffChain) external {
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        _renderTokenOffChain[tokenId] = renderOffChain;

        emit MetadataUpdate(tokenId);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setMaxPerAllowList(uint max) external onlyOwner {
        maxPerAllowList = max;
    }

    function setAllowListPrice(uint price) external onlyOwner {
        allowListPrice = price;
    }

    function setPublicMintPrice(uint price) external onlyOwner {
        publicMintPrice = price;
    }

    function setPlaceholderImage(string calldata placeholder) external onlyOwner {
        placeholderImage = placeholder;
    }

    function setRandomSeed() external onlyOwner {
        require(randomSeed == 0, "Random seed is already set");
        randomSeed = uint(
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
        isAllowListActive = !isAllowListActive;
    }

    function toggleWrapSVG() external onlyOwner {
        shouldWrapSVG = !shouldWrapSVG;
    }

    function togglePublicMint() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function sealContract() external whenUnsealed onlyOwner {
        isContractSealed = true;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint balance = address(this).balance;
        uint amount = balance;
        uint distAmount = 0;
        uint totalDistributionPercentage = 0;

        address payable receiver = payable(owner());

        if (withdrawRecipients.length > 0) {
            for (uint i = 0; i < withdrawRecipients.length; i++) {
                totalDistributionPercentage = totalDistributionPercentage + withdrawRecipients[i].percentage;
                address payable currRecepient = payable(withdrawRecipients[i].recipientAddress);
                distAmount = (amount * (10000 - withdrawRecipients[i].percentage)) / 10000;

                Address.sendValue(currRecepient, amount - distAmount);
            }
        }
        balance = address(this).balance;
        Address.sendValue(receiver, balance);
    }

    function transferFrom(address from, address to, uint tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}