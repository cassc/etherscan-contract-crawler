// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBallerBars.sol";
import "./ChainsLibrary.sol";

contract Chains is ERC721Enumerable, Ownable {

    using ChainsLibrary for uint8;
    using ECDSA for bytes32;

    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }
    
    // Price
    uint256 public price = 0.05 ether;

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;
    mapping(uint256 => uint256) internal tokenIdToTimestamp;
    mapping(uint256 => uint256) internal tokenIdToRarityCount;

    //uint256s
    uint256 public MAX_SUPPLY = 6000;
    uint256 public MAX_PER_MINT = 5;
    uint256 public MAX_MINTS_FOR_ETHER = 2000;
    uint256 SEED_NONCE = 0;

    //string arrays
    string[] LETTERS = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    //uint arrays
    uint16[][8] TIERS;

    //address
    address ballerbarsAddress;
    address _owner;

    uint256 public privateAmountMinted;
    bool public saleLive;

    mapping(string => bool) private _usedNonces;

    address private _artistAddress = 0x695652942cD5bE0Fe488645974dF15c3782fd552; 
    address private _signerAddress = 0xCBf2a728bDFDb683573a88E1c359FE892f9De049;   
    
    
    constructor() ERC721("Chains", "CHAIN") {
        _owner = msg.sender;

        //Declare all the rarity tiers

        //Clairty (1) <= 2
        TIERS[0] = [50, 450, 2000, 3000, 4500];

        //Gem (2) <= 2
        TIERS[1] = [50, 100, 750, 1000, 1100, 1200, 1300, 1400, 1500, 1600];

        //Chain Gems (3) <= 3
        TIERS[2] = [50, 100, 200, 800, 1100, 1200, 1300, 1450, 1650, 2150]; 

        //Chain (4) rares <= 3
        TIERS[3] = [50, 100, 400, 1450, 1700, 1900, 2100, 2300];

        //Watermark (5) <= 7
        TIERS[4] = [50, 100, 200, 200, 200, 300, 500, 8450];

        //Background (6) <= 7     
        TIERS[5] = [50, 100, 200, 200, 200, 300, 500, 8450];

    }

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 tokenId, uint256 _randinput, uint8 _rarityTier)
        internal
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) {
                if (
                    ( _rarityTier == 0 && i <= 2 ) ||
                    ( _rarityTier == 1 && i <= 2 ) ||
                    ( _rarityTier == 2 && i <= 3 ) || 
                    ( _rarityTier == 3 && i <= 3 ) || 
                    ( _rarityTier == 4 && i <= 7 ) || 
                    ( _rarityTier == 5 && i <= 7 )
                ) {
                    tokenIdToRarityCount[tokenId] += 1; 
                }
                return i.toString();
            }
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @dev Generates a 7 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.     
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate a 7 character string.
        // The last 6 digits are random, the first is 0, due to the chain is not being burned.

        string memory currentHash = "0";

        for (uint8 i = 0; i < 6; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_t, _randinput, i))
            );
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }

    /**
     * @dev Returns the current baller bar cost of a mint.
     */

    function currentBallerBarsCost() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply <= 3000)
            return 4 ether;
        if (_totalSupply > 3000 && _totalSupply <= 4000)
            return 8 ether;
        if (_totalSupply > 4000 && _totalSupply <= 5000)
            return 16 ether;

        return 24 ether;
    }

    /**
     * @dev Changes the price
     */
    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
    
    function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
          bytes32 signerHash = keccak256(abi.encodePacked(sender, qty, nonce));
          return signerHash;
    }
    
    function matchAddresSigner(bytes32 signerHash, bytes memory signature) private view returns(bool) {
        return _signerAddress == signerHash.toEthSignedMessageHash().recover(signature);
    }    
    
    function buy(bytes32 signerHash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");

        require(matchAddresSigner(signerHash, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(hashTransaction(msg.sender, tokenQuantity, nonce) == signerHash, "HASH_FAIL");

        
        require(totalSupply() <= MAX_MINTS_FOR_ETHER, "OUT_OF_STOCK_FOR_ETHER");
        require(tokenQuantity <= MAX_PER_MINT, "EXCEED_PER_MINT");

        require(price * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
             mintInternal();
        }
        
        _usedNonces[nonce] = true;
    }


    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!ChainsLibrary.isContract(msg.sender));

        uint256 thisTokenId = _totalSupply;

        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);

        hashToMinted[tokenIdToHash[thisTokenId]] = true;

        tokenIdToTimestamp[thisTokenId] = block.timestamp;

        _mint(msg.sender, thisTokenId);
    }
    
    
    function mintReserve(uint256 tokenQuantity) onlyOwner external  {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            require(totalSupply() < 35); // Reserved for teams and giveaways
            mintInternal();
        }
    }

    /**
     * @dev Mint for BallerBars
     */
    function mintChainWithToken(uint256 tokenQuantity) public {        
        //Burn this much baller bars
        require(totalSupply() >= MAX_MINTS_FOR_ETHER, "minting with BBs is only allowed when the first 2k is minted" );
        
        require(tokenQuantity <= MAX_PER_MINT, "EXCEED_PER_MINT");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            IBallerBars(ballerbarsAddress).burnFrom(msg.sender, currentBallerBarsCost());
            mintInternal();
        }
    }

    /**
     * @dev Burns and mints new.
     * @param _tokenId The token to burn.
     */
    function burnForMint(uint256 _tokenId) public {
        require(totalSupply() >= MAX_MINTS_FOR_ETHER, "Burning is only allowed when the first 2k is minted" );

        require(ownerOf(_tokenId) == msg.sender);

        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        mintInternal();
    }


    function withdraw() external onlyOwner {
        payable(_artistAddress).transfer(address(this).balance / 10);
        payable(msg.sender).transfer(address(this).balance);
    }


    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(string memory _inputLetter)
        internal
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i + 1);
        }
        revert();
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory svgString;
        
        string memory bgString;
        string memory bgColor;
        // 

        bool[24][24] memory placedPixels;

        uint8 bgIndex =  ChainsLibrary.parseInt(ChainsLibrary.substring(_hash, 6, 7)); // BG 

        if ( bgIndex == 0 ) {
            bgColor = "2596be";
        } else if ( bgIndex == 1 ) {
            bgColor = "10447c";
        } else if ( bgIndex == 2 ) {
            bgColor = "c8fcfc";
        } else if ( bgIndex == 3 ) {
            bgColor = "383434";
        } else if ( bgIndex == 4 ) {
            bgColor = "ffe4bc";
        } else if ( bgIndex == 5 ) {
            bgColor = "d0ccfc";
        }else if ( bgIndex == 6 ) {
            bgColor = "e0dcdc";
        } 
        
        if ( bgIndex < 7 ) { // bg color 7 is none 
            bgString = string(
                    abi.encodePacked(
                        'style="background-color:#',
                        bgColor,
                        '" '                        
                    )
                );
        } else {
            bgString = "";
        }
        

        for (uint8 i = 0; i < 6; i++) {  // 7 (we should skip BG here, so 6 will be final)
            uint8 thisTraitIndex = ChainsLibrary.parseInt(
                ChainsLibrary.substring(_hash, i, i + 1)
            );

            for (
                uint16 j = 0;
                j < traitTypes[i][thisTraitIndex].pixelCount; // <
                j++
            ) {
                string memory thisPixel = ChainsLibrary.substring(
                    traitTypes[i][thisTraitIndex].pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = letterToNumber(
                    ChainsLibrary.substring(thisPixel, 0, 1)
                );
                uint8 y = letterToNumber(
                    ChainsLibrary.substring(thisPixel, 1, 2)
                );

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        ChainsLibrary.substring(thisPixel, 2, 4),
                        "' x='",
                        x.toString(),
                        "' y='",
                        y.toString(),
                        "'/>"
                    )
                );

                placedPixels[x][y] = true;
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="c" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 26 26" ',bgString,' > ',
                svgString,
                "<style>rect{width:1px;height:1px;}#c{shape-rendering: crispedges;}.c00{fill:#d844cf}.c01{fill:#f1f1f1}.c02{fill:#ff4b54}.c03{fill:#ff6b71}.c04{fill:#ff5c64}.c05{fill:#ff132f}.c06{fill:#ff4651}.c07{fill:#ff444f}.c08{fill:#ff3644}.c09{fill:#ff3543}.c10{fill:#ff3845}.c11{fill:#ff4d57}.c12{fill:#c146fb}.c13{fill:#333aff}.c14{fill:#c2defc}.c15{fill:#eaf4ff}.c16{fill:#e3eefa}.c17{fill:#cfe4fa}.c18{fill:#b61ffc}.c19{fill:#bf42fb}.c20{fill:#bc35fb}.c21{fill:#bd36fb}.c22{fill:#fee4bf}.c23{fill:#ff8800}.c24{fill:#ffd300}.c25{fill:#ffc200}.c26{fill:#ff9a00}.c27{fill:#ffb100}.c28{fill:#ffa000}.c29{fill:#f6d900}.c30{fill:#f0ce00}.c31{fill:#eed100}.c32{fill:#00e58b}.c33{fill:#00df71}.c34{fill:#00e280}.c35{fill:#00cb59}.c36{fill:#00d874}.c37{fill:#00d963}.c38{fill:#00d36c}.c39{fill:#00de7c}.c40{fill:#ebb7a5}.c41{fill:#e3aa96}.c42{fill:#094378}.c43{fill:#c1a900}.c44{fill:#dcc000}.c45{fill:#fade11}.c46{fill:#f8dc09}.c47{fill:#00c5e6}.c48{fill:#dcdcdc}.c49{fill:#c1f8f9}.c50{fill:#b2b8b9}.c51{fill:#aab0b1}.c52{fill:#b0b4b5}.c53{fill:#e2a38d}.c54{fill:#eba992}.c55{fill:#e8b2a0}.c56{fill:#ff0043}.c57{fill:#f6767b}.c58{fill:#c74249}.c59{fill:#aa343a}.c60{fill:#4047ff}.c61{fill:#585eff}.c62{fill:#4d54ff}.c63{fill:#222bff}.c64{fill:#3d44ff}.c65{fill:#3b42ff}.c66{fill:#3239ff}.c67{fill:#343bff}.c68{fill:#4249ff}.c69{fill:#333333}.c70{fill:#222222}.c71{fill:#ccccff}</style></svg>"

            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 7; i++) { //9
            uint8 thisTraitIndex = ChainsLibrary.parseInt(
                ChainsLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"},'
                )
            );
          
        }

        metadataString = string(abi.encodePacked(metadataString, '{"display_type": "boost_number", "trait_type": "BB Boost", "value":',ChainsLibrary.toString(tokenIdToRarityCount[_tokenId]),'}'));

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    ChainsLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "BlockChain #',
                                    ChainsLibrary.toString(_tokenId),
                                    '", "description": "The BlockChains collection serves as the first phase of Ben Baller Did The BlockChain.", "image": "data:image/svg+xml;base64,',
                                    ChainsLibrary.encode(
                                        bytes(hashToSVG(tokenHash))
                                    ),
                                    '","attributes":',
                                    hashToMetadata(tokenHash, _tokenId),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId];
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "1",
                    ChainsLibrary.substring(tokenHash, 1, 9)
                )
            );
        }

        return tokenHash;
    }


    /**
     * @dev Returns the mint timestamp of a tokenId
     * @param _tokenId The tokenId to return the timestamp for.
     */
    function getTokenTimestamp(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tokenIdToTimestamp[_tokenId];
    }

    /**
     * @dev Returns the number of rare assets of a tokenId
     * @param _tokenId The tokenId to return the number of rare assets for.
     */
    function getTokenRarityCount(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tokenIdToRarityCount[_tokenId];
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
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
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pixels,
                    traits[i].pixelCount
                )
            );
        }

        return;
    }

    /**
     * @dev Sets the diamonds ERC20 address
     * @param _ballerbarsAddress The diamonds address
     */

    function setBallerBarsAddress(address _ballerbarsAddress) public onlyOwner {
        ballerbarsAddress = _ballerbarsAddress;
    }

}