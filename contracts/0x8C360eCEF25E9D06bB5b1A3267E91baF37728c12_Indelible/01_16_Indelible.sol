// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.13;

    import "erc721a/contracts/ERC721A.sol";
    import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/Base64.sol";
    import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
    import "@openzeppelin/contracts/utils/Address.sol";
    import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
    import "./SSTORE2.sol";
    import "./DynamicBuffer.sol";
    import "./HelperLib.sol";

    contract Indelible is ERC721A, DefaultOperatorFilterer, ReentrancyGuard, Ownable {
        using HelperLib for uint;
        using DynamicBuffer for bytes;

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

        mapping(uint => address[]) internal _traitDataPointers;
        mapping(uint => mapping(uint => Trait)) internal _traitDetails;
        mapping(uint => bool) internal _renderTokenOffChain;
        mapping(uint => mapping(uint => uint[])) internal _linkedTraits;

        uint[15] private PRIME_NUMBERS;
        uint private constant DEVELOPER_FEE = 250; // of 10,000 = 2.5%
        uint private constant NUM_LAYERS = 15;
        uint private constant MAX_BATCH_MINT = 20;
        uint[][NUM_LAYERS] private TIERS;
        string[] private LAYER_NAMES = [unicode"Species", unicode"Species", unicode"Elder", unicode"Lower Body", unicode"Lower Body", unicode"Upper Body", unicode"Upper Body", unicode"Mouth", unicode"Eyes", unicode"Outline", unicode"Amalgam", unicode"Amalgam", unicode"Amalgam", unicode"Weapon", unicode"Terrain"];
        bool private shouldWrapSVG = true;
        string private backgroundColor = "transparent";
        uint private randomSeedData;
            
        WithdrawRecipient[] public withdrawRecipients;
        bool public isContractSealed;
        uint public constant maxSupply = 2048;
        uint public maxPerAddress = 3;
        uint public publicMintPrice = 0.010 ether;
        string public baseURI = "";
        bool public isPublicMintActive;
        bytes32 private merkleRoot = 0;
        uint public allowListPrice = 0.005 ether;
        uint public maxPerAllowList = 1;
        bool public isAllowListActive;

        ContractData public contractData = ContractData(unicode"On Chain Shrooms", unicode"On Chain Mushrooms! Highly optimised, cleverly devised, Mushy collectibles. Fully on-chain artwork.", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/4150e49b-c04a-49e3-ba2d-2baed97797a3", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/4150e49b-c04a-49e3-ba2d-2baed97797a3", "projectrxnegade.com", 500, "0x40DF4dC41FC5DD7828B122cd2ad8f34EbDE86FD5");

        constructor() ERC721A(unicode"On Chain Shrooms", unicode"OCSHROOM") {
            TIERS[0] = [1,1,1,154,166,195,226,318,462,524];
            TIERS[1] = [0,0,0,0,0,0,0,0,0,0,2048];
            TIERS[2] = [0,0,0,0,0,0,0,0,0,0,2048];
            TIERS[3] = [55,62,75,78,88,97,98,111,117,122,144,155,162,164,167,175,178];
            TIERS[4] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2048];
            TIERS[5] = [56,56,56,63,65,78,78,87,89,94,96,99,108,109,115,122,123,126,137,138,153];
            TIERS[6] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2048];
            TIERS[7] = [18,33,94,116,117,118,127,167,228,266,275,489];
            TIERS[8] = [34,44,50,109,117,130,176,207,208,245,336,392];
            TIERS[9] = [2048];
            TIERS[10] = [25,42,189,229,366,591,606];
            TIERS[11] = [0,0,0,0,0,0,0,2048];
            TIERS[12] = [0,0,0,0,0,0,0,2048];
            TIERS[13] = [0,21,44,64,79,92,116,161,233,292,294,298,354];
            TIERS[14] = [242,248,249,435,436,438];
            
            PRIME_NUMBERS = [
                432534654635437988648695007417836862217547977730730769366091,
                935919214672529529254699379456068172547564622727740728385203,
                577511032852311313897393410587293046739400234012091068864039,
                445730560699308616878100110185308606331080346485121531052089,
                669537310232575125291855927056732103107921011363770145177603,
                455255148896994205943326626951197024927648464365329800703251,
                121937390920146269387636233026547222240097190277750874729107,
                472403938247917779491914836805248705545654463845719721031103,
                197636338835913099229515612260127815566058069514897730698607,
                489283222294688268987820540542047890674696745383853025932409,
                153761362786647109825322724558215431057092100535325989154943,
                668657002110143242634345628894400250523693660459153690697319,
                705837224857882411289814862085650030200947499818982762698831,
                222880340296779472696004625829965490706697301235372335793669,
                902136958511366894226891930366237266945146287574429473893339
            ];
            randomSeedData = uint(
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
            for (uint i = 0; i < TIERS[rarityTier].length; i++) {
                uint thisPercentage = TIERS[rarityTier][i];
                if (
                    randinput >= currentLowerBound &&
                    randinput < currentLowerBound + thisPercentage
                ) return i;
                currentLowerBound = currentLowerBound + thisPercentage;
            }

            revert();
        }
        
        function entropyForExtraData() internal view returns (uint24) {
            uint randomNumber = uint(
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
            return uint24(randomNumber);
        }
        
        function stringCompare(string memory a, string memory b) internal pure returns (bool) {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }

        function tokensAreDuplicates(uint tokenIdA, uint tokenIdB) public view returns (bool) {
            return stringCompare(
                tokenIdToHash(tokenIdA),
                tokenIdToHash(tokenIdB)
            );
        }
        
        function reRollDuplicate(
            uint tokenIdA,
            uint tokenIdB
        ) public whenUnsealed {
            require(tokensAreDuplicates(tokenIdA, tokenIdB), "All tokens must be duplicates");

            uint largerTokenId = tokenIdA > tokenIdB ? tokenIdA : tokenIdB;

            if (msg.sender != owner()) {
                require(msg.sender == ownerOf(largerTokenId), "Only the token owner or contract owner can re-roll");
            }
            
            _initializeOwnershipAt(largerTokenId);
            if (_exists(largerTokenId + 1)) {
                _initializeOwnershipAt(largerTokenId + 1);
            }

            _setExtraDataAt(largerTokenId, entropyForExtraData());
        }
        
        function _extraData(
            address from,
            address,
            uint24 previousExtraData
        ) internal view virtual override returns (uint24) {
            return from == address(0) ? 0 : previousExtraData;
        }

        function getTokenSeed(uint tokenId) internal view returns (uint24) {
            return _ownershipOf(tokenId).extraData;
        }

        function tokenIdToHash(
            uint tokenId
        ) public view returns (string memory) {
            require(_exists(tokenId), "Invalid token");
            // This will generate a NUM_LAYERS * 3 character string.
            bytes memory hashBytes = DynamicBuffer.allocate(NUM_LAYERS * 4);

            uint[] memory hash = new uint[](NUM_LAYERS);
            bool[] memory modifiedLayers = new bool[](NUM_LAYERS);
            uint traitSeed = randomSeedData % maxSupply;

            for (uint i = 0; i < NUM_LAYERS; i++) {
                uint traitIndex = hash[i];
                if (modifiedLayers[i] == false) {
                    uint tokenExtraData = getTokenSeed(tokenId);
                    uint traitRangePosition;
                    if (tokenExtraData == 0) {
                        traitRangePosition = ((tokenId + i + traitSeed) * PRIME_NUMBERS[i]) % maxSupply;
                    } else {
                        traitRangePosition = uint(
                            keccak256(
                                abi.encodePacked(
                                    tokenExtraData,
                                    tokenId,
                                    tokenId + i
                                )
                            )
                        ) % maxSupply;
                    }
    
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

        function handleMint(uint256 count, address recipient) internal whenMintActive returns (uint256) {
            uint256 totalMinted = _totalMinted();
            require(count > 0, "Invalid token count");
            require(totalMinted + count <= maxSupply, "All tokens are gone");

            if (isPublicMintActive) {
                if (msg.sender != owner()) {
                    require(_numberMinted(msg.sender) + count <= maxPerAddress, "Exceeded max mints allowed");
                    require(count * publicMintPrice == msg.value, "Incorrect amount of ether sent");
                }
                require(msg.sender == tx.origin, "EOAs only");
            }

            uint256 batchCount = count / MAX_BATCH_MINT;
            uint256 remainder = count % MAX_BATCH_MINT;

            for (uint256 i = 0; i < batchCount; i++) {
                _mint(recipient, MAX_BATCH_MINT);
            }

            if (remainder > 0) {
                _mint(recipient, remainder);
            }

            return totalMinted;
        }

        function mint(uint256 count, bytes32[] calldata merkleProof)
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

        function airdrop(uint256 count, address recipient)
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

            for (uint i = 0; i < NUM_LAYERS - 1; i++) {
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
            bool afterFirstTrait;

            for (uint i = 0; i < NUM_LAYERS; i++) {
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
                            LAYER_NAMES[i],
                            '","value":"',
                            _traitDetails[i][thisTraitIndex].name,
                            '"}'
                        )
                    );
                    if (afterFirstTrait == false) {
                        afterFirstTrait = true;
                    }
                }

                if (i == NUM_LAYERS - 1) {
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
            jsonBytes.appendSafe(unicode"{\"name\":\"On Chain Shrooms #");

            jsonBytes.appendSafe(
                abi.encodePacked(
                    _toString(tokenId),
                    "\",\"description\":\"",
                    contractData.description,
                    "\","
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
                        '&network=mainnet",'
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
                    jsonBytes.appendSafe(
                        abi.encodePacked(
                            '"svg_image_data":"',
                            svgString,
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
            require(TIERS[layerIndex].length == traits.length, "Traits size does not match tiers for this index");
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
            require(msg.sender == ownerOf(tokenId), "Only the token owner can set the render method");
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

        function transferFrom(address from, address to, uint256 tokenId)
            public
            payable
            override
            onlyAllowedOperator(from)
        {
            super.transferFrom(from, to, tokenId);
        }

        function safeTransferFrom(address from, address to, uint256 tokenId)
            public
            payable
            override
            onlyAllowedOperator(from)
        {
            super.safeTransferFrom(from, to, tokenId);
        }

        function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
            public
            payable
            override
            onlyAllowedOperator(from)
        {
            super.safeTransferFrom(from, to, tokenId, data);
        }
    }