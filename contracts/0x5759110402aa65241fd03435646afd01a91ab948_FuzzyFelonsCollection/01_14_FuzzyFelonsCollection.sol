// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

                                        /*^!!7?JJ7     
FUZZY                  .:^^~~^~!!:  .7J5GGBBBGPY7~:    
  FELONS ~~       ~7??YPGGP5YJJ????J5###BBBBBGGGY7~    
          ...::.  7B######BGPP555P5YB##BBBBBBBBG5?:    
     :!7?Y55GBBGPPG#######BGGPP55Y5GGGGGBBBBBBG5?:     
     !GBBBB#B###&##BB#BBBGGGGGGGGGGGGGPPPPPGPJ!:       
     ~GBBB#BB####BBBBBBBBGBGGGGGGGGGGGGGGPP5J^         
     .!PB#######BBBBBBBBBBGPPGGGPGGGGGGGGGP55J7.       
       .~7Y5PBBBBBBBBBBBBBGGBBBGGGGGGGGGGBG55Y?!       
            7PGBBBBBBBBBBBBBBBBBGGGGGBGGG55G5J!!:      
            7PBBBBBBGGGBGBGBGBBBGGGGGBGGPPPPJ7~!^      
           .?PBBB##BBBBBGGBGGBGGGGGGGP55555Y7!77       
            .JPB###BB##BBBBBGGBBGGGG55P5555J?!~.       
              :7PB###BB#####BBGGGP55JYYYYJJ!~.         
                .^7YPGBBGBGGGGPPGPPP55Y??7^            
                   .!Y555YYYYY555YYJ?77~.  ..          
               .~7J5PPP555555YYYJ?!^^:.:.   .:.        
            .~7?JYYYPPPP55555555YJ777!~^^^:::^^:..     
         .~!??7777??Y55555555555YJ7777~^^^::^:^~: ..*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title The ERC721 contract for the Fuzzy Felons collection.
 *
 * This collection will allow up to MAX_SUPPLY tokens to be minted.
 *
 * The mint price per token is MINT_PRICE.
 * 
 * During its lifetime this contract will go through several phases:
 *   - Phase 0 - Minting is still not active.
 *   - Phase 1 - Whitelisted addresses can mint 1 token each.
 *   - Phase 2 - Whitelisted addresses can mint up to MAX_WL_MINT tokens each,
 *               including any single token minted in Phase 1.
 *   - Phase 3 - Public minting, any address (even if not on whitelist) can mint
 *               up to MAX_PUBLIC_MINT tokens each, including any tokens minted
 *               in Phases 1 and 2.
 *   - Phase 4 - Minting is over. This will monstly happen after MAX_SUPPLY
 *               tokens have been minted or the deadline for Phase 3 is over.
 *
 *  Each of these phases will have a deadline, after which the owner of this
 *  contract will use setPhase() to move on to the next one. See the FAQ at
 *  the website for more info on these phases and deadlines:
 *     https://fuzzyfelons.com/#faq
 *
 * For sake of transparencey, as an assurance that the content of the
 * animations/images will not be tampered unnoticeably by the team, a
 * PROVENANCE hash is published here. This contains the SHA256 hash of all
 * SHA256 hashes of the animation files put together in order of tokenId.
 * Anyone can download all these files, run a SHA256 hash on each one of them,
 * concatenate all the bytes of these hashes and calculate its SHA256 hash to
 * verify that they have the expected content. Thus, the content of these images
 * will forever be recorded and verifiable in the blockchain.
 *
 * The owners of this contract reserve themselves the ability to mint up to
 * MAX_OWNER_MINT tokens for free (except gas). These tokens will be mintable
 * only when the wider public can also mint (Phase 1 to Phase 3). For the sake
 * of transparency and openness this reduces the hipothetical scenario in which
 * the team cherry-picks specific tokens. These tokens are meant to be handed
 * out back to the community and people who supported the team as gifts,
 * raffles, prizes, rewards, etc. The owner specifies which account will
 * receive the newly minted tokens.
 *
 * The owner account is able to withdraw the eth funds from minting in this
 * smart contract into a specified account.
 *
 * The whitelisting process uses a merkle tree and merkle proofs in order
 * to reduce the gas needs for checking if an address is in the whitelist.
 *
 * The contract can be paused at any moment by the team if need be. This will
 * pause the minting and token transfers.
 *
 */ 
contract FuzzyFelonsCollection is ERC721, Ownable, Pausable {

    // Maximum allowed tokens to be minted per whitelisted address during
    // phase 2.
    uint8 public constant MAX_WL_MINT = 4;
    
    // Maximum allowed tokens to be held by the minting account during the
    // public minting phase 3.
    uint8 public constant MAX_PUBLIC_MINT = 2;

    // Maximum number of tokens to be minted by the owner.
    uint8 public constant MAX_OWNER_MINT = 50;

    // The current minting Phase.
    uint8 public phase;

    // Keeps track of the number of tokens already minted by the owner.
    uint8 public ownerMintedCount;

    // Merkle Tree root for the Whitelist.
    bytes32 public whitelistRoot;

    // Maximum number of tokens that this collection will have.
    uint256 public MAX_SUPPLY;

    // The price per minted token.
    uint256 public MINT_PRICE = 0.1 ether;
    
    // Keeps track of how many tokens minted by each address.
    mapping (address => uint8) public mintCount;

    // Keeps track of the number of tokens minted so far.
    using Counters for Counters.Counter;
    Counters.Counter private _idCounter;

    // Provenance - an hex hash produced by hashing all the image files of all
    // tokens. Can be used as a proof that the images are the original ones. 
    string public PROVENANCE;

    // The URI of the default token JSON, to be returned by tokenURI(id) before
    // reveal.
    string public defaultURI;

    // The base URI of the revealed token metadata.
    string public metadataBaseURI;

    /**
     * @param maxSupply - the maximum number of tokens allowed to be minted.
     * @param provenance - the initial value of PROVENANCE.
     * @param _defaultURI - the initial URI for every token.
     */
    constructor(
        uint256 maxSupply,
        string memory provenance,
        string memory _defaultURI,
        address _owner
    ) 
        ERC721("Fuzzy Felons", "FELON")
    {
        // Initialize a few values during deploy.
        MAX_SUPPLY = maxSupply;
        PROVENANCE = provenance;
        defaultURI = _defaultURI;

        // Start with minting deactivated.
        setPhase(0);

        // Set the owner
        transferOwnership(_owner);
    }

    //*** Minting ***//

    /**
     * @notice Mints tokens. The sender address will receive these tokens. The
     * correct amount of eth has to be sent with the transaction that calls
     * this. This eth amount should be = MINT_PRICE * mintNum.
     *
     * @dev This function validates if the sender address meets the conditions
     * imposed by the current minting phase and fail if it doesn't.
     *
     * @param mintNum - the number of tokens to be minted.
     *
     * @param merkleProof - to be used to check if the sender address is in the
     * whitelist. This is ignored during public minting (phase 3).
     */
    function mint(uint8 mintNum, bytes32[] calldata merkleProof)
        public payable whenNotPaused
    {
        // Check if minting is active.
        require (isMintingActive(), "MINTING_NOT_ACTIVE");

        if (isWhitelistActive()) {
            // Check if the sender address is in the whitelist.
            require(isInWhitelist(_msgSender(), merkleProof),
                "INVALID_WL_PROOF");

            // If we are in the single mint whitelist phase (1), then allow one
            // token to be minted per whitelisted address, otherwise only allow
            // up to MAX_WL_MINT (phase 2);
            uint256 maxAllowed = isWhitelistSingle()? 1 : MAX_WL_MINT;

            // Check if this address hasn't minted all the tokens it is allowed
            // to in this phase.
            require(mintCount[_msgSender()] + mintNum <= maxAllowed,
                "EXCEEDS_WL_ALLOWED");
        
        } else {
            // Public Phase

            // Make sure that the sender will not mint more tokens than the ones
            // allowed during the public minting phase.
            // NOTE: This will not stop an individual from minting more tokens
            //       with other addresses.
            require(mintCount[_msgSender()] + mintNum <= MAX_PUBLIC_MINT,
                "EXCEEDS_PUBLIC_ALLOWED");
        }

        // Make sure that the correct ammount of eth is being paid.
        require(msg.value == MINT_PRICE * mintNum, "WRONG_ETH_AMOUNT");

        // Don't allow the maximum supply to be exceeded.
        require(totalSupply() + mintNum <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");

        // All the conditions are verified at this point, good to go!
        for (uint32 i = 0; i < mintNum; i++) {
            // Increment the counter and get the id. First id is 1. 
            _idCounter.increment();
            uint256 newTokenId = _idCounter.current();

            // Mint the token.
            _safeMint(_msgSender(), newTokenId);
        }

        // Update the counter of minted tokens by this address.
        mintCount[_msgSender()] += mintNum;
    }

    /**
     * @notice Allows the owner to mint up to MAX_OWNER_MINT tokens. The
     *      resulting tokens will be held by the 'to' account. This should
     *      fail during phases 0 and 4, when minting is deactivated for
     *      everyone.
     *         
     * @param mintNum - the number of tokens to be minted.
     * @param to - the address of the account that will receive the newly minted
     *      tokens.
     */
    function ownerMint(uint8 mintNum, address to)
        public onlyOwner whenNotPaused
    {
        // The owner can only mint when others can also mint - it's only fair...
        require (isMintingActive(), "MINTING_NOT_ACTIVE");

        // Make sure the owner doesn't mint more than it is allowed to.
        require(ownerMintedCount + mintNum <= MAX_OWNER_MINT,
            "EXCEEDS_OWNER_ALLOWED");

        // Don't allow the maximum supply to be exceeded.
        require(totalSupply() + mintNum <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");

        // Mint the tokens.
        for (uint32 i = 0; i < mintNum; i++) {
            // Increment the counters and get the id. First id is 1. 
            _idCounter.increment();
            uint256 newTokenId = _idCounter.current();

            // Mint the token into the 'to' account.
            _safeMint(to, newTokenId);
        }

        // Update the number of tokens minted by the owner.
        ownerMintedCount += mintNum;
    }

    /**
     * @dev Overrides ERC721.tokenURI().
     *
     * @notice Makes sure no transfers happen when paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal override whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Returns the number of tokens minted so far.
     */
    function totalSupply() public view returns (uint256) {
        return _idCounter.current();
    }

    //*** Whitelist ***//

    /**
     * @notice Sets root of the Merkle Tree with the white list entries.
     *
     * @param root - the Merkle Tree root.
     */
    function setWhitelistRoot(bytes32 root) external onlyOwner {
        whitelistRoot = root;
    }
    
    /**
     * @notice Verifies if an address is in the Whitelist.
     *
     * @param addr - the address being tested against the whitelist.
     *
     * @param merkleProof - the Merkle proof for addr in the tree.
     */
    function isInWhitelist(address addr, bytes32[] calldata merkleProof)
        public view returns (bool)
    {
        require( whitelistRoot != 0, "WHITELIST_ROOT_NOT_SET" );

        return MerkleProof.verify(
            merkleProof,
            whitelistRoot,
            keccak256(abi.encodePacked(addr))
        );
    }

    //*** Metadata URI ***//

    /**
     * @notice Reveals the token images and traits by setting the base URI for
     * all the token metadata JSONS. The full URI will be this base followed by
     * the token id number.
     *
     * @param baseURI - the base URI for the token metadata JSONS. 
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        metadataBaseURI = baseURI;
    }

    /** 
     * @dev Overrides ERC721._baseURI().
     */
    function _baseURI() internal view override returns (string memory) {
        return metadataBaseURI;
    }

    /**
     * @dev Overrides ERC721.tokenURI().
     *
     * @return uri - the default uri until reveal and final one after that.  
     */
    function tokenURI(uint256 tokenId)
        public view override returns (string memory)
    {
        string memory uri = super.tokenURI(tokenId);

        if (bytes(uri).length == 0) {
            // The reveal hasn't happend yet - return default URI.
            return defaultURI;
        } else {
            return uri;
        }
    }

    //*** Minting Phases ***//

    /**
     * @notice Sets the current minting phase. For more info:
     *         https://fuzzyfelons.com/#faq
     */
    function setPhase(uint8 _phase) public onlyOwner {
        require(_phase >= 0 && _phase <= 4, "INVALID_PHASE");
        phase = _phase;
    }

    /**
     * @return true if minting is active in this phase.
     */
    function isMintingActive() public view returns (bool) {
        // True for phases 1, 2 and 3.
        return phase > 0 && phase < 4;
    }

    /**
     * @return true if only whitelisted addresses can mint in this phase.
     */
    function isWhitelistActive() public view returns (bool) {
        // True for phases 1 and 2.
        return phase > 0 && phase < 3;
    }

    /**
     * @return true if whitelisted addresses can mint only 1 token in this
     * phase.
     */
    function isWhitelistSingle() public view returns (bool) {
        // True for phase 1.
        return phase == 1;
    }

    //*** Funds ***//

    /**
     * @notice Transfers all the minting funds to the 'to' account. 
     *
     * @param to - the address of the account that will receive the funds.
     */
    function withdraw(address payable to) public onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "WITHDRAW_ERROR");
    }

    //*** Provenance ***//

    /**
     * @notice Sets provenance hash.
     *
     * @dev This should match the SHA256 hash of all the SHA256 hashes of the
     * token image files put together in order.
     */
    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    //*** Pause ***//

    /**
    * @notice Pauses the minting.
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * @notice Unpauses the minting.
    */
    function unpause() public onlyOwner {
        _unpause();
    }
}