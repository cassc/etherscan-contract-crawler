// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IToken.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../interfaces/IRandomNumberProvider.sol";
import "../interfaces/IRandomNumberRequester.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


contract LockableRevealERC721EnumerableToken is IToken, ERC721Enumerable, Ownable {
    using Strings  for uint256;

    IRegistryConsumer   immutable   public TheRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
    string              constant    public REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV1";

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
        string memory   _name, 
        string memory   _symbol,
        string memory   _tokenPreRevealURI,
        string memory   _tokenRevealURI,        
        bool            _transferLocked,
        uint256         _reservedSupply,
        uint256         _giveawaySupply,
        string memory   _contractURI
    ) ERC721(_name, _symbol) {
        projectID           = _projectID;
        tokenPreRevealURI   = _tokenPreRevealURI;
        tokenRevealURI      = _tokenRevealURI;
        maxSupply           = _maxSupply;
        transferLocked      = _transferLocked;
        reservedSupply      = _reservedSupply;
        giveawaySupply      = _giveawaySupply;

        contractURI         = _contractURI;
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
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, ++mintedSupply);
        }
    }

    /**
     * @dev Admin: mint reserved cards.
     *   Should only mint reserved AFTER the sale is over.
     */
    function mintReservedCards(uint256 numberOfCards, address recipient) external onlyAllowed {
        require(lastRevealRequested, "Token: Last reveal must be requested first");
        require(mintedReserve + numberOfCards <= reservedSupply - giveawaySupply, "Token: This would exceed the number of cards reserved cards available");
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, mintedSupply+ ++mintedReserve);
        }
    }

    /**
     * @dev DropRegistry util
     */
    function getFirstGiveawayCardId() public view returns (uint256) {
        return mintedSupply + reservedSupply - giveawaySupply + 1;
    }

    /**
     * @dev OpenSea will refuse to display tokens that never had a "Transfer" event.
     *   To get around this, we can call this method
     *
     *   Notes:
     *   ** Does not increase collection supply ( that only happens when we actually mint )
     *   ** Listing has no owner 
     *
     *   Will most likely never get used.
     */
    function OpenSeaHackForGiveawayCards(uint256 _start, uint256 _count) external onlyAllowed {
        require(lastRevealRequested, "Token: Last reveal must be requested first");
        require(mintedReserve == reservedSupply - giveawaySupply, "Token: Must mint reserved cards first");
        uint256 firstIndex = getFirstGiveawayCardId();
        uint256 lastIndex = firstIndex + giveawaySupply;
        require( _start >= firstIndex, "Token: _start must be higher or equal to firstIndex" );
        require( _start + _count <= lastIndex, "Token: _end must be lower or equal to lastIndex" );

        for(uint256 i = _start; i < _start + _count; i++) {
            emit Transfer(address(0), address(this), i);
        }
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
    function revealAtCurrentSupply() public onlyAllowed {
        require(!lastRevealRequested, "Token: Last reveal already requested");
        require(reveals[currentRevealCount].RANGE_END < mintedSupply, "Token: Reveal request already exists");
        revealStruct storage currentReveal = reveals[++currentRevealCount];
        currentReveal.RANGE_END = mintedSupply;
        currentReveal.REQUEST_ID = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
    }

    /**
     * @dev Admin: reveal tokens starting at prev range end to max supply
     */
    function lastReveal() public onlyAllowed {
        require(!lastRevealRequested, "Token: Last reveal already requested");
        require(reveals[currentRevealCount].RANGE_END < maxSupply, "Token: Reveal request already exists");
        lastRevealRequested = true;
        revealStruct storage currentReveal = reveals[++currentRevealCount];
        currentReveal.RANGE_END = mintedSupply + reservedSupply;
        currentReveal.REQUEST_ID = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
    }

    /**
     * @dev Chainlink VRF callback
     */
    function process(uint256 _random, bytes32 _requestId) external {

        require(msg.sender == TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT), "Token: process() Unauthorised caller");

        revealStruct storage currentReveal = reveals[currentRevealCount];
        if(currentReveal.REQUEST_ID == _requestId) {
            currentReveal.RANDOM_NUM = _random / 2; // Set msb to zero
            currentReveal.RANGE_START = reveals[currentRevealCount-1].RANGE_END;
            currentReveal.SHIFT = currentReveal.RANDOM_NUM % ( currentReveal.RANGE_END - currentReveal.RANGE_START );
            
            // in the very rare case where the shifting result is 0, do it again but divide by 3
            if(currentReveal.SHIFT == 0) {
                currentReveal.RANDOM_NUM = currentReveal.RANDOM_NUM / 3;
                currentReveal.SHIFT = currentReveal.RANDOM_NUM % ( currentReveal.RANGE_END - currentReveal.RANGE_START );
            }

            emit RandomProcessed(
                currentRevealCount,
                currentReveal.RANDOM_NUM,
                currentReveal.SHIFT,
                currentReveal.RANGE_START,
                currentReveal.RANGE_END
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