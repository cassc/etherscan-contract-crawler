// SPDX-License-Identifier: MIT

/************************************************************************************
 *       :::        :::::::::: :::    ::: ::::::::::: ::::::::   ::::::::  ::::    :::* 
 *     :+:        :+:        :+:    :+:     :+:    :+:    :+: :+:    :+: :+:+:   :+:  *
 *    +:+        +:+         +:+  +:+      +:+    +:+        +:+    +:+ :+:+:+  +:+   *
 *   +#+        +#++:++#     +#++:+       +#+    +#+        +#+    +:+ +#+ +:+ +#+    *
 *  +#+        +#+         +#+  +#+      +#+    +#+        +#+    +#+ +#+  +#+#+#     *
 * #+#        #+#        #+#    #+#     #+#    #+#    #+# #+#    #+# #+#   #+#+#      *
 *########## ########## ###    ### ########### ########   ########  ###    ####       *
 *************************************************************************************/
/// @title Lexicon Composable NFTs
/// @author Cherry, Ste

pragma solidity 0.8.6;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {SVGConstructors} from "./SVGConstructors.sol";
import {ILexicon} from "../interfaces/ILexicon.sol";
import {Base64} from "./Base64.sol";

contract Lexicon is ILexicon, ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {

    // Word list merkle root - prevent claim spamming
    bytes32 public immutable merkleRoot;

    // If a word exists - prevents an auction bidding on a word that already exists
    mapping(string => bool) public claimed;

    // Maps word indexes to their words - these words are set during claim or through an auction victory
    mapping(uint256 => string) public wordList;

    // Map tokenId to the words in the token - key to compostability
    mapping(uint256 => ILexicon.TokenDetails) public tokenToWords;

    // The address of the auction contract
    address public minter;

    // The auctionId being used by the auction contract - set in constructor
    uint256 private currentAuctionTokenId;

    // The msg.value required for a successful dismantle operation
    uint256 public dismantlePrice;

    // contains the svg styling information
    string[] public svgStyleString;

    // Token Counter for the next assembled token
    uint256 public currentAssembleCounter; //TODO: WHAT TOKEN ID SHOULD WE GO FROM


    /**Only Minter
     * @notice Method modifier only callable by a seperate minter contract (auction)
     */ 
    modifier onlyMinter(){
        require(msg.sender == minter, "LEXICON:NotMinter");
        _;
    }

    /**Constructor
     * @notice Called only during contract creation - provide
     * @param _merkleRoot               - { The merkle root of the Lexicon wordlist }
     * @param _currentAuctionTokenId    - { The starting ID for the words auction }
     * @dev populates configuration values, contract is immediately paused on deployment
     */
    constructor(
        bytes32 _merkleRoot, 
        uint256 _currentAuctionTokenId
    ) 
        ERC721("LEXICON", "LEXI")        
    {
        pause();

        merkleRoot = _merkleRoot;
        currentAuctionTokenId = _currentAuctionTokenId;
        dismantlePrice = 10000000000000000 wei;
        currentAssembleCounter = 11000;
    }

    /**Set Minter Address
     * @notice Sets the address of the auction contract
     * @param _newMinter - { The new auction contract address }
     * @dev Can only be called by owner
     */
    function setMinterAddress(address _newMinter) external onlyOwner{
        minter = _newMinter;
    }

    /**Set Dismantle Price
     * @notice Set the price for a dismantle operation
     * @param _newPrice - { New Price for the dismantle operation }
     * @dev Can only be called by owner
     */
    function setDismantlePrice(uint256 _newPrice) external onlyOwner {
        dismantlePrice = _newPrice;
    }

    /**Set SVG String
     * @notice Sets SVG string for font 
     * @param _styleString - { New proceeding SVG string }
     * @dev Can only be called by owner
     */
    function setSVGString(string[] memory _styleString) external onlyOwner {
        svgStyleString = _styleString;
    }

    /** Is word claimed
     * @notice method used by the auction contract to check that the supplied word has not already been claimed yet in the open mint
     * @param word - { The word to check }
     */
    function isWordClaimed(string calldata word) external override returns (bool isClaimed) {
        isClaimed = claimed[word];
    }

    /**Check owned and not phrase
     * @notice  Checks the owner of the provided [tokenId] is the sender account
     *          If the provided word is a phrase / a burned token it will also revert
     * @param tokenId - { The tokenId being dismantled }
     * @dev Strictly a helper function
     */
    function checkOwnedAndNotPhrase(uint256 tokenId) private {
        require(ownerOf(tokenId) == msg.sender, "!OWNER");
        require(tokenToWords[tokenId].length == 1, "LEXICON:CannotAssemblePhrases");
    }

   
    /**Assemble Multiple
     * @notice Assembles the provided tokenIds into one token
     * @notice All tokens are appended into the first provided token
     * @param tokenIds - { An set of tokenIds } 
     * @dev Can only be used on tokens that are standalone words and are not already phrases
     */
    function assembleMultiple(uint256[] calldata tokenIds) external override nonReentrant whenNotPaused{
        require(tokenIds.length > 1, "LEXICON:MoreThanOneRequired");

        // counter to keep track of the total length of the new token
        uint8 length = uint8(tokenIds.length);
        require(length <= 10, "LEXICON:CanOnlyAssemble10Words");
        
        // temp arr
        uint[] memory memTemp = new uint[](length);
        for (uint8 i = 0; i < length; i++){
            // check they own all of the tokens they are using
            checkOwnedAndNotPhrase(tokenIds[i]);

            memTemp[i] = tokenIds[i];

            // burn the assembled tokens - burn checks if they have already been burned
            _burn(tokenIds[i]);

            // delete the token2 reference
            delete tokenToWords[tokenIds[i]];
        }
        // set token values
        tokenToWords[currentAssembleCounter].ids = memTemp;
        tokenToWords[currentAssembleCounter].length = length;

        // mint token
        _safeMint(msg.sender, currentAssembleCounter);

        // Emit assembled event 
        emit Assembled(currentAssembleCounter, msg.sender);

        // update the assembled counter for the next one
        currentAssembleCounter++;
    }

    /**Dismantle 
     * @notice  Dismantle the given tokenID by re-minting it's sub components back into the original tokens
     *          This burns the given tokenID 
     *          This also takes a fee that can be set by setDismantlePrice
     * @param tokenId - { The tokenId of the token being dismantled }
     */
    function dismantle(uint256 tokenId) external payable override nonReentrant whenNotPaused{
         require(ownerOf(tokenId) == msg.sender, "!OWNER");
         require(msg.value >= dismantlePrice, "LEXICON:<DismantlePrice");

         // check that the token being dismantled actually has greater than one word in it
         uint length = tokenToWords[tokenId].length; 
         require(length > 1, "LEXICON:!SingleToken");

         for (uint i = 0; i < length ; i++){
            
            // set the length of the new mint to 1
            tokenToWords[tokenToWords[tokenId].ids[i]].ids = [tokenToWords[tokenId].ids[i]];
            tokenToWords[tokenToWords[tokenId].ids[i]].length = 1;

            _safeMint(msg.sender, tokenToWords[tokenId].ids[i]);   
         }
     
        delete tokenToWords[tokenId];
        _burn(tokenId);

        // Share dismantled event 
        emit Dismantled(tokenId, msg.sender);
    }

    /**Get Word
     * @notice Gets a word at an index for a tokenId 
     * @param index     - { The position in the phrase of the word being requested }
     * @param tokenId   - { The token Id of the word / phrase }
     */
    function getWord(uint index, uint tokenId) view public returns (string memory){
        if (tokenToWords[tokenId].length < (index+1) ) return "";
        return wordList[tokenToWords[tokenId].ids[index]];
    }

    /**Get Words For Token
     * @notice returns an array of all the words currently owned by a token
     * @param tokenId - { The tokenId of the phrase words being requested }
     * @dev View function for dismantle UI / sanity checks
     */
    function getWordsForToken(uint tokenId) public override view returns (string[] memory returnArr){
        
        uint lengthOfCombination = tokenToWords[tokenId].length;
        returnArr = new string[](lengthOfCombination);

        // append each word to the end of the array
        for (uint8 i=0; i < lengthOfCombination; i++){
            string memory word = getWord(i, tokenId);
            returnArr[i] = word;
        }
        return returnArr;
    }

    /**Token URI
     * @notice Constructs NFT metadata for the given tokenID 
     *         This generates info for opensea aswell as an svg
     * @param tokenId - { The tokenId being requested }
     * @dev all output is encoded into base64
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // TODO: you need to be able to search by the words aswell!!! - try set the word in the title 
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory output = constructSVG(tokenId);
        string[] memory words = getWordsForToken(tokenId);
        string memory json = SVGConstructors.jsonBuilder(tokenId, output, words);
        output = string(abi.encodePacked("data:application/json;base64,", json));
        return output;
    }

    /**Construct SVG
      * @notice Generates the NFT image containing a tokens owned words
      * @param tokenId - { the tokenId of the phrase / word being requested}
      * @dev - this does not have any uri checks associated with tokenURI and is for debugging
     */
    function constructSVG(uint tokenId) public view  returns (string memory){ 
       
        uint lengthOfCombination = tokenToWords[tokenId].length;
        uint length = 6 + lengthOfCombination;
        string[] memory parts = new string[](length);
       
        // start svg
        for (uint8 i = 0; i < 5; i++){
            parts[i] = svgStyleString[i];
        }
        // series of tspans in duos
        uint256 partsCounter = 5;
        for (uint8 i=0; i < lengthOfCombination; i = i + 2){
            string memory word1 = getWord(i, tokenId);
            string memory word2 = getWord(i+1, tokenId);
            string memory offset = SVGConstructors.getOffset(i, lengthOfCombination);
            string memory line = SVGConstructors.constructLine(word1, word2, offset);
            parts[partsCounter] = line;
            partsCounter++;
        }

        // close text & svg
        parts[partsCounter] = '</text></svg>';
        string memory constructed;
        for (uint8 i =0; i <= partsCounter; i++){
            constructed = SVGConstructors.concat(constructed, parts[i]) ;
        }
        return string(constructed);
    }

    /** Get Word
     * @notice returns the tokenId that will be used for the next auction
     * @dev TODO will the access modifier get changed!
     */
    function getNextWord() view external override returns (uint) {
        return currentAuctionTokenId;
    }

    /**Mint from Auction
     * @notice The method the auction contract will call to mint the auction winners token into the current colleciton
     * @param to        - { the address that won the auction }
     * @param tokenId   - { the tokenId that the auction was for }
     * @param word      - { the word that won the auction }
     * @dev Only callable by the current auction contract
     */
    function mintFromAuction(address to, uint tokenId, string memory word) external override onlyMinter {
        require(currentAuctionTokenId==tokenId, "IncorrectAuction");

        wordList[currentAuctionTokenId] = word;
        
        // set the token details map to defaults
        tokenToWords[currentAuctionTokenId].ids = [currentAuctionTokenId];
        tokenToWords[currentAuctionTokenId].length = 1;
        claimed[word] = true;

        _safeMint(to, currentAuctionTokenId);
        
        currentAuctionTokenId++;
    }

    /** Pause
     * @notice OpenZep pause
     * @dev Only callable by owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /** Pauses
     * @notice OpenZep unpause
     * @dev Only callable by owner
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**Claim 
    * @notice  A claim function inspired by UniSwaps Merkle Distributor - it checks that the word provided 
    *          exists within the lexicon word list. 
     * @param index         - { The index of the word being claimed }
     * @param account       - { The address claiming the word } 
     * @param word          - { The word being claimed } 
     * @param merkleProof   - { A proof that the word is in the lexicon wordlist - 
     *                        This is done through the UI to ensure random distribution of words in the free mint }
     * @dev Only when not paused
     */
    function claim(uint256 index, address account, string calldata word, bytes32[] calldata merkleProof)  external override  whenNotPaused nonReentrant {
        require(!claimed[word], "Lexicon:AlreadyClaimed");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encode(word, index));
        require(verify(merkleProof, merkleRoot, node), 'Lexicon:InvalidProof');

        // Mark it claimed and send the token.
        wordList[index] = word;
        
        // set to the defaults
        tokenToWords[index].ids = [index];
        tokenToWords[index].length = 1;
        claimed[word] = true;

        _safeMint(account, index);
    
        emit Claimed(index, account, word);
    }

    /**
     * @notice from Uniswap merkle distributor
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }


    /**
     * @notice Allows owner to withdraw amount
     */
    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}