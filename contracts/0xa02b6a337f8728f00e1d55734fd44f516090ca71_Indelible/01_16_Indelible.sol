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
        string[] private LAYER_NAMES = [unicode"holding", unicode"Head", unicode"clothes", unicode"Glasses", unicode"cheeks", unicode"mouth", unicode"eyes", unicode"hands", unicode"shoes", unicode"Max", unicode"Max", unicode"pants", unicode"cape", unicode"rocket", unicode"toy"];
        bool private shouldWrapSVG = true;
        string private backgroundColor = "transparent";
        uint private randomSeedData;
            
        WithdrawRecipient[] public withdrawRecipients;
        bool public isContractSealed;
        uint public constant maxSupply = 888;
        uint public maxPerAddress = 3;
        uint public publicMintPrice = 0.003 ether;
        string public baseURI = "";
        bool public isPublicMintActive;
        bytes32 private merkleRoot = 0;
        uint public allowListPrice = 0 ether;
        uint public maxPerAllowList = 0;
        bool public isAllowListActive;

        ContractData public contractData = ContractData(unicode"max", unicode"Once upon a time.", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/7fd02338-51b8-490d-a8f5-88e2f64d3df0", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/7fd02338-51b8-490d-a8f5-88e2f64d3df0", "https://twitter.com/OnchainMax", 700, "0xe75699de99D2b9284F6B6e5eE7E36Ab6074a40c2");

        constructor() ERC721A(unicode"max", unicode"max") {
            TIERS[0] = [49,99,130,251,359];
            TIERS[1] = [16,18,37,43,47,50,93,117,135,332];
            TIERS[2] = [43,55,62,94,141,161,332];
            TIERS[3] = [67,77,136,143,219,246];
            TIERS[4] = [18,132,148,284,306];
            TIERS[5] = [47,142,156,257,286];
            TIERS[6] = [80,186,298,324];
            TIERS[7] = [20,269,599];
            TIERS[8] = [114,130,644];
            TIERS[9] = [888];
            TIERS[10] = [888];
            TIERS[11] = [20,868];
            TIERS[12] = [30,858];
            TIERS[13] = [30,858];
            TIERS[14] = [25,863];
            
            PRIME_NUMBERS = [
                135419986466399101724740108903015610477591324758987986294397,
                263743197985470588204349265269345001644610514897601719492623,
                795524184772701992168701409728225618620809563704319825349899,
                222880340296779472696004625829965490706697301235372335793669,
                239439210107002209100408342483681304951633794994177274881807,
                874778160644048956810394214801467472093537087897851981604983,
                192516593828483755313857340433869706973450072701701194101197,
                308043264033071943254647080990150144301849302687707544552767,
                435971530141217434414644657864363626485043834932240354294471,
                632927012893602565676075421341685619761332234876041339403653,
                197636338835913099229515612260127815566058069514897730698607,
                445730560699308616878100110185308606331080346485121531052089,
                691768493742031397614199039242108474419560046070176392220443,
                920701082264717957207933036509568484453068938413931146184577,
                455255148896994205943326626951197024927648464365329800703251
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
            jsonBytes.appendSafe(unicode"{\"name\":\"max #");

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