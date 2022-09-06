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
        uint256 private constant NUM_LAYERS = 15;
        uint256 private constant MAX_BATCH_MINT = 20;
        uint256[][NUM_LAYERS] private TIERS;
        string[] private LAYER_NAMES = [unicode"1 of 1s", unicode"Hands", unicode"Accessory", unicode"SP Eyes", unicode"SP Mouth", unicode"SP Head", unicode"LL Eyes", unicode"LL Mouth", unicode"LL Head", unicode"Toadz Mouth", unicode"Toadz Eyes", unicode"Dick", unicode"Butt", unicode"Skin", unicode"Background"];
        bool private shouldWrapSVG = true;
        string private backgroundColor = "transparent";

        bool public isContractSealed;
        uint256 public constant maxSupply = 2777;
        uint256 public maxPerAddress = 10;
        uint256 public publicMintPrice = 0.020 ether;
        string public baseURI = "";
        bool public isPublicMintActive;
        
        bytes32 private merkleRoot;
        uint256 public allowListPrice = 0.0 ether;
        uint256 public maxPerAllowList = 1;
        bool public isAllowListActive;
        
        ContractData public contractData = ContractData(unicode"My Final Form", unicode"Restored back to its rightful utopia, Gooch Island has seen an influx of evil amphibious creatures occupying the desolate wasteland.  Dickbutt children are vanishing, PFP Police are searching, Larva Lads are worrying, Toadz are hiding and Stoneys are still smoking GAS.  Something shocking has been uncovered by a Phunky Civilian…  Below the PFP Police HQ on Gooch Island, Evil King Gremplin & The Gooch Army are experimenting and cross breeding Stoney Cryptoad Dickbutt Larva Phunks!  My Final Form is a collection of 2777 randomly generated, on-chain, experimental creatures uncovered by a Phunky Artist & his pot smoking friends.   MFF is in the public domain, MFFers can be used in any way imaginable just don’t show your children.  All MFFers face left for obvious reasons, they will remain on the right side of Web3 History!", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/542f3b94-058d-496d-9e4c-1b4c6afd9eb2", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/542f3b94-058d-496d-9e4c-1b4c6afd9eb2", "http://myfinalform.io/", 500, "0xbBc65012FFDBd902C9A80d652B8c1478f1880A0d");

        constructor() ERC721A(unicode"My Final Form", unicode"MFFers") {
            TIERS[0] = [1,1,1,1,1,1,1,1,1,1,1,2766];
TIERS[1] = [4,6,15,17,22,24,45,54,67,75,77,85,88,97,105,106,109,116,118,134,136,151,186,188,193,263,296];
TIERS[2] = [1,1,1,2,3,4,5,6,7,9,10,13,15,15,17,19,19,22,25,30,30,31,32,32,32,35,39,40,43,44,45,47,53,56,57,58,60,61,64,67,71,73,82,86,89,148,153,153,159,166,216,231];
TIERS[3] = [1,1,1,1,1,1,1,1,1,2,2,3,3,3,3,3,3,4,4,4,5,5,6,8,8,8,9,9,10,13,13,14,16,17,17,17,19,20,21,22,23,23,25,26,26,27,30,31,32,34,35,35,36,37,37,37,38,39,39,40,40,41,44,44,45,45,46,48,57,61,67,68,73,77,80,95,95,100,104,106,110,121,121,139];
TIERS[4] = [1,1,1,3,3,4,5,6,8,12,16,16,18,21,28,31,31,34,34,36,44,45,48,58,58,61,62,62,62,63,65,70,70,71,74,81,86,87,90,91,104,108,110,124,134,175,177,188];
TIERS[5] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5,5,5,6,6,7,7,7,8,8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11,11,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,14,14,14,14,14,14,15,15,15,15,15,15,16,16,16,17,17,17,17,17,18,18,18,18,19,19,19,20,21,21,21,21,23,23,23,23,23,24,24,24,24,25,25,26,27,27,27,28,29,29,29,29,29,31,32,32,32,33,34,38,39,41,42,44,45,46,49,51,51,51,62,66,72,74,75,75,83];
TIERS[6] = [1,1,1,1,2,2,3,3,3,3,3,3,5,5,6,7,9,9,10,10,11,12,13,14,14,15,18,18,19,19,19,20,21,21,22,22,23,24,26,29,29,31,32,32,33,33,33,34,34,35,36,37,37,37,38,39,39,39,42,43,44,45,46,47,47,48,50,52,55,56,57,59,67,79,87,91,92,98,105,110,120,142];
TIERS[7] = [1,2,2,2,3,3,5,5,6,6,8,8,9,10,12,17,18,18,18,20,28,38,41,42,43,47,48,50,55,56,59,62,64,66,68,84,84,87,89,97,114,116,121,125,132,169,177,209,233];
TIERS[8] = [1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,8,8,8,8,9,9,9,10,10,10,10,11,11,11,11,12,12,12,13,13,13,13,13,13,14,14,14,14,14,15,15,15,15,15,16,16,17,17,17,18,18,18,18,18,19,19,19,20,21,21,21,21,22,22,22,22,23,23,23,23,24,24,24,24,24,25,25,28,29,30,30,31,31,32,32,33,34,34,35,35,36,41,41,45,45,46,47,51,52,54,55,55,60,62,68,69,71,75,85];
TIERS[9] = [2,3,4,7,7,8,8,9,11,12,12,17,17,20,22,24,27,27,28,29,31,34,38,41,42,46,49,53,53,56,58,58,59,61,67,68,76,82,86,92,100,101,114,143,143,156,158,191,227];
TIERS[10] = [1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,5,6,8,8,8,9,9,9,11,11,11,12,12,13,13,14,14,15,16,18,18,20,23,23,24,24,25,26,27,28,29,30,30,30,30,30,30,31,31,32,32,33,33,34,35,36,37,39,42,43,44,45,46,48,48,51,53,53,54,55,55,59,70,74,82,90,99,116,130,154,186];
TIERS[11] = [5,13,21,23,36,42,44,45,73,91,94,95,97,101,109,123,126,128,143,1368];
TIERS[12] = [41,78,255,2403];
TIERS[13] = [3,5,7,9,10,11,12,14,15,17,18,19,24,26,28,31,34,37,42,43,43,46,47,48,54,57,59,59,62,63,63,63,64,65,67,79,87,104,105,149,151,155,156,167,171,188];
TIERS[14] = [1,2,3,3,5,5,7,8,10,13,13,13,17,26,30,37,38,39,40,41,42,42,49,52,53,57,59,63,64,65,66,66,88,92,94,104,115,124,135,142,149,193,238,274];
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

        function mint(uint64 _count, bytes32[] calldata merkleProof)
            external
            payable
            nonReentrant
            whenMintActive
            returns (uint256)
        {
            uint256 totalMinted = _totalMinted();
            require(_count > 0, "Invalid token count");
            require(totalMinted + _count <= maxSupply, "All tokens are gone");
            
            if (isPublicMintActive) {
                if (msg.sender != owner()) {
                    require(_numberMinted(msg.sender) + _count <= maxPerAddress, "Exceeded max mints allowed");
                }
                require(_count * publicMintPrice == msg.value, "Incorrect amount of ether sent");
            } else {
                if (msg.sender != owner()) {
                    require(onAllowList(msg.sender, merkleProof), "Not on allow list");
                    require(_numberMinted(msg.sender) + _count <= maxPerAllowList, "Exceeded max mints allowed");
                }
                require(_count * allowListPrice == msg.value, "Incorrect amount of ether sent");
            }
            

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
            return _totalMinted() < maxSupply && (isPublicMintActive || isAllowListActive);
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

        
        function onAllowList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
            return MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(addr)));
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
            jsonBytes.appendSafe(unicode"{\"name\":\"My Final Form #");

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

        
        function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
            merkleRoot = newMerkleRoot;
        }

        function setMaxPerAllowList(uint256 _maxPerAllowList) external onlyOwner {
            maxPerAllowList = _maxPerAllowList;
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
            uint256 balance = address(this).balance;
            uint256 amount = (balance * (10000 - DEVELOPER_FEE)) / 10000;
    
            address payable receiver = payable(owner());
            address payable dev = payable(0xEA208Da933C43857683C04BC76e3FD331D7bfdf7);
    
            Address.sendValue(receiver, amount);
            Address.sendValue(dev, balance - amount);
        }
    }