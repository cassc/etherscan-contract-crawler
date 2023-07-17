// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './libraries/ERC721A.sol';
import "./interfaces/IWord.sol";
import "./interfaces/IMintverseWord.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * ███╗   ███╗██╗███╗   ██╗████████╗██╗   ██╗███████╗██████╗ ███████╗███████╗    ██╗    ██╗ ██████╗ ██████╗ ██████╗ 
 * ████╗ ████║██║████╗  ██║╚══██╔══╝██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    ██║    ██║██╔═══██╗██╔══██╗██╔══██╗
 * ██╔████╔██║██║██╔██╗ ██║   ██║   ██║   ██║█████╗  ██████╔╝███████╗█████╗      ██║ █╗ ██║██║   ██║██████╔╝██║  ██║
 * ██║╚██╔╝██║██║██║╚██╗██║   ██║   ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      ██║███╗██║██║   ██║██╔══██╗██║  ██║
 * ██║ ╚═╝ ██║██║██║ ╚████║   ██║    ╚████╔╝ ███████╗██║  ██║███████║███████╗    ╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝
 * ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝     ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝     ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ 
 *                                                                                                        @ryanycw                                                                                                             
 *                                                                                                                                                                                     
 *      第二宇宙辭典 鑄造宣言
 *   1. 即使舊世界的文明已經滅亡，我們仍相信文字保存了曾有的宇宙。
 *   2. 我們不排斥嶄新的當代文明，只是相信古老的符號裡，仍含有舊世界人類獨得之奧秘。
 *   3. 我們不相信新世界與舊世界之間，是毫無關聯的兩個文明。
 *   4. 我們相信在最簡單的線條裡，有最豐滿的形象、顏色與場景。
 *   5. 我們確知一切最複雜的思想，必以最單純的音節組成。
 *   6. 我們相信文字永不衰亡，只是沉睡。喚醒文字的方式，便是釋義、辨析、定義、區分⋯⋯。
 *   7. 我們不執著於「正確」，我們更信任「想像」。因為，從線條聯想物象，音節捕捉概念，正是人類文明的輝煌起點。
 *   8. 它是什麼意思；它不是什麼意思——這些都很重要。但最重要的是：它「還可以」是什麼意思？
 *   9. 我們熱愛衝突，擁抱矛盾，因為激烈碰撞所能引出的奧秘，遠勝於眾口一聲的意見。   
 *  10. 我們堅決相信：在我們降生群聚的第一宇宙之外、之間、之前、之後，還有一個值得我們窮盡想像力去探索的第二宇宙。
 */ 

contract IMintverseWordStorage is IWord {
    // Metadata Variables
    mapping(uint256 => TokenInfo) public tokenItem;
    // Mint Record Variables
    mapping(address => bool) public mintedByAddress;
    mapping(address => bool) public purchaseDictionaryCheckByAddress;
    mapping(address => uint256) public whitelistMintAmount;
    // Phase Limitation Variables
    bool public mintWhitelistEnable;
    bool public mintPublicEnable;
    uint256 public mintWhitelistTimestamp;
    uint256 public mintPublicTimestamp;
    uint48 public revealTimestamp;
    // Mint Record Variables
    uint16 public totalDictionary;
	uint16 public totalWordGiveaway;
    uint16 public totalWordWhitelist;
    // Mint Limitation Variables
    uint256 public MAX_MINTVERSE_RANDOM_WORD;
    uint256 public MAX_MINTVERSE_GIVEAWAY_WORD;
    uint256 public MAX_MINTVERSE_DICTIONARY;
    uint256 public DICT_ADDON_PRICE;
    uint48 public WORD_EXPIRATION_TIME;
    uint16 public HEAD_RANDOM_WORDID;
    uint16 public TAIL_RANDOM_WORDID;
    uint16 public SETTLE_HEAD_TOKENID;
    uint16 public DESIGNATED_WORDID_OFFSET;
    // Governance Variables
	address public treasury;
    string public baseTokenURI;
    // Mapping Off-Chain Storage
    string public legalDocumentURI;
    string public systemMechanismDocumentURI;
    string public animationCodeDocumentURI;
    string public visualRebuildDocumentURI;
    string public ERC721ATechinalDocumentURI;
    string public wordIdMappingDocumnetURI;
    string public partOfSpeechIdMappingDocumentURI;
    string public categoryIdMappingDocumentURI;
    string public metadataMappingDocumentURI;
}

contract MintverseWord is IMintverseWord, IMintverseWordStorage, Ownable, EIP712, ERC721A {

    using SafeMath for uint16;
    using SafeMath for uint48;
    using SafeMath for uint256;
	using Strings for uint256;

    constructor()
    EIP712("MintverseWord", "1.0.0")
    ERC721A("MintverseWord", "MVW")     
    {
        mintWhitelistEnable = true;
        mintPublicEnable = true;
        mintWhitelistTimestamp = 1651752000;
        mintPublicTimestamp = 1652155200;
        revealTimestamp = 1652068800;

        MAX_MINTVERSE_RANDOM_WORD = 1900;
        MAX_MINTVERSE_GIVEAWAY_WORD = 200;
        MAX_MINTVERSE_DICTIONARY = 185;
        DICT_ADDON_PRICE = 0.15 ether;
        WORD_EXPIRATION_TIME = 42 hours;
        TAIL_RANDOM_WORDID = 1900;
        SETTLE_HEAD_TOKENID = TAIL_RANDOM_WORDID;
        DESIGNATED_WORDID_OFFSET = uint16(TAIL_RANDOM_WORDID.mul(2));

        treasury = 0xbA53C6831B496c8a40c02A3c2d1366DfC6503F4e;
        baseTokenURI = "https://api.mintverse.world/word/metadata/";
        legalDocumentURI = "";
        systemMechanismDocumentURI = "";
        animationCodeDocumentURI = "";
        visualRebuildDocumentURI = "";
        ERC721ATechinalDocumentURI = "";
        wordIdMappingDocumnetURI = "";
        partOfSpeechIdMappingDocumentURI = "";
        categoryIdMappingDocumentURI = "";
        metadataMappingDocumentURI = "";
    }

    /**
     * Modifiers
     */
    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownershipOf(tokenId).addr == msg.sender, "Can't define - Not the word owner");
        _;
    }

    modifier mintWhitelistActive() {
		require(mintWhitelistEnable == true, "Can't mint - WL mint phase hasn't enable");
        require(block.timestamp >= mintWhitelistTimestamp, "Can't mint - WL mint phase hasn't started");
        _;
    }

    modifier mintPublicActive() {
		require(mintPublicEnable == true, "Can't mint - Public mint phase hasn't enable");
        require(block.timestamp >= mintPublicTimestamp, "Can't mint - Public mint phase hasn't started");
        _;
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Invalid caller - Caller is a Contract");
        _;
    }

    modifier wordNotExpired(uint256 tokenId){
        require((block.timestamp > tokenItem[tokenId].mintTime) || tokenItem[tokenId].defined, "Invalid Block Time - Mint time shouldn't be larger than current time");
        require((block.timestamp <= (tokenItem[tokenId].mintTime + WORD_EXPIRATION_TIME)) || tokenItem[tokenId].defined, "Invalid Block Time - This token is expired");
        _;
    }

    /**
     * Verify Functions
     */
    /** @dev Verify if a address is eligible to mint a specific amount
     * @param SIGNATURE Signature used to verify the minter address and amount of claimable tokens
     */
    function verify(
        uint256 maxQuantity,
        bytes calldata SIGNATURE
    ) 
        public 
        override
        view 
        returns(bool)
    {
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("NFT(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);
        return owner() == recoveredAddr;
    }

    /**
     * Mint Functions
     */
    /** @dev Record dictionary addon for a an address as owner
     * @param to Address to record dictionary addon
     * @param addon True if recording giveaway dictionary to the "to" address, otherwise false
     */
    function mintGiveawayDictionary(
        address to, 
        bool addon
    ) 
        external
        override
        onlyOwner
    {   
        _mintGiveawayDictionary(to, addon);
    }

    /** @dev Mint word token to an address with specific amount of tokens as owner
     * @param to Address to transfer the tokens
     * @param wordId Designated wordId of the giveaway tokens
     * @param mintTimestamp Timestamp to start the countdown for expiration
     */
    function mintGiveawayWord(
        address to, 
        uint16 wordId,
        uint48 mintTimestamp
    ) 
        external
        override
        onlyOwner
    {   
        require(totalWordGiveaway.add(1) <= MAX_MINTVERSE_GIVEAWAY_WORD, "Exceed maximum word amount");
        totalWordGiveaway = uint16(totalWordGiveaway.add(1));
        _mintDesignatedWord(to, wordId, mintTimestamp);

		emit mintWordEvent(to, 1, totalSupply());
    }

    /** @dev Mint word token as Whitelisted Address
     * @param quantity Amount of tokens the address wants to mint
     * @param maxClaimNum Maximum amount of word tokens the address can mint
     * @param addon True if recording giveaway dictionary to the "to" address, otherwise false
     * @param SIGNATURE Signature used to verify the minter address and amount of claimable tokens
     */
    function mintWhitelistWord(
        uint256 quantity,
        uint256 maxClaimNum, 
        bool addon,
        bytes calldata SIGNATURE
    ) 
        external 
        payable
        override
        mintWhitelistActive
        callerIsUser
    {
        require(verify(maxClaimNum, SIGNATURE), "Can't claim - Not eligible");
        require(_getRandomWordMintCnt().add(quantity) <= MAX_MINTVERSE_RANDOM_WORD, "Exceed maximum word amount");
        require(quantity > 0 && whitelistMintAmount[msg.sender].add(quantity) <= maxClaimNum, "Exceed maximum mintable whitelist amount");
        
        mintedByAddress[msg.sender] = true;
        whitelistMintAmount[msg.sender] = whitelistMintAmount[msg.sender].add(quantity);
        totalWordWhitelist = uint16(totalWordWhitelist.add(quantity));
        _mintPublicDictionary(msg.sender, addon);

        for(uint16 index=0; index < quantity; index++) {
            _mintRandomWord(msg.sender);
        }
        
        emit mintWordEvent(msg.sender, quantity, totalSupply());
    }

    /** @dev Mint word token as Public Address
     * @param addon True if recording giveaway dictionary to the "to" address, otherwise false
     */
    function mintPublicWord(
        bool addon
    )
        external
        payable 
        override
        mintPublicActive
        callerIsUser
    {
        require(mintedByAddress[msg.sender]==false, "Already minted you naughty, leave some word for others");
        require(_getRandomWordMintCnt().add(1) <= MAX_MINTVERSE_RANDOM_WORD, "Exceed maximum word amount");
            
        mintedByAddress[msg.sender] = true;
        _mintPublicDictionary(msg.sender, addon);
        _mintRandomWord(msg.sender);

        emit mintWordEvent(msg.sender, 1, totalSupply());
    }

    /** @dev Calculate the token counts for random words, which is total supply substract the giveaway amount
     */
    function _getRandomWordMintCnt()
        private
        view
        returns(uint16 randomWordMintCnt)
    {
        return uint16(totalSupply().sub(totalWordGiveaway));
    }

    /** @dev Calculate the token timestamp for expiration calculation
     *       If the mint timestamp is before reveal, then set at reveal
     *       If the mint timestamp is after reveal, then set at mint current time
     */
    function _getCurWordTimestamp()
        private
        view
        returns(uint48 curWordTimestamp)
    {
        if(block.timestamp <= revealTimestamp) return revealTimestamp;
        else return uint48(block.timestamp);
    }

    /** @dev Calculate the token's corresponding wordId
     *       If the random token count is smaller than the initial maximum random count, then circulate with the maximum random count - (0 - 1899)
     *       If the token is minted after some tokens are dead, then start from the end of the maximum random count - (1900 - 3799)
     */
    function _getCurWordId()
        private
        view
        returns(uint16 curWordId)
    {
        if(_getRandomWordMintCnt() < TAIL_RANDOM_WORDID) return HEAD_RANDOM_WORDID % TAIL_RANDOM_WORDID;
        else return uint16(_getRandomWordMintCnt());
    }

    /** @dev Set the initial point of the random wordId mapping, using the 1st minter's address and the timestamp
     */
    function _setHeadWordId()
        private
    {
        HEAD_RANDOM_WORDID = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)))) % TAIL_RANDOM_WORDID;
    }

    /** @dev Called by #mintWhitelistWord and #mintPublicWord to mint random words
     * @param to Address to mint the tokens to
     */
    function _mintRandomWord(address to)
        private
    {
        if((totalSupply() - totalWordGiveaway) == 0) _setHeadWordId();

        HEAD_RANDOM_WORDID = uint16(HEAD_RANDOM_WORDID.add(1));
        _mintWord(to, _getCurWordId(), _getCurWordTimestamp());
    }

    /** @dev Called by #mintGiveawayWord to mint the designated words
     * @param to Address to mint the tokens to
     * @param designatedWordId Designated wordId of the giveaway tokens
     * @param mintTimestamp Timestamp to start the countdown for expiration, since the receiver might not be able to start 
     */
    function _mintDesignatedWord(
        address to, 
        uint16 designatedWordId,
        uint48 mintTimestamp
    )
        private
    {
        require(designatedWordId >= DESIGNATED_WORDID_OFFSET, "Invalid wordId - This Id belongs to random Id");
        _mintWord(to, designatedWordId, mintTimestamp);
    }

    /** @dev Called by #_mintDesignatedWord and #_mintRandomWord to mint tokens
     * @param to Address to mint the tokens to
     * @param wordId wordId of the tokens
     * @param mintTimestamp Timestamp to start the countdown for expiration, since the receiver might not be able to start 
     */
    function _mintWord(
        address to,
        uint16 wordId,
        uint48 mintTimestamp
    )
        private
    {
        string memory nullString;

        _safeMint(to, 1);

        tokenItem[totalSupply().sub(1)] = TokenInfo(nullString, nullString, nullString, wordId, 1, 1, 1, mintTimestamp, false);
    }
    
    /** @dev Called by #mintGiveawayWord to record dictionary addon of an address
     * @param to Address to record dictionary addon
     * @param addon True or False, of whether the address wants to purchase the addon
     */
    function _mintPublicDictionary(
        address to,
        bool addon
    )
        private
    {
        _mintDictionary(to, addon, false);
    }

    /** @dev Called by #mintPublicWord and #mintWhitelistWord to record giveaway dictionary addon of an address
     * @param to Address to record dictionary addon
     * @param addon True or False, of whether the address wants to purchase the addon
     */
    function _mintGiveawayDictionary(
        address to,
        bool addon
    )
        private
    {
        _mintDictionary(to, addon, true);
    }

    /** @dev Called by #_mintPublicDictionary and #_mintGiveawayDictionary to record dictionary addon of an address
     * @param to Address to record dictionary addon
     * @param addon True or False, whether the address wants to purchase the addon
     * @param giveaway True or False, whether to check the msg.value 
     *
     * A = Purchase addon dictionary
     * B = Check addon status if caller address purchased already
     * T_A, T_B => No need msg.value, No modification of addon status
     * F_A, T_B => No need msg.value, No modification of addon status
     * T_A, F_B => Need msg.value, Modification of addon status
     * F_A, F_B => No need msg.value, No modification of addon status
     *
     */
    function _mintDictionary(
        address to,
        bool addon,
        bool giveaway
    )
        private
    {
        require(totalDictionary.add(1) <= MAX_MINTVERSE_DICTIONARY, "Exceed maximum dictionary amount");
        if((addon == true) && !(purchaseDictionaryCheckByAddress[to])) {
            if(giveaway == false) require(msg.value == DICT_ADDON_PRICE, "Not the right amount of ether");
            totalDictionary = uint16(totalDictionary.add(1));
            purchaseDictionaryCheckByAddress[to] = addon;
        }
    }

    /**
     * Define Functions
     */
    /** @dev Define word token as token owner wants
     * @param tokenId TokenId that the token owner wants to define
     * @param definer 鑄造者
     * @param partOfSpeech1 詞性1
     * @param partOfSpeech2 詞性2
     * @param relatedWord 同義詞
     * @param description 詮釋
     */
    function defineWord(
        uint256 tokenId, 
        string calldata definer, 
        uint8 partOfSpeech1,
        uint8 partOfSpeech2,
        string calldata relatedWord, 
        string calldata description
    )
        external 
        override
        onlyTokenOwner(tokenId)
        wordNotExpired(tokenId)
    {
        tokenItem[tokenId].definerPart = definer;
        tokenItem[tokenId].relatedWordPart = relatedWord;
        tokenItem[tokenId].descriptionPart = description;
        tokenItem[tokenId].partOfSpeechPart1 = partOfSpeech1;
        tokenItem[tokenId].partOfSpeechPart2 = partOfSpeech2;
        tokenItem[tokenId].defined = true;
        if (tokenItem[tokenId].categoryPart == 2) tokenItem[tokenId].categoryPart = 1;

        emit wordDefinedEvent(tokenId);
    }

    /**
     * Getter Functions
     */
    /** @dev Retrieve word definition metadata by tokenId
     * @param tokenId TokenId which caller wants to get its metadata
     */
    function getTokenProperties(uint256 tokenId)
        public
        view
        override
        returns (
            string memory definer, 
            uint256 wordId,
            uint256 categoryId,
            uint256 partOfSpeechId1,
            uint256 partOfSpeechId2,
            string memory relatedWord,
            string memory description
        )
    {   
        return (
            tokenItem[tokenId].definerPart,
            tokenItem[tokenId].wordPart,
            tokenItem[tokenId].categoryPart,
            tokenItem[tokenId].partOfSpeechPart1,
            tokenItem[tokenId].partOfSpeechPart2,
            tokenItem[tokenId].relatedWordPart,
            tokenItem[tokenId].descriptionPart
        );
    }

    /** @dev Retrieve expiration timestamp of a token by tokenId
     * @param tokenId TokenId which caller wants to get its expiration timestamp
     */
    function getTokenExpirationTime(uint256 tokenId)
        public
        view
        override
        returns(uint256 expirationTime)
    {
        return tokenItem[tokenId].mintTime.add(WORD_EXPIRATION_TIME);
    }

    /** @dev Retrieve the status whether a token has been written by tokenId
     * @param tokenId TokenId which caller wants to get its status of written or not
     */
    function getTokenStatus(uint256 tokenId)
        public
        view
        override
        returns(bool writtenOrNot)
    {
        return tokenItem[tokenId].defined;
    }

    /** @dev Retrieve all word definition metadatas by owner address
     * @param owner Address which caller wants to get all of its metadatas of tokens
     */
    function getTokenPropertiesByOwner(address owner) 
        public 
        view 
        override
        returns (TokenInfo[] memory tokenInfos)
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new TokenInfo[](0);
        } else {
            TokenInfo[] memory result = new TokenInfo[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, index);
                result[index] = tokenItem[tokenId];
            }
            return result;
        }
    }

    /** @dev Retrieve all expiration timestamps by owner address
     * @param owner Address which caller wants to get all of its expiration timestamps of tokens
     */
    function getTokenExpirationTimeByOwner(address owner) 
        public 
        view 
        override
        returns (uint256[] memory expirationTimes)
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, index);
                result[index] = tokenItem[tokenId].mintTime.add(WORD_EXPIRATION_TIME);
            }
            return result;
        }
    }

    /** @dev Retrieve all defined status of the word tokens by owner address
     * @param owner Address which caller wants to get all its word token defined statuses
     */
    function getTokenStatusByOwner(address owner) 
        public 
        view 
        override
        returns (bool[] memory writtenOrNot)
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new bool[](0);
        } else {
            bool[] memory result = new bool[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, index);
                result[index] = tokenItem[tokenId].defined;
            }
            return result;
        }
    }

    /** @dev Retrieve if a address has purchased the dictionary
     * @param owner Address which caller wants to get if it has purchased the dictionary
     */
    function getAddonStatusByOwner(address owner) 
        public 
        view 
        override
        returns (bool addon)
    {
        return purchaseDictionaryCheckByAddress[owner];
    }

    /**
     * Token Functions
     */
    /** @dev Retrieve token URI to get the metadata of a token
     * @param tokenId TokenId which caller wants to get the metadata of
     */
	function tokenURI(uint256 tokenId) 
        public 
        view 
        override 
        returns (string memory curTokenURI) 
    {
		require(_exists(tokenId), "Token doesn't exist");
		return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
	}

    /** @dev Retrieve all tokenIds of a given address
     * @param owner Address which caller wants to get all of its tokenIds
     */
    function tokensOfOwner(address owner) 
        external 
        view 
        override
        returns(uint256[] memory) 
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    /** @dev Retrieve dictionary tokens supply amount
     */
    function getTotalDictionary() 
        public
        view
        override 
        returns (uint256 amount)
    {
        return uint256(totalDictionary);
    }

    /** @dev Retrieve all tokenIds of a given address
     * @param startTokenId Address which caller wants to get all of its tokenIds
     * @param endTokenId test
     * If the token is undefined & have passed 42 hours after mint time, then we settle the token
     */
    function settleExpiredWord(
        uint256 startTokenId, 
        uint256 endTokenId
    )
        override
        external
        onlyOwner
    {
        for(uint256 index = startTokenId; index <= endTokenId; index++) {
            if(!(tokenItem[index].defined) && (block.timestamp > (tokenItem[index].mintTime + WORD_EXPIRATION_TIME))) {
                emit moveWordToTheBack(SETTLE_HEAD_TOKENID, tokenItem[index].wordPart);
                SETTLE_HEAD_TOKENID = uint16(SETTLE_HEAD_TOKENID.add(1));
                MAX_MINTVERSE_RANDOM_WORD = MAX_MINTVERSE_RANDOM_WORD.add(1);
            }
        }
    }

    /** @dev Set the status of whitelist mint phase and its starting time
     * @param _hasWLMintStarted True if the whitelist mint phase have started, otherwise false
     * @param _wlMintTimestamp After this timestamp the whitelist mint phase will be enabled
     */
    function setWLMintPhase(
        bool _hasWLMintStarted, 
        uint256 _wlMintTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        mintWhitelistEnable = _hasWLMintStarted;
        mintWhitelistTimestamp = _wlMintTimestamp;
    }

    /** @dev Set the status of public mint phase and its starting time
     * @param _hasPublicMintStarted True if the public mint phase have started, otherwise false
     * @param _publicMintTimestamp After this timestamp the public mint phase will be enabled
     */
    function setPublicMintPhase(
        bool _hasPublicMintStarted, 
        uint256 _publicMintTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        mintPublicEnable = _hasPublicMintStarted;
        mintPublicTimestamp = _publicMintTimestamp;
    }

    /** @dev Set the price to purchase dictionary tokens.
     * @param price New price that caller wants to set as the price of dictionary tokens
     */
    function setDictPrice(uint256 price) 
        override 
        external 
        onlyOwner 
    {
        DICT_ADDON_PRICE = price;
    }

    /** @dev Set the timestamp to start the expiration countdown
     * @param newRevealTimestamp Timestamp to set as the new reveal timestamp
     */
    function setRevealTimestamp(uint48 newRevealTimestamp)
        override
        external
        onlyOwner
    {
        revealTimestamp = newRevealTimestamp;
    }

    /** @dev Set the timestamp period use to calculate if a token is expired
     * @param newExpirationPeriod Timestamp to set as the new expiration period
     */
    function setExpirationTime(uint48 newExpirationPeriod)
        override
        external
        onlyOwner
    {
        WORD_EXPIRATION_TIME = newExpirationPeriod;
    }

    /** @dev Set the categoryId of a specific token
     * @param tokenId TokenId that owner wants to set categoryId
     * @param categoryId CategoryId that owner wants to set the token to
     */
    function setCategoryByTokenId(
        uint256 tokenId, 
        uint8 categoryId
    ) 
        override
        external
        onlyOwner
    {
        tokenItem[tokenId].categoryPart = categoryId;
    }

    /** @dev Set the maximum supply of random word tokens.
     * @param amount Maximum amount of random word tokens
     */
    function setMaxRandomWordTokenAmt(uint256 amount) 
        override 
        external 
        onlyOwner 
    {
        MAX_MINTVERSE_RANDOM_WORD = amount;
    }

    /** @dev Set the maximum supply of giveaway word tokens.
     * @param amount Maximum amount of giveaway word tokens
     */
    function setMaxGiveawayWordTokenAmt(uint256 amount)
        override 
        external 
        onlyOwner 
    {
        MAX_MINTVERSE_GIVEAWAY_WORD = amount;
    }

    /** @dev Set the maximum supply of dictionary tokens.
     * @param amount Maximum amount of dictionary tokens
     */
    function setMaxDictAmt(uint256 amount) 
        override 
        external 
        onlyOwner 
    {
        MAX_MINTVERSE_DICTIONARY = amount;
    }

    /** @dev Set the index of the head of random word token
     * @param index New index to set as the head index
     */
    function setHeadRandomWordId(uint16 index) 
        override 
        external 
        onlyOwner
    {
        HEAD_RANDOM_WORDID = index;
    }

    /** @dev Set the index of the tail of random word token
     * @param index New index to set as the tail index
     */
    function setTailRandomWordId(uint16 index)
        override 
        external 
        onlyOwner
    {
        TAIL_RANDOM_WORDID = index;
    }

    /** @dev Set the index of the head of settle word token
     * @param index New index to set as the settle head index
     */
    function setSettleHeadRandomWordId(uint16 index)
        override 
        external 
        onlyOwner
    {
        SETTLE_HEAD_TOKENID = index;
    }   

    /** @dev Set the offset amount of the designated wordId
     * @param offsetAmount Amount to set as the new offset amount
     */
    function setWordIdOffset(uint16 offsetAmount)
        override 
        external 
        onlyOwner
    {
        DESIGNATED_WORDID_OFFSET = offsetAmount;
    }

    /** @dev Set the wordId of a specific token
     * @param tokenId TokenId that owner wants to set its wordId
     * @param wordId WordId that owner wants to set its tokens to
     */
    function setTokenWordIdByTokenId(
        uint256 tokenId, 
        uint16 wordId
    )
        override 
        external 
        onlyOwner
    {
        tokenItem[tokenId].wordPart = wordId;
    }

    /** @dev Set the timestamp of a specific token
     * @param tokenId TokenId that owner wants to set its mint timestamp
     * @param mintTimestamp Mint timestamp that owner wants to set its tokens to
     */
    function setTokenMintTimeByTokenId(
        uint256 tokenId, 
        uint48 mintTimestamp
    ) 
        override 
        external 
        onlyOwner
    {
        tokenItem[tokenId].mintTime = mintTimestamp;
    }

    /** @dev Set the defined status of a specific token
     * @param tokenId TokenId that owner wants to set its defined status
     * @param definedOrNot Defined status that owner wants to set its tokens to
     */
    function setTokenDefineStatusByTokenId(
        uint256 tokenId, 
        bool definedOrNot
    )
        override 
        external 
        onlyOwner
    {
        tokenItem[tokenId].defined = definedOrNot;
    }

    /** @dev Set the URI for tokenURI, which returns the metadata of token.
     * @param newBaseTokenURI New URI that caller wants to set as tokenURI
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) 
        override 
        external 
        onlyOwner 
    {
		baseTokenURI = newBaseTokenURI;
	}

    /** @dev Set the URI for legalDocumentURI, which returns the URI of legal document.
     * @param newLegalDocumentURI New URI that caller wants to set as legalDocumentURI
     */
    function setLegalDocumentURI(string calldata newLegalDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		legalDocumentURI = newLegalDocumentURI;
	}

    /** @dev Set the URI for systemMechanismDocumentURI, which returns the URI of system mechanicsm document.
     * @param newSystemMechanismDocumentURI New URI that caller wants to set as systemMechanismDocumentURI
     */
    function setSystemMechanismDocumentURI(string calldata newSystemMechanismDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		systemMechanismDocumentURI = newSystemMechanismDocumentURI;
	}

    /** @dev Set the URI for animationCodeDocumentURI, which returns the URI of animation code.
     * @param newAnimationCodeDocumentURI New URI that caller wants to set as animationCodeDocumentURI
     */
    function setAnimationCodeDocumentURI(string calldata newAnimationCodeDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		animationCodeDocumentURI = newAnimationCodeDocumentURI;
	}

    /** @dev Set the URI for visualRebuildDocumentURI, which returns the URI of visual rebuild document.
     * @param newVisualRebuildDocumentURI New URI that caller wants to set as visualRebuildDocumentURI
     */
    function setVisualRebuildDocumentURI(string calldata newVisualRebuildDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		visualRebuildDocumentURI = newVisualRebuildDocumentURI;
	}

    /** @dev Set the URI for ERC721ATechinalDocumentURI, which returns the URI of ERC721A technical document.
     * @param newERC721ATechinalDocumentURI New URI that caller wants to set as ERC721ATechinalDocumentURI
     */
    function setERC721ATechinalDocumentURI(string calldata newERC721ATechinalDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		ERC721ATechinalDocumentURI = newERC721ATechinalDocumentURI;
	}

    /** @dev Set the URI for wordIdMappingDocumnetURI, which returns the URI of wordId mapping document.
     * @param newWordIdMappingDocumnetURI New URI that caller wants to set as wordIdMappingDocumnetURI
     */
    function setWordIdMappingDocumnetURI(string calldata newWordIdMappingDocumnetURI) 
        override 
        external 
        onlyOwner 
    {
		wordIdMappingDocumnetURI = newWordIdMappingDocumnetURI;
	}

    /** @dev Set the URI for partOfSpeechIdMappingDocumentURI, which returns the URI of partOfSpeechId mapping document.
     * @param newPartOfSpeechIdMappingDocumentURI New URI that caller wants to set as partOfSpeechIdMappingDocumentURI
     */
    function setPartOfSpeechIdMappingDocumentURI(string calldata newPartOfSpeechIdMappingDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		partOfSpeechIdMappingDocumentURI = newPartOfSpeechIdMappingDocumentURI;
	}

    /** @dev Set the URI for categoryIdMappingDocumentURI, which returns the URI of categoryId mapping document.
     * @param newCategoryIdMappingDocumentURI New URI that caller wants to set as categoryIdMappingDocumentURI
     */
    function setCategoryIdMappingDocumentURI(string calldata newCategoryIdMappingDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		categoryIdMappingDocumentURI = newCategoryIdMappingDocumentURI;
	}

    /** @dev Set the URI for metadataMappingDocumentURI, which returns the URI of metadata mapping document.
     * @param newMetadataMappingDocumentURI New URI that caller wants to set as metadataMappingDocumentURI
     */
    function setMetadataMappingDocumentURI(string calldata newMetadataMappingDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		metadataMappingDocumentURI = newMetadataMappingDocumentURI;
	}

    /** @dev Set the address that act as treasury and recieve all the fund from token contract.
     * @param _treasury New address that caller wants to set as the treasury address
     */
    function setTreasury(address _treasury) 
        override 
        external 
        onlyOwner 
    {
        require(_treasury != address(0), "Invalid address - Zero address");
        treasury = _treasury;
    }

    /**
     * Withdrawal Functions
     */
    /** @dev Set the maximum supply of dictionary tokens.
     */
	function withdrawAll() 
        override 
        external 
        payable 
        onlyOwner 
    {
		payable(treasury).transfer(address(this).balance);
	}
}