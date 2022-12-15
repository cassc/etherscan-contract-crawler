// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/Ownable.sol";
import "./token/ERC721/IERC721A.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    ██╗░░░██╗░█████╗░██╗░░░░░██╗░░██╗░█████╗░██╗░░░░░██╗░░░░░░█████╗░    //
//    ██║░░░██║██╔══██╗██║░░░░░██║░░██║██╔══██╗██║░░░░░██║░░░░░██╔══██╗    //
//    ╚██╗░██╔╝███████║██║░░░░░███████║███████║██║░░░░░██║░░░░░███████║    //
//    ░╚████╔╝░██╔══██║██║░░░░░██╔══██║██╔══██║██║░░░░░██║░░░░░██╔══██║    //
//    ░░╚██╔╝░░██║░░██║███████╗██║░░██║██║░░██║███████╗███████╗██║░░██║    //
//    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * Subset of a Utility with only the methods that the dna contract will call.
 */
interface Utility {
    function approvedBurn(address spender, uint256 tokenId, uint256 amount) external;
}

contract ValhallaDNA is Ownable {

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // This IPFS code hash will have a function that can translate any token's
    // DNA into the corresponding traits. This logic is put here instead of on the 
    // contract so that the gas fee for rerolling is minimal for the user.
    string public constant DNA_TRANSLATOR_CODE_HASH = "QmbFBwrDdSSd7VxsSGxhyPAASMuJJBqY5n8RY6LkUg1smx";

    // Checks the `ownerOf` method of this address for tokenId re-roll eligibility
    address public immutable TOKEN_CONTRACT;

    // Hash for the initial revealed tokens.
    string public constant MINT_PROVENANCE_HASH = "037226b21636376001dbfd22f52d1dd72845efa9613baf51a6a011ac731b2327";

    // Proof of hash will be given after all tokens are auctioned.
    string public constant AUCTION_PROVENANCE_HASH = "eb8c88969a4b776d757de962a194f5b4ffaaadb991ecfbb24d806c7bc6397d30";

    // The Initial DNA is composed of 128 bits for each token
    // with each trait taking up 8 bits.
    uint256 private constant _BITMASK_INITIAL_DNA = (1 << 8) - 1;

    // Each call to reroll will give this many options to select during boost
    uint256 public constant NUM_BOOSTS = 3;
    
    // Offset in bits where the booster information will start
    uint256 private constant _BOOSTER_OFFSET = 128;

    // 3 rerollable traits will fit in 2 bits
    uint256 private constant _BITLEN_BOOSTER_TRAIT = 2;
    uint256 private constant _BITMASK_BOOSTER_TRAIT = (1 << _BITLEN_BOOSTER_TRAIT) - 1;

    uint256 private constant _BITLEN_SINGLE_BOOST = 20;
    uint256 private constant _BITMASK_SINGLE_BOOST = (1 << _BITLEN_SINGLE_BOOST) - 1;
    uint256 private constant _BITLEN_TRAIT_BOOST = 21;
    uint256 private constant _BITMASK_TRAIT_BOOST = (1 << _BITLEN_TRAIT_BOOST) - 1;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // These will define what token is required to reroll traits
    address public utilityAddress;
    uint256 public utilityTokenId;

    // Only address allowed to change a token's dna.
    address public dnaInjectorAddress;
    // Will be locked after all the tokens are auctioned
    bool public dnaInjectionLocked;

    // A token's dna cannot be changed unless both of these are active.
    bool public rerollActive;
    bool public boostingActive;

    // for pseudo-rng
    uint256 private _seed;
    
    // Mapping tokenId to DNA information. An extra bit is needed for
    // each trait because the random boosterValue does have the tiniest
    // but non-zero probability to roll a 0. (1 in 1_048_576)
    //
    // Bits Layout:
    // - [0..127]   `initialDna`
    // - [128]      `hasHairBooster`
    // - [129..148] `hairBooster`
    // - [149]      `hasClothingBooster`
    // - [150..169] `clothingBooster`
    // - [170]      `hasPrimaryBooster`
    // - [171..190] `primaryBooster`
    // - [191..255]  Extra Unused Bits
    mapping(uint256 => uint256) private _dna;

    // Bits Layout:
    // - [0..1]     `boosterIdx`
    // - [2..21]    `boosterRoll`
    // - [22..41]   `boosterRoll`
    // - [42..61]   `boosterRoll`
    // - [62..256]   Extra Unused Bits
    mapping(uint256 => uint256) public activeBooster;

    // =============================================================
    //                         Events
    // =============================================================

    event Bought(
        uint256 indexed tokenId,
        uint256 indexed traitId,
        uint256 tokenDna,
        uint256 boosterVal
    );
    event Boost(uint256 indexed tokenId, uint256 boosterId, uint256 tokenDna);

    // =============================================================
    //                         Constructor
    // =============================================================
    constructor (address tokenAddress) {
        TOKEN_CONTRACT = tokenAddress;
    }

    // =============================================================
    //                          Only Owner
    // =============================================================

    /**
     * @notice Allows the owner to change the dna of any tokenId. Used for initial dna injection,
     * and the owner can call {lockDnaInjection} below to ensure that future dna changes can only 
     * be achieved by the token owner themselves.
     */
    function injectDna(uint256[] memory dna, uint256[] memory tokenIds) external {
        if (msg.sender != dnaInjectorAddress) revert NotDnaInjector();
        if (dnaInjectionLocked) revert DnaLocked();

        for (uint i = 0; i < tokenIds.length; ) {
            _dna[tokenIds[i]] = dna[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows the owner to prevent the owner from injecting dna forever. 
     * THIS CANNOT BE UNDONE.
     */
    function lockDnaInjection() external onlyOwner {
        dnaInjectionLocked = true;
    }

    /**
     * @notice Allows the owner to update the dna translator script. 
     */
    function setDnaInjector(address dnaInjector) external onlyOwner {
        dnaInjectorAddress = dnaInjector;
    }

    /**
     * @notice Allows the owner to select an address and token that must be burned to alter a token's 
     * dna. This address must have an {approvedBurn} method that is callable by this contract for
     * another user's tokens.
     */
    function setRerollToken(address token, uint256 tokenId) external onlyOwner {
        utilityAddress = token;
        utilityTokenId = tokenId;
    }

    /**
     * @notice Allows the owner to enable or disable token owners from rolling their dna.
     */
    function setRerollActive(bool active) external onlyOwner {
        rerollActive = active;
    }

    /**
     * @notice Allows the owner to enable or disable token owners from finalizing rolls into their dna.
     */
    function setBoostingActive(bool active) external onlyOwner {
        boostingActive = active;
    }

    // =============================================================
    //                    Dna Interactions
    // =============================================================

    /**
     * @dev Returns the saved token dna for a given id. This dna can be translated into
     * metadata using the scripts that are part of the DNA_TRANSLATOR_CODE_HASH constant. 
     */
    function getTokenDna(uint256 tokenId) external view returns (uint256) {
        return _dna[tokenId];
    }

    /**
     * @dev Adds an activeBooster to a given tokenId for a certain trait. The caller cannot be
     * a contract address and they must own both the Valhalla tokenId as well as the corresponding
     * Utility token to be burned.
     * 
     * Note: 
     * - A token CANNOT reroll a trait they do not have
     * - A token CAN override an existing activeBooster with another roll without calling {boost}
     * - The override is true even if a different rerollTraitId is selected from the first roll
     * 
     * @param tokenId tokenId that the booster is attached to
     * @param rerollTraitId 0 for hair, 1 for clothing, 2 for primary
     */
    function reroll(uint256 tokenId, uint256 rerollTraitId) external {
        if (!rerollActive) revert RerollInactive();
        if (msg.sender != tx.origin) revert NotEOA();
        if (rerollTraitId > 2) revert TraitNotRerollable();
        if (IERC721A(TOKEN_CONTRACT).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

        Utility(utilityAddress).approvedBurn(msg.sender, utilityTokenId, 1);

        // Cheaper gaswise to do bitshift than to multiply rerollTraitId by 8
        if (_dna[tokenId] & (_BITMASK_INITIAL_DNA << (rerollTraitId << 3)) == 0) revert TraitNotOnToken();

        // Shift _randomNumber up to make room for reroll traitId
        uint256 boosterVal = _randomNumber() << _BITLEN_BOOSTER_TRAIT;
        boosterVal = boosterVal | rerollTraitId;

        activeBooster[tokenId] = boosterVal;
        emit Bought(tokenId, rerollTraitId, _dna[tokenId], boosterVal);
    }

    /**
     * @dev Selects one of the boosters rolled from the {reroll} method and replaces the appropriate
     * section in the token dna's bits with one of the new values that was randomly rolled.
     */
    function boost(uint256 tokenId, uint256 boosterIdx) external {
        if(!boostingActive) revert BoostingInactive();
        if(IERC721A(TOKEN_CONTRACT).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        uint256 boosterVal = activeBooster[tokenId];
        if (boosterVal == 0) revert NoBoosterAtIdx();
        activeBooster[tokenId] = 0;

        if (boosterIdx >= NUM_BOOSTS) revert InvalidBoostIdx();
        uint256 selectedVal = 
            (boosterVal >> (boosterIdx * _BITLEN_SINGLE_BOOST + _BITLEN_BOOSTER_TRAIT)) &
            _BITMASK_SINGLE_BOOST;

        // This shifts the value up one bit and adds a flag to show that this trait has been boosted.
        // This is needed on the small chance that random value generated is exactly 0.
        selectedVal = selectedVal << 1 | 1;

        uint256 rerollTraitId = boosterVal & _BITMASK_BOOSTER_TRAIT;
        uint256 traitShiftAmount = rerollTraitId * _BITLEN_TRAIT_BOOST + _BOOSTER_OFFSET;

        _dna[tokenId] = _dna[tokenId] & ~(_BITMASK_TRAIT_BOOST << traitShiftAmount) | (selectedVal << traitShiftAmount);
        emit Boost(tokenId, boosterIdx, _dna[tokenId]);
    }

    /**
     * @dev Makes a pseudo-random number. Although there is some room for the block.timestamp to be
     * manipulated by miners, the random number used here is not used to determine something with high
     * impact such as determining a lottery winner. 
     * 
     * Implementing a more secure random number generator would lead to a worse reroll experience. 
     */
    function _randomNumber() internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, ++_seed)));
    }

    error BoostingInactive();
    error DnaLocked();
    error InvalidBoostIdx();
    error NoBoosterAtIdx();
    error NotDnaInjector();
    error NotEOA();
    error NotTokenOwner();
    error RerollInactive();
    error TraitNotRerollable();
    error TraitNotOnToken();
}