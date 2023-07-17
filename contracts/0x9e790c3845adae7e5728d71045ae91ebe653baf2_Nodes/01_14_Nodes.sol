// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./AnonymiceLibrary.sol";

/// @custom:security-contact [email protected]
contract Nodes is ERC721A, Ownable {
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }

    // Mint enable
    bool public MINT_ENABLE = false;
    bool public PUBLIC_ENABLE = false;
    uint256 public START_BLOCK = 0;

    // Should be set with functions.
    string private p5Url;
    string private p5Integrity;
    string private pakoUrl;
    string private pakoIntegrity;
    string private imageUrl;
    string private imageUrlExtension;
    string private animationUrl;
    string private gzip;
    string private description;
    string private c;
    string private meta;

    string private constant traitType = "{\"trait_type\":\"";
    string private constant traitValue = "\",\"value\":\"";
    string private constant terminator = "\"}";
    uint8[11] private seq = [1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1];
    uint8[9] private costs = [0,3,4,0,5,3,4,0,5];
    uint8 private constant fuseCost = 2;
    uint private constant ONE_DAY = 86400; // in secs
    uint8 private constant TRAIT_COUNT = 5;
    uint8 private constant PADDED_TRAIT_COUNT = 2;
    uint256 private constant mult = 16807;
    uint256 private constant mod = 2147483647;

    uint private immutable TRAIT_TOKEN_EPOCH = ONE_DAY;
    uint private immutable FUSE_COOLDOWN = ONE_DAY * 3;
    uint private immutable PRICE;
    uint16 public immutable GENISIS_CAP;
    bytes32 public generalMerkleRoot;
    bytes32 public devMerkleRoot;
    uint16 public immutable FUSED_CAP;
    
    // n options per trait.
    uint16[][TRAIT_COUNT] private rarityTree;

    mapping(address => uint) private addrToMintedQ;
    mapping(address => uint) private addrToMintedP;
    mapping(string => bool) private hashToMinted;
    mapping(uint => string) private tokenIdToHash;
    mapping(uint => uint) private tokenIdToTimestamp;
    mapping(uint => uint) private tokenIdToCooldown;
    mapping(uint => uint) private tokenIdToSpent;
    mapping(uint => uint16) private tokenIdToSizeX;
    mapping(uint => uint16) private tokenIdToSizeY;
    mapping(uint256 => Trait[]) private traitTypes;
    mapping(address => uint) private lastWrite;

    // team mints
    uint8 public teamMints = 0;


    constructor(bytes32 _generalMerkleRoot, bytes32 _devMerkleRoot, uint16 genesisCap) ERC721A("NODES", "NODE", 12, genesisCap) {
        // Palette
        rarityTree[0] = [630, 450, 360, 270, 270, 100, 450, 360, 450, 450, 360, 270, 270, 360, 270, 360, 270, 360, 270, 540, 180, 270, 270, 270, 360, 360, 270, 450, 450];
        // Connectivity (N/R) - 1&2
        rarityTree[1] = [195, 388, 388, 388, 1553, 777, 777, 1942, 1165, 485, 388, 777, 777];
        // Node Size - 1&2
        rarityTree[2] = [2500, 2500, 5000];
        // Symmetry
        rarityTree[3] = [3334, 3333, 3333];
        // Node Type - 1&2
        rarityTree[4] = [1613, 645, 968, 1613, 1290, 968, 1290, 645, 645, 323];
        generalMerkleRoot = _generalMerkleRoot;
        devMerkleRoot = _devMerkleRoot;
        // price in Wei, this is 0.05 ETH.
        PRICE = 50000000000000000;
        GENISIS_CAP = genesisCap;
        FUSED_CAP = genesisCap * 2;
        imageUrlExtension = ".gif";
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier noContract() {
        require(!AnonymiceLibrary.isContract(msg.sender), "c0");
        _;
    }

    modifier disallowIfStateIsChanging() {
        // Do what you want in your own house, but guests should be nice
        require(owner() == msg.sender || lastWrite[msg.sender] < block.number, "no.");
        _;
    }

    /**
    ______  ___ _____ ___      ___   _______ _____    
    |  _  \/ _ \_   _/ _ \    / / | | | ___ \_   _|   
    | | | / /_\ \| |/ /_\ \  / /| | | | |_/ / | | ___ 
    | | | |  _  || ||  _  | / / | | | |    /  | |/ __|
    | |/ /| | | || || | | |/ /  | |_| | |\ \ _| |\__ \
    |___/ \_| |_/\_/\_| |_/_/    \___/\_| \_|\___/___/                                           
    */

    /**
     * @dev Hash to HTML function
     */
    function tokenHTML(uint256 tokenId)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        require(_exists(tokenId),"e0");
        return string(
            abi.encodePacked(
                headData(),
                tokenIdToHash[tokenId],
                "%27%3B%20const%20size%20%3D%20%5B",
                tokenIdToSizeX[tokenId] > 0 ? AnonymiceLibrary.toString(tokenIdToSizeX[tokenId]) : "500",
                "%2C",
                tokenIdToSizeY[tokenId] > 0 ? AnonymiceLibrary.toString(tokenIdToSizeY[tokenId]) : "500",
                "%5D%3B%20const%20g%20%3D%20%27",
                gzip,
                "%27%3B%20const%20e%20%3D%20Function(%27%22use%20strict%22%3Breturn%20(%27%20%2B%20pako.inflate(new%20Uint8Array(atob(g).split(%27%27).map(function(x)%7Breturn%20x.charCodeAt(0)%3B%20%7D))%2C%20%7B%20to%3A%20%27string%27%20%7D)%2B%20%27)%27)()%3B%20new%20p5(e.nodes%2C%20%27nodes%27)%3B%20%3C%2Fscript%3E%3Cdiv%20id%3D%22nodes%22%20name%3D%22nodes%22%3E%3C%2Fdiv%3E%3C%2Fbody%3E%3C%2Fhtml%3E"
            )
        );
    }

    function headData() private view returns (bytes memory) {
        return abi.encodePacked(
             "data:text/html,%3Chtml%3E%3Chead%3E",
                meta,
                "%3Cscript%20src%3D%22",
                p5Url,
                "%22%20integrity%3D%22",
                p5Integrity,
                "%22%20crossorigin%3D%22anonymous%22%20referrerpolicy%3D%22no-referrer%22%3E%3C%2Fscript%3E%3Cscript%20src%3D%22",
                pakoUrl,
                "%22%20integrity%3D%22",
                pakoIntegrity,
                "%22%20crossorigin%3D%22anonymous%22%20referrerpolicy%3D%22no-referrer%22%3E%3C%2Fscript%3E%3C%2Fhead%3E%3C%2Fbody%3E%3Cscript%3Econst%20h%20%3D%20%27"
        );
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        disallowIfStateIsChanging
        returns (string memory)
    {
        require(_exists(_tokenId), "e0");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    "{\"name\": \"NODES #",
                                    AnonymiceLibrary.toString(_tokenId),
                                    "\",\"description\": \"",
                                    description,
                                    "\",\"animation_url\": \"",
                                    bytes(animationUrl).length > 0 ? animationUrl : tokenHTML(_tokenId),
                                    bytes(animationUrl).length > 0 ? AnonymiceLibrary.toString(_tokenId) : "",
                                    "\",\"external_url\": \"",
                                    tokenHTML(_tokenId),
                                    "\",\"image\": \"",
                                    imageUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    imageUrlExtension,
                                    "\",\"attributes\": ",
                                    hashToMetadata(getTokenHash(_tokenId)),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
    ___  ________ _   _ _____ _____ _   _ _____ 
    |  \/  |_   _| \ | |_   _|_   _| \ | |  __ \
    | .  . | | | |  \| | | |   | | |  \| | |  \/
    | |\/| | | | | . ` | | |   | | | . ` | | __ 
    | |  | |_| |_| |\  | | |  _| |_| |\  | |_\ \
    \_|  |_/\___/\_| \_/ \_/  \___/\_| \_/\____/                                          
    */
    function mintNodes(uint256 quantity, bytes32[] calldata merkleProof) public payable noContract {
        require(msg.value >= PRICE * quantity,"m1");
        lastWrite[msg.sender] = block.number;
        mint(quantity, merkleProof, false); 
    }

    function mintNodesTeam(uint256 quantity, bytes32[] calldata merkleProof) public noContract {
        mint(quantity, merkleProof, true);
    }

    function mint(uint256 quantity, bytes32[] calldata merkleProof, bool isTeamMint) private {
        uint256 limit = isTeamMint ? 12 : 2;
        require((PUBLIC_ENABLE ? addrToMintedP[msg.sender] : addrToMintedQ[msg.sender]) + quantity <= limit, "m2");
        require((totalGenesisSupply() + quantity) <= GENISIS_CAP, "m3");
        require(MerkleProof.verify(merkleProof, isTeamMint ? devMerkleRoot : generalMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "m4");
        _safeMint(msg.sender, quantity);
        if(isTeamMint) {
            // accountability is good.
            teamMints += uint8(quantity);
            // make sure team can't mint more than our allotment during public mint.
            require(addrToMintedQ[msg.sender] + addrToMintedP[msg.sender] + quantity <= limit, "m6");
        } else {
            require(MINT_ENABLE == true, "m0");
            // Require that you have not minted before for further protection against flash bots.
            require((PUBLIC_ENABLE ? addrToMintedP[msg.sender] : addrToMintedQ[msg.sender]) == 0, "m5");
        }
        if(PUBLIC_ENABLE) {
            addrToMintedP[msg.sender] += quantity;
        } else {
            addrToMintedQ[msg.sender] += quantity;
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity,
        bytes memory data
    ) internal override {
        if(from == address(0)) {
            if(data.length > 0) {
                // THIS IS NOT A BATCH CAPABLE FUNCTION BECAUSE FUSING DOES NOT SUPPORT THIS
                require(quantity == 1, "btt0");
                tokenIdToHash[startTokenId] = string(data);
            } else {
                // This is batch capabable.
                string memory hashi = hash(startTokenId, to, uint8(quantity));
                for(uint i = 0; i < quantity; i++) {
                    tokenIdToHash[startTokenId + i] = string(abi.encodePacked("00", AnonymiceLibrary.substring(hashi, 0 + i*12, 12 + i*12)));
                }
            }
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
      // Nuke token counters
      for(uint i = 0; i < quantity; i++) {
          tokenIdToTimestamp[startTokenId + i] = block.timestamp;
          tokenIdToCooldown[startTokenId + i] = block.timestamp + FUSE_COOLDOWN;
          delete tokenIdToSpent[startTokenId + i];
          delete tokenIdToSizeX[startTokenId + i];
          delete tokenIdToSizeY[startTokenId + i];
      }
    }

    /**
    ______ _   _ _____ _____ _   _ _____ 
    |  ___| | | /  ___|_   _| \ | |  __ \
    | |_  | | | \ `--.  | | |  \| | |  \/
    |  _| | | | |`--. \ | | | . ` | | __ 
    | |   | |_| /\__/ /_| |_| |\  | |_\ \
    \_|    \___/\____/ \___/\_| \_/\____/
    */
    function fuse(
        uint256 tokenId0,
        uint256 tokenId1,
        int8[9] memory phenotype,
        uint256 tokenCostPreference
    ) public noContract {
        require(MINT_ENABLE);
        require(ownerOf(tokenId0) == msg.sender && ownerOf(tokenId1) == msg.sender, "f1");
        require(tokenId0 != tokenId1, "f2");
        require(getRemainingCooldown(tokenId0) == 0 && getRemainingCooldown(tokenId1) == 0, "f3");
        string memory h1 = getTokenHash(tokenId0);
        string memory h2 = getTokenHash(tokenId1);

        // Phenotype = [0,1,0,...,1]
        //           = [p1,p2,p1,...,p2]]
        string memory out;
        uint8 curr = 2;
        uint8 cost = fuseCost;

        for(uint8 i = 0; i < phenotype.length; i++) { 
            if(phenotype[i] == -2) {
                out = string(abi.encodePacked(out, AnonymiceLibrary.substring(h1, curr, curr + seq[i + 2])));
            } else if(phenotype[i] == -1) {
                out = string(abi.encodePacked(out, AnonymiceLibrary.substring(h2, curr, curr + seq[i + 2])));
            } else {
                // you cannot set 0 color, 3 sym1, 7 sym2
                require(phenotype[i] >= 0 && i != 0 && i != 3 && i != 7, "f4");
                // 0, 1, 2, 3, 4, 1, 2, 3, 4
                // safe to convert to unsigned type as we already checked bounds above.
                require(uint8(phenotype[i]) < rarityTree[i < 5 ? i : i - 4].length, "f5");
                cost += costs[i];
                uint8 rar = uint8(phenotype[i]);
                out = string(
                    abi.encodePacked(out, string(abi.encodePacked((rar <= 9 && seq[i+2] == 2) ? "0" : "", rar.toString())))
                );
            }
            curr += seq[i+2];
        }

        uint256 bal0 = getTraitTokenBalance(tokenId0);
        uint256 bal1 = getTraitTokenBalance(tokenId1);
        uint256 t0spend;
        uint256 t1spend;
        require(bal0 + bal1 >= uint256(cost), "f6");
        if(tokenCostPreference == tokenId0) {
            t0spend = cost > bal0 ? bal0 : cost;
            t1spend = cost > t0spend ? cost - t0spend : 0;
        } else {
            t1spend = cost > bal1 ? bal1 : cost;
            t0spend = cost > t1spend ? cost - t1spend : 0;
        }
        tokenIdToSpent[tokenId0] += t0spend;
        tokenIdToSpent[tokenId1] += t1spend;
        _safeMint(msg.sender, 1, abi.encodePacked("01", out));
        burnIfFused(tokenId0, h1);
        burnIfFused(tokenId1, h2);
        // It would be much better if this could fail fast.
        require(totalChildSupply() <= FUSED_CAP, "f7");
    }

    function burnIfFused(uint256 tokenId, string memory h1) private {
        if(AnonymiceLibrary.parseInt(AnonymiceLibrary.substring(h1, 1, 2)) != 0) {
            safeTransferFrom(msg.sender, address(0xdead), tokenId);
            // Pieces that are sacrificed through fusing will have their art updated.
            tokenIdToHash[tokenId] = string(abi.encodePacked("1",AnonymiceLibrary.substring(h1, 1, bytes(h1).length)));
            burn();
            // cooldown happens via transfer, also it doesn't matter since its dead.
        } else {
            tokenIdToCooldown[tokenId] = block.timestamp + FUSE_COOLDOWN;
        }
    }


    /**
    ______           _ _       _____             
    | ___ \         (_) |     |_   _|            
    | |_/ /__ _ _ __ _| |_ _   _| |_ __ ___  ___ 
    |    // _` | '__| | __| | | | | '__/ _ \/ _ \
    | |\ \ (_| | |  | | |_| |_| | | | |  __/  __/
    \_| \_\__,_|_|  |_|\__|\__, \_/_|  \___|\___|
                            __/ |                
                            |___/                    
    */

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        private
        view
        returns (uint8)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < rarityTree[_rarityTier].length; i++) {
            uint16 thisPercentage = rarityTree[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }
        revert("r1");
    }

    /**
     * @dev Generates a 12*q digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint8 q
    ) private returns (string memory) {
        string memory currentHash;
        string memory out;
        uint8 draws = 0;
        uint8 selected = 0;
        // You MUST NOT hash changing attributes like block.timestamp if you haven't thought about flash bot protection.
        uint256 seed =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            c
                        )
                    )
                ) % 123456789;
        // This is a robust uniform random algo which is only slightly less random than Math.random().
        uint256 x = (seed * mult + 1) % mod;
        do {
            for (uint8 i = 0; i < TRAIT_COUNT; i++) {
                uint16 _randinput = uint16(x % 10000);
                x = (x * mult + 1) % mod;
                uint8 rar = rarityGen(_randinput, i);
                currentHash = string(
                    abi.encodePacked(currentHash, string(abi.encodePacked((rar <= 9 && i <= 1) ? "0" : "", rar.toString())))
                );
            }

            if(!hashToMinted[currentHash]) {
                selected++;
                hashToMinted[currentHash] = true;
                // Set the secondary hash for fusing.
                uint8 offset = 2;
                out = string(
                    abi.encodePacked(out, currentHash, AnonymiceLibrary.substring(currentHash, offset, TRAIT_COUNT + offset))
                );
            }
            currentHash = "";
            draws++;
            if(draws >= q*2) {
                revert("h1");
            }
        } while (selected < q);

        return out;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        private
        view
        returns (string memory)
    {
        uint8 curr = 0;
        uint8 idx = 0;
        string memory metadataString;
        for(uint8 i = 0; i < seq.length; i++) {
            idx = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, curr, curr + seq[i])
            );
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    traitType,
                    abi.encodePacked(traitTypes[i > 6 ? i - 4 : i][idx].traitType, i > 6 ? "2" : ""),
                    traitValue,
                    traitTypes[i > 6 ? i - 4 : i][idx].traitName,
                    terminator,
                    i < seq.length-1 ? "," : ""
                )
            );
            curr += seq[i];
        }
        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     _____      _   _              _______      _   _            
    |  __ \    | | | |            / /  ___|    | | | |           
    | |  \/ ___| |_| |_ ___ _ __ / /\ `--.  ___| |_| |_ ___ _ __ 
    | | __ / _ \ __| __/ _ \ '__/ /  `--. \/ _ \ __| __/ _ \ '__|
    | |_\ \  __/ |_| ||  __/ | / /  /\__/ /  __/ |_| ||  __/ |   
    \____/\___|\__|\__\___|_|/_/   \____/ \___|\__|\__\___|_|                                                        
    */

    /**
     * @dev Toggles minting, so it can be start/stopped by the contract owner.
     */
    function toggleMint() public onlyOwner {
        MINT_ENABLE = !MINT_ENABLE;
        if(START_BLOCK == 0) {
            START_BLOCK = block.number;
        }
    }

    /**
     * @dev Toggles minting, so it can be start/stopped by the contract owner.
     */
    function togglePublic() public onlyOwner {
        PUBLIC_ENABLE = !PUBLIC_ENABLE;
    }

    function getTraitTokenBalance(uint256 tokenId) public view returns(uint) {
        require(_exists(tokenId), "e0");
        return ((block.timestamp - tokenIdToTimestamp[tokenId]) / TRAIT_TOKEN_EPOCH) - tokenIdToSpent[tokenId];
    }

    function getRemainingCooldown(uint256 tokenId) public view returns (uint) {
        require(_exists(tokenId), "e0");
        return block.timestamp > tokenIdToCooldown[tokenId] ? 0 : tokenIdToCooldown[tokenId] - block.timestamp;
    }

    /**
     * @dev Gets the hash for an existing token.
     */
    function getTokenHash(uint256 tokenId) public view disallowIfStateIsChanging returns (string memory)  {
        require(_exists(tokenId), "e0");
        return tokenIdToHash[tokenId];
    }

    /**
     * @dev returns the size of the token as javscript list.
     */ 
    function getTokenSize(uint tokenId) public view disallowIfStateIsChanging returns (string memory) {
        require(_exists(tokenId), "e0");
        return string(
                abi.encodePacked(
                    "[",
                    tokenIdToSizeX[tokenId],
                    ",",
                    tokenIdToSizeY[tokenId],
                    "]"
                )
            );
    }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */
    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        delete traitTypes[_traitTypeIndex];
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType
                )
            );
        }
        return;
    }

    function setSizeForTokenId(uint256 tokenId, uint16 xInPixels, uint16 yInPixels) public {
        require(ownerOf(tokenId) == msg.sender, "s0");
        if(xInPixels > 0 && xInPixels <= 5000 && yInPixels > 0 && yInPixels <= 5000) {
            tokenIdToSizeX[tokenId] = xInPixels;
            tokenIdToSizeY[tokenId] = yInPixels;
        } else {
            revert("s1");
        }
    }

    /**
     * @dev Sets the meta tag for the page.
     * @param _meta the meta tag contents.
     */
    function setMeta(string memory _meta) public onlyOwner {
        meta = _meta;
    }

    /**
     * @dev Sets the p5.js mirroring URL - this can be changed if cloudflare ever disappears.
     * @param _p5Url The address of the p5.js file hosted on CDN (URL encoded).
     */

    function setp5Address(string memory _p5Url) public onlyOwner {
        p5Url = _p5Url;
    }

    /**
     * @dev Sets the SHA-512 hash of the p5.js library hosted on the CDN.
     * @param _p5Integrity The SHA-512 Hash of the p5.js library.
     */
    function setp5Integrity(string memory _p5Integrity) public onlyOwner {
        p5Integrity = _p5Integrity;
    }

    /**
     * @dev Sets the pako.js mirroring URL - this can be changed if cloudflare ever disappears.
     * @param _pakoUrl The address of the p5.js file hosted on CDN (URL encoded).
     */

    function setPakoAddress(string memory _pakoUrl) public onlyOwner {
        pakoUrl = _pakoUrl;
    }

    /**
     * @dev Sets the SHA-512 hash of the p5.js library hosted on the CDN.
     * @param _pakoIntegrity The SHA-512 Hash of the p5.js library.
     */
    function setPakoIntegrity(string memory _pakoIntegrity) public onlyOwner {
        pakoIntegrity = _pakoIntegrity;
    }

    /**
     * @dev Sets the B64 encoded Gzipped source string for HTML mirroring.
     * @param _b64Gzip the B64 encoded Gzipped source string for HTML mirroring.
     */
    function setGzipSource(string memory _b64Gzip) public onlyOwner {
        gzip = _b64Gzip;
    }
    
    /**
     * @dev Sets the base image url, this will be the Nodes API, and can be replaced by a static IPFS resource
     * after mint, so the API can be retired.
     * @param _imageUrl The URL of the image API or the IPFS static resource (URL encoded).
     */
    function setImageUrl(string memory _imageUrl) public onlyOwner {
        imageUrl = _imageUrl;
    }

    /**
    * @dev Set the image type extension on the base image url. We'd like to use webp if openSea will let us.
    */
    function setImageUrlExtension(string memory _imageUrlExtension) public onlyOwner {
        imageUrlExtension = _imageUrlExtension;
    }
    
    /**
     * @dev Sets the base animation url, this will be an IPFS hosted version of the API to render the Nodes
     * artwork without needing to hit the mirrored HTML endpoint which OpenSea can't do yet.
     * @param _animationUrl The URL of the Nodes viewer hosted on IPFS.
     */
    function setAnimationUrl(string memory _animationUrl) public onlyOwner {
        animationUrl = _animationUrl;
    }

    /**
     * @dev Sets the description returned in the tokenURI.
     */
    function setDescription(string memory _description) public onlyOwner {
        description = _description;
    }

    /**
     * @dev Clears all set traits. Note these can also just be overwritten since its tied to a mapping.
     */
    function clearTraits() public onlyOwner {
        for (uint8 i = 0; i < TRAIT_COUNT+2; i++) {
            delete traitTypes[i];
        }
    }

    /**
     * @dev Sets the general and team merkle roots.
     */
    function setMerkelRoots(bytes32 _generalMerkleRoot, bytes32 _devMerkleRoot) public onlyOwner {
        generalMerkleRoot = _generalMerkleRoot;
        devMerkleRoot = _devMerkleRoot;
    }

    /**
     * @dev lever.
     */
    function setC(string memory _c) public onlyOwner {
        c = _c;
    }

    /**
     * Pays the team for their hard work.
     */
    function payTheDevs() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }
}