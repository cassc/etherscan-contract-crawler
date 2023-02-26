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
    bytes32 private constant TIER_2_MERKLE_ROOT = 0xe51d10d26260018969950c09110ebb10e32bb65eea784e20f50f222401563af9;

    uint[] private primeNumbers = [
        632927012893602565676075421341685619761332234876041339403653,
        902136958511366894226891930366237266945146287574429473893339,
        935919214672529529254699379456068172547564622727740728385203,
        866501304270831567510395669193811165643415673825427226954301,
        320078828389115961650782679700072873328499789823998523466099,
        453527291597583301312871432965621697728679882118473108149993,
        795524184772701992168701409728225618620809563704319825349899,
        432534654635437988648695007417836862217547977730730769366091,
        233798546572035042606454030173068619364505814127183530498703,
        947803185312051153680939138255132052147806649202034860102891
    ];
    uint[][10] private tiers;
    string[] private layerNames = [unicode"The Boldest Ones", unicode"Grifters", unicode"Nose", unicode"Eyes", unicode"Mouth", unicode"Face", unicode"Top", unicode"Clothes", unicode"Body", unicode"Background"];
    bool private shouldWrapSVG = true;
    string private backgroundColor = "transparent";
    uint private randomSeed;
    bytes32 private merkleRoot = 0xe51d10d26260018969950c09110ebb10e32bb65eea784e20f50f222401563af9;
    string private networkId = "1";
    string private placeholderImage = "https://files.indelible.xyz/placeholder/682fb9ae-6703-46ad-8521-85defc92a8ec";

    bool public isContractSealed;
    uint public maxSupply = 2034;
    uint public maxPerAddress = 1;
    uint public publicMintPrice = 0.0123 ether;
    string public baseURI;
    bool public isPublicMintActive;
    uint public allowListPrice = 0 ether;
    uint public maxPerAllowList = 0;
    bool public isAllowListActive;

    ContractData public contractData = ContractData(unicode"The Bold Ones", unicode"This collection is a tribute to the trailblazers who came before me. The ones who dared to be different, who pushed the boundaries of what was possible and created art on the blockchain. The pioneers who championed decentralization through CC0 art and collections. To those bold ones I say, thank you. Your courage and determination have inspired me to be daring and bold, to chase after my own dreams, and to encourage others to do the same. The Bold Ones are the ones who defy conventions, who conquer obstacles, who aren't afraid to make mistakes, because they learn from them. They forge their own path, they blaze their own trail. They are the mavericks, the rebels, the outliers, the punks and the mfers.  In short, The Bold Ones are the people who are not afraid to think outside the box and challenge the status quo in order to improve humanity and our technology. They are the ones who will shape the future of our world. Are you one of the Bold Ones? Join me in this collection and let's push the limits together, let's be daring and bold together, let's be part of the Bold Ones.  Are you a Bold One.  No Roadmap. Just Vibes. CC0", "https://files.indelible.xyz/profile/682fb9ae-6703-46ad-8521-85defc92a8ec", "https://files.indelible.xyz/banner/682fb9ae-6703-46ad-8521-85defc92a8ec", "", 500, "0x5f81f6FB766d40Ceb7111FB1Eaa5c2632A617804");
    WithdrawRecipient[] public withdrawRecipients;

    constructor() ERC721A(unicode"The Bold Ones", unicode"Bold") {
        tiers[0] = [1999,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
        tiers[1] = [1964,30,20,20,0];
        tiers[2] = [384,270,270,152,94,83,83,79,71,70,60,58,56,51,46,38,34,31,29,23,21,12,12,5,2,0];
        tiers[3] = [151,117,115,100,85,81,80,80,80,80,60,57,55,55,50,50,45,44,44,43,40,36,33,31,31,30,30,30,27,27,25,25,23,23,23,20,20,18,16,16,16,10,6,4,2,0];
        tiers[4] = [195,149,128,125,101,93,92,74,70,67,65,65,62,61,60,60,55,50,45,45,44,44,40,30,28,28,25,24,24,20,14,10,9,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0];
        tiers[5] = [273,150,130,110,100,90,72,70,64,47,40,33,33,32,26,25,25,23,21,20,20,20,18,18,15,15,12,12,12,12,12,12,12,12,11,11,11,11,10,10,10,9,9,9,9,9,9,9,9,9,9,9,9,8,7,7,7,7,7,7,6,6,6,6,6,6,6,6,6,6,6,6,5,5,5,5,5,5,5,5,5,5,4,4,4,4,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        tiers[6] = [67,60,60,55,50,50,47,45,45,45,44,44,40,38,38,36,35,35,35,34,34,33,33,33,31,31,30,30,30,30,29,29,29,28,28,27,26,25,25,25,25,24,24,22,20,20,19,18,16,15,15,15,15,15,15,12,12,11,10,10,10,10,10,10,10,7,6,6,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,4,4,4,4,4,3,2,2,2,2,2,0,0];
        tiers[7] = [324,290,270,160,150,90,90,80,70,70,50,50,50,50,50,30,30,30,20,20,20,20,20,0];
        tiers[8] = [208,208,208,208,208,180,180,180,180,180,30,24,23,17,0];
        tiers[9] = [201,145,99,90,80,75,75,72,60,60,60,60,55,50,50,50,50,42,42,41,40,40,40,33,32,31,30,30,29,25,20,20,20,20,20,20,20,15,11,10,10,10,10,10,9,7,5,5,5,0];
        
        
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
        bool shouldCheckProHolder = ((count * publicMintPrice) + (count * COLLECTOR_FEE)) != msg.value;

        if (isPublicMintActive) {
            if (msg.sender != owner()) {
                if (shouldCheckProHolder) {
                    require(!checkProHolder(msg.sender), "Missing collector's fee.");
                }
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
            bool shouldCheckProHolder = ((count * publicMintPrice) + (count * COLLECTOR_FEE)) != msg.value;
            if (shouldCheckProHolder) {
                require(!checkProHolder(msg.sender), "Missing collector's fee.");
            }
            require(onAllowList(msg.sender, merkleProof), "Not on allow list");
            require(_numberMinted(msg.sender) + count <= maxPerAllowList, "Exceeded max mints allowed");
            require(count * allowListPrice == msg.value, "Incorrect amount of ether sent");
        }
        handleMint(count, msg.sender);
    }

    function checkProHolder(address collector) public view returns (bool) {
        IIndeliblePro proContract = IIndeliblePro(0xf3DAEb3772B00dFB3BBb1Ad4fB3494ea6b9Be4fE);
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

        for (uint i = 0; i < recipients.length - 1; i++) {
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
    }

    function setBackgroundColor(string calldata color) external onlyOwner whenUnsealed {
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