// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    import "erc721a/contracts/ERC721A.sol";
    import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/Base64.sol";
    import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
    import "@openzeppelin/contracts/utils/Address.sol";
    import "./SSTORE2.sol";
    import "./DynamicBuffer.sol";
    import "./HelperLib.sol";

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

        mapping(uint256 => address[]) internal _traitDataPointers;
        mapping(uint256 => mapping(uint256 => Trait)) internal _traitDetails;
        mapping(uint256 => bool) internal _renderTokenOffChain;

        uint256 private constant DEVELOPER_FEE = 250; // of 10,000 = 2.5%
        uint256 private constant NUM_LAYERS = 6;
        uint256 private constant MAX_BATCH_MINT = 20;
        uint256[][NUM_LAYERS] private TIERS;
        string[] private LAYER_NAMES = [unicode"Elites", unicode"Accessory", unicode"Emotion", unicode"Eyes", unicode"No Mad Type", unicode"Background"];
        bool private shouldWrapSVG = true;
        string private backgroundColor = "transparent";

        bool public isContractSealed;
        uint256 public constant maxSupply = 5000;
        uint256 public maxPerAddress = 1;
        uint256 public publicMintPrice = 0.000 ether;
        string public baseURI = "";
        bool public isPublicMintActive;
        
        ContractData public contractData = ContractData(unicode"No Mad Nomads", unicode"A collection of 5000 Nomads who are really definitely no mad about the Nomad Bridge exploit, all stored and generated on-chain at the time of mint.", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/b8a04739-d7a6-46aa-8f6d-c18b9bcb6372", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/b8a04739-d7a6-46aa-8f6d-c18b9bcb6372", "", 500, "0xbdAA031a00e51d4F1C5811eedB82F4B305d66753");

        constructor() ERC721A(unicode"No Mad Nomads", unicode"NOM") {
            TIERS[0] = [1,1,4998];
TIERS[1] = [5,10,25,25,25,69,100,125,125,125,150,150,150,200,250,250,250,300,400,400,666,1200];
TIERS[2] = [50,140,243,344,464,603,623,765,1768];
TIERS[3] = [98,111,443,461,496,688,832,1871];
TIERS[4] = [5,25,50,695,745,795,845,895,945];
TIERS[5] = [35,74,116,121,130,133,151,185,349,450,571,577,759,1349];
        }

        modifier whenMintActive() {
            require(isMintActive(), "Minting is not active");
            _;
        }

        modifier whenUnsealed() {
            require(!isContractSealed, "Contract is sealed");
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
        
        function entropyForExtraData() internal view returns (uint24) {
            uint256 randomNumber = uint256(
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
            address to,
            uint24 previousExtraData
        ) internal view virtual override returns (uint24) {
            return from == address(0) ? entropyForExtraData() : previousExtraData;
        }

        function getTokenSeed(uint256 _tokenId) internal view returns (uint24) {
            return _ownershipOf(_tokenId).extraData;
        }

        function tokenIdToHash(
            uint256 _tokenId
        ) public view returns (string memory) {
            require(_exists(_tokenId), "Invalid token");
            // This will generate a NUM_LAYERS * 3 character string.
            bytes memory hashBytes = DynamicBuffer.allocate(NUM_LAYERS * 4);

            for (uint256 i = 0; i < NUM_LAYERS; i++) {
                uint256 _randinput = uint256(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                getTokenSeed(_tokenId),
                                _tokenId,
                                _tokenId + i
                            )
                        )
                    ) % maxSupply
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

        function mint(uint64 _count)
            external
            payable
            nonReentrant
            whenMintActive
            returns (uint256)
        {
            uint256 totalMinted = _totalMinted();
            require(_count > 0, "Invalid token count");
            require(totalMinted + _count <= maxSupply, "All tokens are gone");
            
            if (msg.sender != owner()) {
                require(_numberMinted(msg.sender) + _count <= maxPerAddress, "Exceeded max mints allowed");
            }
            require(_count * publicMintPrice == msg.value, "Incorrect amount of ether sent");
            

            uint256 batchCount = _count / MAX_BATCH_MINT;
            uint256 remainder = _count % MAX_BATCH_MINT;

            for (uint256 i = 0; i < batchCount; i++) {
                _mint(msg.sender, MAX_BATCH_MINT);
            }

            if (remainder > 0) {
                _mint(msg.sender, remainder);
            }

            return totalMinted;
        }

        function isMintActive() public view returns (bool) {
            return _totalMinted() < maxSupply && isPublicMintActive;
        }

        function hashToSVG(string memory _hash)
            public
            view
            returns (string memory)
        {
            uint256 thisTraitIndex;
            
            bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
            svgBytes.appendSafe('<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-color:');
            svgBytes.appendSafe(
                abi.encodePacked(
                    backgroundColor,
                    ";background-image:url("
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
            jsonBytes.appendSafe(unicode"{\"name\":\"No Mad Nomads #");

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
            whenUnsealed
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
            whenUnsealed
        {
            _traitDetails[_layerIndex][_traitIndex] = Trait(trait.name, trait.mimetype);
            address[] memory dataPointers = _traitDataPointers[_layerIndex];
            dataPointers[_traitIndex] = SSTORE2.write(trait.data);
            _traitDataPointers[_layerIndex] = dataPointers;
            return;
        }

        function setContractData(ContractData memory _contractData) external onlyOwner whenUnsealed {
            contractData = _contractData;
        }

        function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
            maxPerAddress = _maxPerAddress;
        }

        function setBaseURI(string memory _baseURI) external onlyOwner {
            baseURI = _baseURI;
        }

        function setBackgroundColor(string memory _backgroundColor) external onlyOwner whenUnsealed {
            backgroundColor = _backgroundColor;
        }

        function setRenderOfTokenId(uint256 _tokenId, bool _renderOffChain) external {
            require(msg.sender == ownerOf(_tokenId), "Only the token owner can set the render method");
            _renderTokenOffChain[_tokenId] = _renderOffChain;
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
            uint256 balance = address(this).balance;
            uint256 amount = (balance * (10000 - DEVELOPER_FEE)) / 10000;
    
            address payable receiver = payable(owner());
            address payable dev = payable(0xEA208Da933C43857683C04BC76e3FD331D7bfdf7);
    
            Address.sendValue(receiver, amount);
            Address.sendValue(dev, balance - amount);
        }
    }