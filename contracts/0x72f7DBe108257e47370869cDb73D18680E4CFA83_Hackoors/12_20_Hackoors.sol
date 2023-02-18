// SPDX-License-Identifier: MIT

/*
* https://twitter.com/HackoorsNFT
*
*                                             ..?!~~~?..
*                                          :GPY^..   ^~#BP:
*                                        ^[email protected]@@P     .^#@@#&B^
*                                      .B&&&B~      :B&@@@@@&B.
*                                     !5?~!:  .    ::^^#@@#7^J5!
*                                   :&@@&PY!.:^.   ::::#@B!.~P&@&:
*                                  ^&G5P7:::^:.    ..::J7:..:^~7B&^
*                                  5G^::.:.                   :5&@5
*                                 [email protected]^..    :??????????????:     [email protected]
*                                 [email protected]!. ~B&&@@@@@@@@@@@@@@@@&&#?^^[email protected]?
*                                 [email protected]&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^
*                            :.7::~5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5~::7.:
*                          :??.     :Y&@@@@@@@@@@@@@@@@@@@@@@@@&Y:     .??:
*                        ^?^          :^^[email protected]@@@@@@@@@@@@@@@@@@#J:          ^?^
*                       ~?   ..   ...   .:[email protected]@@@@@@@@@@@@@@@#7:   ...  ..7.  ?~
*                      !5.  [email protected]&Y:   :::.75P#@@@&&&&&&&&@@@@#Y7.:::   :#&@7  ~#!
*                     !J:::[email protected]@@&5^..^:::[email protected]@@&~^^^^^^~&@@@B?:::^..^5&@@G~:...?!
*                    7!  .:[email protected]@@@&&&&5YYJYB&@&#JJJJJJ#&@&BYJYY5&&&&@@@@PY!^:  !7
*                   ~?.!YJG&==============================================&&&B!.?~
*                  :&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P~!~!B&:
*                  JGP&@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@&PGJ
*                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@57P5GB77?
*                ~J~^^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5.:.:!P~J~
*                JG&P~^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!::^[email protected]&GJ
*                [email protected]@@&&G57:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y:7B&@@@@@J
*                ~&@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@&~
*                  ?BB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BB?
*                      ^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J:::^
*                           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~
*                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./utils/DefaultOperatorFilter.sol";
import "./interface/IOnchainArt.sol";


contract Hackoors is DefaultOperatorFilterer, ERC2981, ERC721AQueryable, Ownable {
    using Strings for uint256;

    IERC721 constant PUNK = IERC721(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    IERC721 constant MAYC = IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
    IERC721 constant BEANZ = IERC721(0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949);
    IERC721 constant CRYPTODICKBUTTS = IERC721(0x42069ABFE407C60cf4ae4112bEDEaD391dBa1cdB);
    uint256 constant MAX_SUPPLY = 8000;
    uint256 constant MAX_MINT_PER_TX = 5;
    
    bool mintActive;
    bool useUpdatedScores;
    bool scoresSealed;
    bool artRevealed;
    bool useOnchainArt;
    address onchainArt;
    string _imageURI;

    uint16[10][9] RARITY_SCORES;
    mapping(bytes32 => bool) isGenotypeMinted;
    mapping(uint256 => bytes32) genotypes;

    error NoUniqueGenotypeFound();
    error InsufficientEther();
    error MaxSupplyReached();
    error NoContractsAllowed();
    error MintEnded();
    error TooManyMintsRequested();
    error ScoresAreSealed();
    error TokenDoesNotExist();

    modifier onlyEOA {
        if (msg.sender != tx.origin) revert NoContractsAllowed();
        _;
    }

    modifier mintIsActive {
        if (!mintActive) revert MintEnded();
        _;
    }
    
    constructor(string memory preRevealImageURI) ERC721A("Hackoors", "HACK") {
        _imageURI = preRevealImageURI;
        _setDefaultRoyalty(msg.sender, 200); // 2%
        mintActive = true;
    }

    ////////////////////////////////////////////////////////
    //////////////////// USER FUNCTIONS ////////////////////
    ////////////////////////////////////////////////////////

    /**
    * @notice Standard mint function. Generates a unique genotype for each tokenId
    * Max of 5 mints per transaction.
    */
    function mint(uint256 amount, uint256 balanceFlag) external onlyEOA mintIsActive {
        
        if (_nextTokenId() + amount > MAX_SUPPLY) revert MaxSupplyReached();
        if (amount > MAX_MINT_PER_TX) revert TooManyMintsRequested();

        for(uint256 i=0; i<amount; ++i){
            bytes32 genotype;
            if (i==0) {
                genotype = _getGenotype(_nextTokenId()+i, balanceFlag);
            } else {
                genotype = _getGenotype(_nextTokenId()+i, 0);
            }
            isGenotypeMinted[genotype] = true;
            genotypes[_nextTokenId()+i] = genotype;
        }

        _mint(msg.sender, amount);
    }

    /**
     * @notice Exposed for future usecases. Do not call this directly
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    /////////////////////////////////////////////////////////////
    //////////////////// READ-ONLY FUNCTIONS ////////////////////
    /////////////////////////////////////////////////////////////

    /**
     * @notice Returns the rarity score. See description below for _getPreComputedScore()
     */
    function rarityScore(uint256 tokenId) external view returns(uint256) {
        if (tokenId>=_nextTokenId()) revert TokenDoesNotExist();
        return useUpdatedScores ? _getUpdatedScore(tokenId) : _getPreComputedScore(tokenId);
    }

    /**
     * @notice Returns metadata. All metadata is on-chain, with only the image being off-chain (IPFS)
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (tokenId>=_nextTokenId()) revert TokenDoesNotExist();

        bytes32 genotype = genotypes[tokenId];
        
        bytes memory json = abi.encodePacked(
            '{"name": "Hackoors #',tokenId.toString(),'",',
            '"image": "', _getImageURI(tokenId), '","attributes": ['
        );
        
        for (uint i=0; i<9; i++) {
            json = abi.encodePacked(json, _getTraitString(i, uint8(genotype[i])));
        }

        json = abi.encodePacked(json, ']}');

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
    }

    ////////////////////////////////////////////////////////////
    //////////////////// INTERNAL FUNCTIONS ////////////////////
    ////////////////////////////////////////////////////////////
    
    /**
     * @notice Each NFT has a unique 'genotype' which determines the traits. These are generated at the time of
     * minting, which means you will know the traits immedaitely. 7 attempts are made to generate
     * a unique genotype for each NFT before the transaction reverts. This is plenty and in practice, less than
     * 10% of all mints would need 1 re-roll, and only a handful (less than 20) would need 2 re-rolls. It is
     * highly unlikely that any NFT would need 3 or more re-rolls.
     */
    function _getGenotype(uint256 tokenID, uint256 balanceFlag) internal view returns(bytes32) {
        // Generate random hash. This essentially serves as 16 very-pseudo-rng between 0 and 65535
        // Highly doubt anyone will go through the trouble of predicting RNG for a freemint NFT, so this
        // is sufficient
        bytes32 randhash = keccak256(abi.encodePacked(block.timestamp,block.prevrandao,msg.sender,tokenID));

        // Try generating a unique genotype upto 7 times
        for (uint i=0; i<7; i++) {
            // Generate a 9-digit number which determines the traits
            bytes32 genotype = _generateUniqueGenotypeFromHash(randhash, balanceFlag);

            // Check for uniqueness
            if (!isGenotypeMinted[genotype]) {
                return genotype;
            }
            
            // Shift 15 bits and try again. Slight offset to not repeat same numbers from last round
            randhash = bytes32(uint256(randhash) << 15);
        }

        // Failed after 7 attempts
        revert NoUniqueGenotypeFound();
    }

    /**
     * @notice Generates the unique genotype, with the additional condition that if a wallet owns a Punk, MAYC,
     * Bean, or cryptodickbutt, then this is reflected in the "Laptop Sticker" trait. This is the only way to get
     * these 4 traits.
     */
    function _generateUniqueGenotypeFromHash(bytes32 randHash, uint256 balanceFlag) internal view returns(bytes32 genotypeFixedBytes) {
        
        bytes memory genotypeDynamicBytes;

        // For each category
        for (uint i=0; i<9; i++) {
            uint16 randNumb = uint16(bytes2(randHash));
            uint8 gene;

            if (i!=5) {
                gene = _getGene(randNumb, i);
            } else { // For laptop sticker trait only

                // Precedence order: Punk > MAYC > Bean > CDB
                if (balanceFlag == 1) {
                    gene = PUNK.balanceOf(msg.sender) > 0 ? 8 : 0;
                } else if (balanceFlag == 2) {
                    gene = MAYC.balanceOf(msg.sender) > 0 ? 9 : 0;
                } else if (balanceFlag == 3) {
                    gene = BEANZ.balanceOf(msg.sender) > 0 ? 10 : 0;
                } else if (balanceFlag == 4) {
                    gene = CRYPTODICKBUTTS.balanceOf(msg.sender) > 0 ? 11 : 0;
                }

                gene = gene == 0 ? _getGene(randNumb, i) : gene;
            }

            // Concatenate the genes
            genotypeDynamicBytes = abi.encodePacked(genotypeDynamicBytes, gene);

            // Shift 1 rng for next trait
            randHash = bytes32(uint256(randHash) << 16);
        }

        assembly {
            genotypeFixedBytes := mload(add(genotypeDynamicBytes, 32))
        }
    }

    /**
     * @notice Determines the specific gene within the genotype. In other words, determines the individual traits as
     * defined by the trait odds.
     */
    function _getGene(uint16 randNumb, uint256 i) internal pure returns(uint8) {
        // In-memory 2D array of cumulative rarities (65535 = 100%) for each category. Saves ~15k gas when minting
        // compared to using storage arrays
        uint16[10][9] memory TRAIT_ODDS = [
            [16383, 32767, 52428, 65535, 0, 0, 0, 0, 0, 0],
            [10922, 21845, 32767, 43690, 54612, 65535, 0, 0, 0, 0],
            [7209, 15728, 24248, 28180, 36700, 45219, 53739, 60948, 63569, 65535],
            [18724, 42129, 65535, 0, 0, 0, 0, 0, 0, 0],
            [14838, 16074, 32561, 49048, 65535, 0, 0, 0, 0, 0],
            [8192, 16383, 24575, 32767, 40959, 49151, 57343, 65535, 0, 0],
            [58982, 62258, 65535, 0, 0, 0, 0, 0, 0, 0],
            [22937, 25559, 36700, 42270, 46858, 54722, 57998, 58130, 60292, 65535],
            [45875, 53083, 58326, 65535, 0, 0, 0, 0, 0, 0]
        ];

        // Find which trait the rng corresponds to for category i
        for(uint j=0; j<10; j++) {
            if (randNumb < TRAIT_ODDS[i][j]) return uint8(j);
        }

        return 0; // This will never reach
    }

    /**
     * @notice Rarity score calculated with method outlined here:
     * https://raritytools.medium.com/ranking-rarity-understanding-rarity-calculation-methods-86ceaeb9b98c
     * 
     * Essentially its:
     *                         (1/percentChanceOfTrait)
     *
     * Values are also multipled by 10 to preserve 1 decimal place
     * Keep in mind that these rarity scores would be close-approximates to the final rarity scores, since we can't guarantee
     * the final counts for each trait.
     * E.g. We can't guarantee that a trait with a 10% chance occurence from an 8000 NFT collection will have exactly 800
     * pieces, so final rarities may slightly vary. See next function description
     * 
     * Future on-chain governance voting power and puzzle burn mechanics may be decided with rarity score ;)
     */
    function _getPreComputedScore(uint256 tokenId) internal view returns(uint256 score) {

        uint256[10][9] memory SCORES = [
            [uint256(40), 40, 33, 50, 0, 0, 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0], // No score for "Table" as all traits have equal chance
            [uint256(91), 77, 77, 167, 77, 77, 77, 91, 250, 333],
            [uint256(35), 28, 28, 0, 0, 0, 0, 0, 0, 0],
            [uint256(44), 530, 40, 40, 40, 0, 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0],  // No score for "Sticker" as all traits have equal chance, or based on other NFT holdings
            [uint256(11), 200, 200, 0, 0, 0, 0, 0, 0, 0],
            [uint256(29), 250, 59, 118, 143, 83, 200, 4965, 303, 125],
            [uint256(14), 91, 125, 91, 0, 0, 0, 0, 0, 0]
        ];

        bytes32 genotype = genotypes[tokenId];
        for (uint i=0; i<9; i++){
            score += (!(i==1 || i==5)) ? uint256(SCORES[i][uint8(genotype[i])]) : 0;
        }
    }

    /**
     * @notice This is a backup method used if the resulting counts for each trait are sufficiently different to what is expected.
     * If this is the case, an updated rarity scores table (like the SCORES table above) will be pushed. See updateScores() below
     */
    function _getUpdatedScore(uint256 tokenId) internal view returns(uint256) {
        bytes32 genotype = genotypes[tokenId];
        uint16 score;
        for (uint i=0; i<9; i++){
            score += (!(i==1 || i==5)) ? (RARITY_SCORES[i][uint8(genotype[i])]) : 0;
        }
        return uint256(score);
    }

    /**
     * @notice Though the metadata is on-chain, the art is currently off-chain (IPFS). Keep in mind that there is built-in flexibility
     * for moving the art fully on-chain in the future (currently this has a very high deployment cost for the Hackoors artwork)
     */
    function _getImageURI(uint256 tokenID) internal view returns (string memory) {
        return useOnchainArt ? IOnchainArt(onchainArt).getSVG(tokenID) : artRevealed ? string(abi.encodePacked(_imageURI,tokenID.toString())) : _imageURI;
    }

    /**
     * @notice Helper function to format the metadata string
     */
    function _getTraitString(uint256 categoryIndex, uint8 traitIndex) internal pure returns (string memory) {
        string[9] memory CATEGORIES = ["Background", "Table", "Hoody", "Laptop Model", "Laptop Colour", "Laptop Sticker", "Aura", "Face", "Pet"];

        string[12][9] memory TRAITS = [
            ["Bedroom", "Coast", "Veranda", "Server Warehouse", "", "", "", "", "", "", "", ""],
            ["Clean", "Criminal", "Gamer", "Messy", "Stoner", "Techie", "", "", "", "", "", ""],
            ["Black", "Blue", "Brown", "Daybreak", "Green", "Grey", "Red", "Denim", "Gi", "Iron Skin", "", ""],
            ["Bulky", "Slim", "Standard", "", "", "", "", "", "", "", "", ""],
            ["Black", "Gold", "Blue", "Grey", "White", "", "", "", "", "", "", ""],
            ["None", "Bitcoin", "Cicada 3301", "Dragonball", "Ethereum", "Murica", "Skull", "Nuclear", "Punk", "Ape", "Bean", "CryptoDickbutt"],
            ["None", "Lightning", "Sakura", "", "", "", "", "", "", "", "", ""],
            ["None", "Bloodline", "Shadow", "Gas Mask", "Kitsune", "Anonymous", "Shogun", "Recruit", "Ghost", "Scream", "", ""],
            ["None", "Mouse", "Kitten", "Owl", "", "", "", "", "", "", "", ""]
        ];

        bytes memory res = abi.encodePacked('{"trait_type": "', CATEGORIES[categoryIndex],'", "value": "', TRAITS[categoryIndex][traitIndex], '"}');

        // Preceding comma for json formatting
        if (categoryIndex > 0 && res.length > 0) {
            res = abi.encodePacked(",", res);
        }

        return string(res);
    }

    //////////////////////////////////////////////////////////////
    //////////////////// OWNER ONLY FUNCTIONS ////////////////////
    //////////////////////////////////////////////////////////////
    //
    // The 'owner' is planned to be transferred to a Governor contract once on-chain governance is implemented.
    // All functions below will require a succesful vote once ownership is transferred to the Governor contract.

    /**
     * @notice Reveal artwork!
     */
    function revealImage(string memory revealedImageURI) external onlyOwner {
        _imageURI = revealedImageURI;
        artRevealed = true;
    }

    /**
     * @notice Close minting period. Only needed if collection doesn't hit max supply cap
     */
    function closeMint() external onlyOwner {
        mintActive = false;
    }

    /**
     * @notice Irreversible switch which finalises the rarity scores.
     */
    function sealScores() external onlyOwner {
        scoresSealed = true;
    }

    /**
     * @notice As mentioned above, pushes the updated rarity scores if the final trait counts are significantly different
     * than the intended percentages. Can also be use if the trait counts change by a large amount due to burning. Rarity
     * scores are not calculated on-chain as this would mean significantly higher minting gas costs, as each mint would need
     * to incremement the counter for each of the 10 attributes.
     */
    function updateScores(uint16[10][9] memory temp) external onlyOwner {
        if (scoresSealed) revert ScoresAreSealed();
        useUpdatedScores = true;
        RARITY_SCORES = temp;
    }

    /**
     * @notice Sets the on-chain art contract address
     */
    function setOnchainArtAddress(address onchainArt_) external onlyOwner {
        onchainArt = onchainArt_;
    }

    /**
     * @notice A switch which can be turned on or off
     */
    function switchOnchainArt() external onlyOwner {
        useOnchainArt = !useOnchainArt;
    }

    /**
     * @notice Withdraws any ETH mistakenly sent to this contract
     */
    function withdraw() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Rescue any ERC20 tokens mistakenly sent to this contract
     */
    function rescueERC20(address token, address recipient) external onlyOwner() {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    /**
     * @notice Rescue any ERC721 NFTs mistakenly sent to this contract
     */
    function rescueERC721(address token, uint256 tokenId, address recipient) external onlyOwner() {
        IERC721(token).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @notice Sets royalty info according to EIP2981
     */
    function setRoyalty(address recipient, uint96 royaltyBips) external onlyOwner() {
        _setDefaultRoyalty(recipient, royaltyBips);
    }

    /////////////////////////////////////////////////////////////////
    //////////////////// OTHER UTILITY OVERRIDES ////////////////////
    /////////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A, IERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    fallback() external payable {}
    receive() external payable {}
}