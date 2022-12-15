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
        947803185312051153680939138255132052147806649202034860102891,
        121937390920146269387636233026547222240097190277750874729107,
        197636338835913099229515612260127815566058069514897730698607,
        192516593828483755313857340433869706973450072701701194101197,
        239439210107002209100408342483681304951633794994177274881807,
        445730560699308616878100110185308606331080346485121531052089,
        931147417701026196725981216508189527323460133287836248716671,
        308043264033071943254647080990150144301849302687707544552767,
        823147169916224825307391528014949069340357622154256148689191,
        558377243318447014834550684808284827184942745775381187076631
    ];
    uint[][10] private tiers;
    string[] private layerNames = [unicode"ELITE", unicode"Undercover", unicode"Optics", unicode"Accessory", unicode"Jaw Plate Part Number", unicode"Audio Port Part Number", unicode"Frontal Guard Part Number", unicode"Class", unicode"Head", unicode"Background"];
    bool private shouldWrapSVG = true;
    string private backgroundColor = "transparent";
    uint private randomSeed;
    bytes32 private merkleRoot = 0;
    string private networkId = "1";

    bool public isContractSealed;
    uint public maxSupply = 3333;
    uint public maxPerAddress = 33;
    uint public publicMintPrice = 0.0033 ether;
    string public baseURI;
    bool public isPublicMintActive;
    uint public allowListPrice = 0 ether;
    uint public maxPerAllowList = 0;
    bool public isAllowListActive;

    ContractData public contractData = ContractData(unicode"The Gatekeepers", unicode"Humanity's last breath, an elite army of Android Phunks, The Gatekeepers. OnChain. CC0. Set 1000 years into the future. The constant surplus of new Ape communities popping up everyday has given rise to a new age. The Age of the Apes. Planet Earth is no longer controlled by humanity. The Apes are in power now. Everyday humanity's habitats are shrinking. Populations dwindling.    The remaining human civilizations have band together to utilize what appears to be their final available resources to deploy an Elite Army of Android Phunks, The Gatekeepers.  Function: Control access to remaining human civilizations, protect humanity at all costs. End Goal: Take back Planet Earth.   Will The Gatekeepers fail, or will they prevail?", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/ededb93d-230f-490f-90bc-41b87e8e7e90", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/ededb93d-230f-490f-90bc-41b87e8e7e90", "", 300, "0xD503B89b39E5d820399e94Ba6250b90fA22B9812");
    WithdrawRecipient[] public withdrawRecipients;

    constructor() ERC721A(unicode"The Gatekeepers", unicode"TGK") {
        tiers[0] = [1,1,1,1,1,1,1,1,1,1,1,1,1,3320];
        tiers[1] = [0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,2,3,3,4,4,4,5,6,7,43,47,52,3141];
        tiers[2] = [0,0,0,0,0,0,0,0,0,0,0,0,22,35,42,43,46,66,71,74,86,87,87,90,93,93,94,97,98,98,98,99,100,101,102,102,105,108,109,110,113,118,119,120,123,123,128,133];
        tiers[3] = [0,0,0,0,0,0,0,0,0,32,47,56,58,114,119,127,131,153,2496];
        tiers[4] = [0,0,0,0,0,0,0,0,0,0,143,149,172,175,177,185,188,188,191,191,191,192,193,194,195,196,197,216];
        tiers[5] = [0,0,0,0,0,0,0,0,89,94,97,153,160,164,169,170,172,172,173,174,175,176,186,195,199,200,206,209];
        tiers[6] = [0,0,0,0,0,0,0,0,96,108,114,119,121,121,121,122,123,123,124,125,126,126,126,126,126,127,127,127,127,128,128,130,130,131,131];
        tiers[7] = [0,0,0,0,0,0,0,0,91,92,298,381,388,426,534,544,579];
        tiers[8] = [0,1483,1850];
        tiers[9] = [0,657,783,928,965];
        withdrawRecipients.push(WithdrawRecipient(unicode"null",unicode"null", 0x2979897bc0Ea8B021bDBA07325A26b1DA26f8A1F, 5000));
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
        returns (string memory)
    {
        return string(SSTORE2.read(_traitDataPointers[layerIndex][traitIndex]));
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