// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/Base64.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "./SSTORE2.sol";
import "./DynamicBuffer.sol";
import "./HelperLib.sol";

contract Indelible is ERC721A, DefaultOperatorFilterer, ReentrancyGuard, Ownable {
    using HelperLib for uint;
    using DynamicBuffer for bytes;
    using LibPRNG for *;
    
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
    
    uint private constant DEVELOPER_FEE = 250; // of 10,000 = 2.5%
    uint private constant MAX_BATCH_MINT = 20;

    uint[] private primeNumbers = [
        263743197985470588204349265269345001644610514897601719492623,
        489283222294688268987820540542047890674696745383853025932409,
        445730560699308616878100110185308606331080346485121531052089,
        632927012893602565676075421341685619761332234876041339403653,
        432534654635437988648695007417836862217547977730730769366091,
        935919214672529529254699379456068172547564622727740728385203,
        752418160701043808365139710144653623245409393563454484133021,
        258651016223339299696400112684012163441306064889610262117641,
        135419986466399101724740108903015610477591324758987986294397
    ];
    uint[][9] private tiers;
    string[] private layerNames = [unicode"Emote", unicode"Mouth", unicode"Eyes", unicode"Head", unicode"Clothes", unicode"Skin", unicode"Clothes Color", unicode"Background", unicode"Sky"];
    bool private shouldWrapSVG = true;
    string private backgroundColor = "transparent";
    uint private randomSeed;
    bytes32 private merkleRoot = 0;
    string private networkId = "1";

    bool public isContractSealed;
    uint public maxSupply = 7654;
    uint public maxPerAddress = 4;
    uint public publicMintPrice = 0.0275 ether;
    string public baseURI;
    bool public isPublicMintActive;
    uint public allowListPrice = 0.0075 ether;
    uint public maxPerAllowList = 1;
    bool public isAllowListActive;

    ContractData public contractData = ContractData(unicode"ecc0s", unicode"ecc0s is an on-chain digital collection of vector NFTs with public domain license (CC0). Each one of the 200+ traits has been crafted to be efficiently deployed on-chain, and infinitely scalable for print and digital usage. Using a clean simple art style, ecc0s are designed for derivative creation, to be “ecc0ed” – modified or completely reimagined by their holders. ecc0s is a progressive multi-collection project where holders are granted priority and exclusivity for all future ecc0s releases.", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/251e9344-2aed-4a44-9614-2517db3be9e9", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/251e9344-2aed-4a44-9614-2517db3be9e9", "https://ecc0s.com/", 800, "0x8CaF042685e8740C6dC9d6aC23a28d0BE00139E3");
    WithdrawRecipient[] public withdrawRecipients;

    constructor() ERC721A(unicode"ecc0s", unicode"ECC0S") {
        tiers[0] = [4,30,50,108,116,120,127,131,135,139,140,147,185,193,209,213,217,220,224,238,258,265,283,290,335,358,360,436,555,1568];
        tiers[1] = [50,150,387,542,620,697,968,1298,1450,1492];
        tiers[2] = [2,50,294,325,348,372,403,527,558,864,938,942,1015,1016];
        tiers[3] = [2,30,50,60,61,67,68,68,69,75,75,75,82,82,85,93,95,105,108,110,111,112,116,117,117,117,118,120,120,124,125,126,126,126,127,127,128,130,130,132,132,134,134,135,136,136,137,137,137,139,139,141,141,144,144,144,145,145,146,150,153,156,157,158,160,165];
        tiers[4] = [50,189,190,193,302,317,428,570,591,630,665,676,688,689,702,774];
        tiers[5] = [5,10,10,10,75,1807,1884,1891,1962];
        tiers[6] = [263,271,279,286,294,302,1050,1128,1206,1284,1291];
        tiers[7] = [77,224,232,233,234,237,240,248,253,263,275,280,282,286,294,302,310,324,324,335,345,353,358,361,449,535];
        tiers[8] = [5,13,47,58,64,68,70,72,487,495,502,510,516,517,519,520,522,526,532,534,535,542];
        
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

    function handleMint(uint count, address recipient) internal whenMintActive returns (uint) {
        uint totalMinted = _totalMinted();
        require(count > 0, "Invalid token count");
        require(totalMinted + count <= maxSupply, "All tokens are gone");

        if (isPublicMintActive) {
            if (msg.sender != owner()) {
                require(_numberMinted(msg.sender) + count <= maxPerAddress, "Exceeded max mints allowed");
                require(count * publicMintPrice == msg.value, "Incorrect amount of ether sent");
            }
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

        return totalMinted;
    }

    function mint(uint count, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        whenMintActive
        returns (uint)
    {
        if (!isPublicMintActive && msg.sender != owner()) {
            require(onAllowList(msg.sender, merkleProof), "Not on allow list");
            require(_numberMinted(msg.sender) + count <= maxPerAllowList, "Exceeded max mints allowed");
            require(count * allowListPrice == msg.value, "Incorrect amount of ether sent");
        }
        return handleMint(count, msg.sender);
    }

    function airdrop(uint count, address recipient)
        external
        payable
        nonReentrant
        whenMintActive
        returns (uint)
    {
        require(isPublicMintActive || msg.sender == owner(), "Public minting is not active");
        return handleMint(count, recipient);
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
        return MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(addr)));
    }

    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Invalid token");
        require(_traitDataPointers[0].length > 0,  "Traits have not been added");

        string memory tokenHash = tokenIdToHash(tokenId);

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

    function tokenIdToSVG(uint tokenId)
        public
        view
        returns (string memory)
    {
        return hashToSVG(tokenIdToHash(tokenId));
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

    function addLayer(uint layerIndex, TraitDTO[] memory traits)
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

    function addTrait(uint layerIndex, uint traitIndex, TraitDTO memory trait)
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

    function setLinkedTraits(LinkedTraitDTO[] memory linkedTraits)
        public
        onlyOwner
        whenUnsealed
    {
        for (uint i = 0; i < linkedTraits.length; i++) {
            _linkedTraits[linkedTraits[i].traitA[0]][linkedTraits[i].traitA[1]] = [linkedTraits[i].traitB[0],linkedTraits[i].traitB[1]];
        }
    }

    function setContractData(ContractData memory data) external onlyOwner whenUnsealed {
        contractData = data;
    }

    function setMaxPerAddress(uint max) external onlyOwner {
        maxPerAddress = max;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setBackgroundColor(string memory color) external onlyOwner whenUnsealed {
        backgroundColor = color;
    }

    function setRenderOfTokenId(uint tokenId, bool renderOffChain) external {
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        _renderTokenOffChain[tokenId] = renderOffChain;
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

    function toggleAllowListMint() external onlyOwner {
        isAllowListActive = !isAllowListActive;
    }

    function toggleOperatorFilter() external onlyOwner {
        isOperatorFilterEnabled = !isOperatorFilterEnabled;
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
        uint amount = (balance * (10000 - DEVELOPER_FEE)) / 10000;
        uint distAmount = 0;
        uint totalDistributionPercentage = 0;

        address payable receiver = payable(owner());
        address payable dev = payable(0xEA208Da933C43857683C04BC76e3FD331D7bfdf7);
        Address.sendValue(dev, balance - amount);

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