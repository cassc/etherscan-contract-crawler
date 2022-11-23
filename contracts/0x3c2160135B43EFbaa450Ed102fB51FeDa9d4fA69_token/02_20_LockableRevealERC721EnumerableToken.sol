// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IToken.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../interfaces/IRandomNumberProvider.sol";
import "../interfaces/IRandomNumberRequester.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


contract LockableRevealERC721EnumerableToken is IToken, ERC721Enumerable, Ownable, BlackHolePrevention {
    using Strings  for uint256;

    IRegistryConsumer   immutable   public TheRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
    string              constant    public REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV2_SSP";

    uint256             immutable   public projectID;
    uint256             immutable   public maxSupply;
    uint256                         public mintedSupply;    // minted incrementally
    uint256                         public mintedReserve;   
    uint256             immutable   public reservedSupply;  // includes giveaway supply
    uint256             immutable   public giveawaySupply;

    string                          public tokenPreRevealURI;
    string                          public tokenRevealURI;
    bool                            public transferLocked;
    bool                            public lastRevealRequested;

    mapping (address => bool)       public permitted;

    mapping(uint16 => revealStruct) public reveals;
    mapping(uint256 => uint16)      public requestToRevealId;
    string                          public revealURI;
    uint16                          public currentRevealCount;
    string                          public contractURI;

    event Allowed(address, bool);
    event Locked(bool);
    event RandomProcessed(uint256 stage, uint256 randNumber, uint256 _shiftsBy, uint256 _start, uint256 _end);
    event ContractURIset(string contractURI);

    constructor(
        uint256         _projectID, 
        uint256         _maxSupply,
        string memory   _721name, 
        string memory   _721symbol,
        string memory   _tokenPreRevealURI,
        string memory   _tokenRevealURI,        
        bool            _transferLocked,
        uint256         _reservedSupply,
        uint256         _giveawaySupply
    ) ERC721(_721name, _721symbol) {
        projectID           = _projectID;
        tokenPreRevealURI   = _tokenPreRevealURI;
        tokenRevealURI      = _tokenRevealURI;
        maxSupply           = _maxSupply;
        transferLocked      = _transferLocked;
        reservedSupply      = _reservedSupply;
        giveawaySupply      = _giveawaySupply;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override {
        require(!transferLocked, "Token: Transfers are not enabled");
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    /**
     * @dev Sale: mint cards.
     */
    function mintIncrementalCards(uint256 numberOfCards, address recipient) external onlyAllowed {
        require(!lastRevealRequested, "Token: Cannot mint after last reveal");
        require(mintedSupply + numberOfCards <= maxSupply - reservedSupply, "Token: This would exceed the number of cards available");
        uint256 mintId = mintedSupply + 1;
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, mintId++);
        }
        mintedSupply+=numberOfCards;
    }

    /**
     * @dev Admin: mint reserved cards.
     *   Should only mint reserved AFTER the sale is over.
     */
    function mintReservedCards(uint256 numberOfCards, address recipient) external onlyAllowed {
        require(lastRevealRequested, "Token: Last reveal must be requested first");
        require(mintedReserve + numberOfCards <= reservedSupply - giveawaySupply, "Token: This would exceed the number of cards reserved cards available");
        uint256 mintId = mintedSupply + mintedReserve + 1;
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, mintId++);
        }
        mintedReserve+=numberOfCards;
    }

    /**
     * @dev DropRegistry util
     */
    function getFirstGiveawayCardId() public view returns (uint256) {
        return mintedSupply + reservedSupply - giveawaySupply + 1;
    }

    /**
     * @dev DropRegistry: mint specific giveaway card.
     *   Can only mint after reserve has been minted.
     */
    function mintGiveawayCard(uint256 _index, address _recipient) external onlyAllowed {
        require(lastRevealRequested, "Token: Last reveal must be requested first");
        require(mintedReserve == reservedSupply - giveawaySupply, "Token: Must mint reserved cards first");
        uint256 firstIndex = getFirstGiveawayCardId();
        require( _index >= firstIndex && _index < firstIndex + giveawaySupply, "Token: Card id not in range");
        _mint(_recipient, _index);
    }

    /**
     * @dev Admin: set PreRevealURI
     */
    function setPreRevealURI(string calldata _tokenPreRevealURI) external onlyAllowed {
        tokenPreRevealURI = _tokenPreRevealURI;
    }

    /**
     * @dev Admin: set RevealURI
     */
    function setRevealURI(string calldata _tokenRevealURI) external onlyAllowed {
        tokenRevealURI = _tokenRevealURI;
    }

    /**
     * @dev Admin: reveal tokens starting at prev range end to current supply
     */
    function revealAtCurrentSupply() external onlyAllowed {
        require(!lastRevealRequested, "Token: Last reveal already requested");
        require(reveals[currentRevealCount].RANGE_END < mintedSupply, "Token: Reveal request already exists");
        revealStruct storage currentReveal = reveals[++currentRevealCount];
        currentReveal.RANGE_END = mintedSupply;
        currentReveal.REQUEST_ID = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
        requestToRevealId[currentReveal.REQUEST_ID] = currentRevealCount;
    }

    /**
     * @dev Admin: reveal tokens starting at prev range end to max supply
     */
    function lastReveal() external onlyAllowed {
        require(!lastRevealRequested, "Token: Last reveal already requested");
        require(reveals[currentRevealCount].RANGE_END < maxSupply, "Token: Reveal request already exists");
        lastRevealRequested = true;
        revealStruct storage currentReveal = reveals[++currentRevealCount];
        currentReveal.RANGE_END = mintedSupply + reservedSupply;
        currentReveal.REQUEST_ID = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
        requestToRevealId[currentReveal.REQUEST_ID] = currentRevealCount;
    }

    /**
     * @dev Chainlink VRF callback
     */
    function process(uint256 _random, uint256 _requestId) external {

        require(msg.sender == TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT), "Token: process() Unauthorised caller");

        // get reveal using _requestId
        uint16 thisRevealId = requestToRevealId[_requestId];
        revealStruct storage thisReveal = reveals[thisRevealId];

        require(!thisReveal.processed, "Token: reveal already processed.");

        if(thisReveal.REQUEST_ID == _requestId) {
            thisReveal.RANDOM_NUM = _random / 2; // Set msb to zero

            // in the very rare case where RANDOM_NUM is 0, use currentReveal.RANGE_END / 3
            if(thisReveal.RANDOM_NUM == 0) {
                thisReveal.RANDOM_NUM = thisReveal.RANGE_END * (10 ** 5) / 3;
            }

            thisReveal.RANGE_START = reveals[currentRevealCount-1].RANGE_END;
            thisReveal.SHIFT = thisReveal.RANDOM_NUM % ( thisReveal.RANGE_END - thisReveal.RANGE_START );
            
            // in the very rare case where the shifting result is 0, do it again but divide by 3
            if(thisReveal.SHIFT == 0) {
                thisReveal.RANDOM_NUM = thisReveal.RANDOM_NUM / 3;
                thisReveal.SHIFT = thisReveal.RANDOM_NUM % ( thisReveal.RANGE_END - thisReveal.RANGE_START );
            }

            thisReveal.processed = true;

            emit RandomProcessed(
                thisRevealId,
                thisReveal.RANDOM_NUM,
                thisReveal.SHIFT,
                thisReveal.RANGE_START,
                thisReveal.RANGE_END
            );

        } else revert("Token: Incorrect requestId received");
    }


    function findRevealRangeForN(uint256 n) public view returns (uint16) {
        for(uint16 i = 1; i <= currentRevealCount; i++) {
            if(n <= reveals[i].RANGE_END) {
                return i;
            }
        }
        return 0;
    }

    function uri(uint256 n) public view returns (uint256) {
        uint16 rangeId = findRevealRangeForN(n); 
        // outside ranges
        if(rangeId == 0) {
            return n;
        }

        revealStruct memory currentReveal = reveals[rangeId];
        uint256 shiftedN = n + currentReveal.SHIFT;
        if (shiftedN <= currentReveal.RANGE_END) {
            return shiftedN;
        }
        return currentReveal.RANGE_START + shiftedN - currentReveal.RANGE_END;
    }

    /**
    * @dev Reserved are always at the end of current minted 
    */
    function _reserved(uint256 _tokenId) public view returns (bool) {
        if(_tokenId > mintedSupply + mintedReserve && _tokenId <= mintedSupply + reservedSupply) {
            return true;
        }
        return false;
    }

    /**
    * @dev Get metadata server url for tokenId
    */
    function tokenURI(uint256 _tokenId) public view override(IToken, ERC721) returns (string memory) {
        require(_exists(_tokenId) || _reserved(_tokenId), 'Token: Token does not exist');

        uint16 rangeId = findRevealRangeForN(_tokenId);
        // outside ranges
        if(rangeId == 0) {
            return tokenPreRevealURI;
        }

        revealStruct memory currentReveal = reveals[rangeId];

        // if random number was not set, return pre reveal
        // TODO: most likely remove this.. as we never get here.. we're already outside range
        if(currentReveal.RANDOM_NUM == 0) {
            return tokenPreRevealURI;
        }

        uint256 newTokenId = uri(_tokenId);        
        string memory folder = (newTokenId % 100).toString(); 
        string memory file = newTokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(tokenRevealURI, folder, slash, file));
    }

    /**
     * @dev Admin: Lock / Unlock transfers
     */
    function setTransferLock(bool _locked) external onlyAllowed {
        transferLocked = _locked;
        emit Locked(_locked);
    }

    /**
     * @dev Admin: Allow / Dissalow addresses
     */
    function setAllowed(address _addr, bool _state) external onlyOwner {
        permitted[_addr] = _state;
        emit Allowed(_addr, _state);
    }

    function isAllowed(address _addr) public view returns(bool) {
        return permitted[_addr] || _addr == owner();
    }

    modifier onlyAllowed() {
        require(isAllowed(msg.sender), "Token: Unauthorised");
        _;
    }

    function tellEverything() external view returns (TokenInfo memory) {
        
        revealStruct[] memory _reveals = new revealStruct[](currentRevealCount);
        for(uint16 i = 1; i <= currentRevealCount; i++) {
            _reveals[i - 1] = reveals[i];
        }

        return TokenInfo(
            name(),
            symbol(),
            projectID,
            maxSupply,
            mintedSupply,
            mintedReserve,
            reservedSupply,
            giveawaySupply,
            tokenPreRevealURI,
            tokenRevealURI,
            transferLocked,
            lastRevealRequested,
            totalSupply(),
            _reveals
        );
    }

    function getTokenInfoForSale() external view returns (TokenInfoForSale memory) {
        return TokenInfoForSale(
            projectID,
            maxSupply,
            reservedSupply
        );
    }

    function setContractURI(string memory _contractURI) external onlyAllowed {
        contractURI = _contractURI;
        emit ContractURIset(_contractURI);
    }
}