// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IWildlandCards.sol";

/**
 *  @title Wildlands' Member Cards
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

contract WildlandCards is ERC721Enumerable, AccessControlEnumerable, Ownable {
    using SafeERC20 for IERC20;
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool public isLocked;
    string public baseURI;
    Counters.Counter public bitId;
    Counters.Counter public goldId;
    Counters.Counter public blackId;
    Counters.Counter public standardId;
    // codes of affiliators
    mapping (address => bytes4) public affiliator2Code;
    // affiliate codes mapped to nft id
    mapping (bytes4 => uint256) public code2TokenId;

    event Lock();
    event NonFungibleTokenRecovery(address indexed token, uint256 tokenId);
    event TokenRecovery(address indexed token, uint256 amount);
    event CodeFailed(uint256 tokenId);
    event CodeSuccess(bytes4 code, uint256 tokenId);

    constructor(
    ) ERC721("Wildlands Member Cards", "WMC") {

        setBaseURI("https://nft.wildlands.me/wmc/meta/");
        // set minter role
        // minter role is assigned to membership contract to allow users buy a card
        _setupRole(MINTER_ROLE,  _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE,  _msgSender());
        // set initial values
        bitId._value = 1; // 1 - 100
        goldId._value = 101; // 101 - 400
        blackId._value = 401;  // 401 - 1000
        standardId._value = 1001; // 1001 - x
    }

    /**
     * @notice Allows the owner to lock the contract
     * @dev Callable by owner
     */
    function lock() external onlyOwner {
        require(!isLocked, "Operations: Contract is locked");
        isLocked = true;
        emit Lock();
    }    

    function isCardAvailable(uint256 cardId) public view returns (bool) {
        if (cardId == 0)  
            return true; // 1001 - x
        else if (cardId == 1)
            return blackId.current() <= 1000; // 401 - 1000
        else if (cardId == 2)
            return goldId.current() <= 400; // 101 - 400
        else if (cardId == 3)
            return bitId.current() <= 100; // 1 - 100
        return false;
    }

    function cardIndex(uint256 cardId) external view returns (uint256) {
        if (cardId == 0)  
            return standardId.current(); 
        else if (cardId == 1)
            return blackId.current(); 
        else if (cardId == 2)
            return goldId.current(); 
        else if (cardId == 3)
            return bitId.current(); 
        return 0;
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        // does token id exist?
        return _exists(_tokenId);
    }

    function existsCode(bytes4 _code) external view returns (bool) {
        // does code exist for any wildland card? -> valid code
        return code2TokenId[_code] != 0;
    }

    function getTokenIdByCode(bytes4 _code) external view returns (uint256) {
        // obtain token id for a given code to process affiliates
        return code2TokenId[_code];
    }

    function getCodeByAddress(address _address) external view returns (bytes4) {
        // obtain code for given address
        return affiliator2Code[_address];
    }

    /**
     * @notice Allows the owner to mint a token to a specific address
     * @param _to: address to receive the token
     * @param _cardId: card id
     * @dev Callable by owner
     */
    function mint(address _to, uint256 _cardId) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "Minter role required to mint new member NFTs");
        require(isCardAvailable(_cardId), "Wildland cards: requested vip card is sold out");
        if (_cardId == 0) {
            // mint Wild Land Member Card
            _mint(_to, standardId.current());
		    _generateCode(_to, standardId.current());
			standardId.increment();
		}
        else if (_cardId == 1){
            // mint Wild Land Black Card
            _mint(_to, blackId.current());
		    _generateCode(_to, blackId.current());
            blackId.increment();
        }
        else if (_cardId == 2){
            // mint Wild Land Gold Card
            _mint(_to, goldId.current());
		    _generateCode(_to, goldId.current());
            goldId.increment();
        }
        else if (_cardId == 3){  
            // mint Wild Land Bit Card
            _mint(_to, bitId.current());
		    _generateCode(_to, bitId.current());     
            bitId.increment();      
        }
    }

    // code generator function for affiliate link
    // affiliators need to activate thir affiliation code
    function generateCode(uint256 _tokenId) external {
        require (_exists(_tokenId), "generateCode: Invalid token id for code generation");
        require (ownerOf(_tokenId) == msg.sender, "generateCode: Only owner of card can generate code");
        _generateCode(msg.sender, _tokenId);
    }

    function _generateCode(address _for, uint256 _tokenId) internal {
        bytes4 code = bytes4(keccak256(abi.encodePacked(block.timestamp, _tokenId)));
        if (code2TokenId[code] != 0 || code == 0x0) {
            // security checK. do not overwrite existing codes if it happens... 
            // default value 0x0 cannot be a valid code
            emit CodeFailed(_tokenId);
            return;
        }
        // link code to token id. Affiliators can have multiple codes linked to a specific token id, but only last one is stored.
        // Selling the member cards also sells all affiliates as affilatees are linked to code only. 
        // Buyers can reuse old code or generate an own one. 
        affiliator2Code[_for] = code;
        code2TokenId[code] = _tokenId;
        emit CodeSuccess(code, _tokenId);
    }

    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);

        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20(_token).safeTransfer(address(msg.sender), balance);

        emit TokenRecovery(_token, balance);
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) public onlyOwner {
        require(!isLocked, "Operations: Contract is locked");
        baseURI = _uri;
    }

    /**
     * @notice Returns a list of token IDs owned by `user` given a `cursor` and `size` of its token list
     * @param user: address
     * @param cursor: cursor
     * @param size: size
     */
    function tokensOfOwnerBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > balanceOf(user) - cursor) {
            length = balanceOf(user) - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = tokenOfOwnerByIndex(user, cursor + i);
        }

        return (values, cursor + length);
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for a token ID
     * @param tokenId: token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // 24 different doors -> every 24th tokenId maps on the same nft file
        uint256 tokenType = 0;
        if (tokenId <= 100) {
            // BIT CARD MEMBER
            tokenType = 3; 
        }
        else if (tokenId <= 400) {
            // GOLD CARD MEMBER
            tokenType = 2;
        }
        else if (tokenId <= 1000) {
            // BLACK CARD MEMBER
            tokenType = 1;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenType.toString(), ".json")) : "";
    } 
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}