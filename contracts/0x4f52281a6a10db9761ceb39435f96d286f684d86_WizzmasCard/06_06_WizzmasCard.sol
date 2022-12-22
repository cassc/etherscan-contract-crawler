//
//                 __                                                        
//      _    _     LJ    _____     _____     _ _____       ___ _      ____   
//     FJ .. L]         [__   F   [__   F   J '_  _ `,    F __` L    F ___J  
//    | |/  \| |   FJ   `-.'.'/   `-.'.'/   | |_||_| |   | |--| |   | '----_ 
//    F   /\   J  J  L  .' (_(_   .' (_(_   F L LJ J J   F L__J J   )-____  L
//   J\__//\\__/L J__L J_______L J_______L J__L LJ J__L J\____,__L J\______/F
//    \__/  \__/  |__| |_______| |_______| |__L LJ J__|  J____,__F  J______F 
//
//                                                                                                                                       
// Wizzmas Holiday Cards Collection
// https://wizz.wtf
pragma solidity ^0.8.9;

import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC1155.sol";
import {LibString} from "solmate/utils/LibString.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "solmate/auth/Owned.sol";

contract WizzmasCard is ERC721, Owned, ReentrancyGuard {
    using LibString for uint256;

    struct Card {
        uint24 card; // 16m cards allowed, 3 bytes slot1
        address tokenContract; // 20 bytes, slot1
        uint16 token; // 2 bytes, slot 1
        uint8 artwork; // 1 bytes, slot 1 
        uint8 template; // 1 bytes, slot 1
        string message; // 64 bytes, 2 slots, slot 2 & 3
        address sender; // 20 bytes, slot 4
        address recipient; // 20 bytes, slot 5
    }
    
    uint8 public numTemplates;
    uint24 private nextTokenId;
    address public artworkAddress;
    string public baseURI;
    bool public mintEnabled;

    mapping(uint24 => Card) cards;
    mapping(address => bool) public supportedTokenContracts;
    mapping(address => uint24[]) public senderCards; 
    mapping(address => uint24[]) public recipientCards;

    error MintClosed();
    error InvalidTemplate();
    error InvalidToken();
    error InvalidMessageLength();
    error NotOwnerOfToken();
    error NoCover();
    error CardNotMinted();

    event WizzmasCardMinted(Card data);

    constructor(
        address _artworkAddress,
        address[] memory _tokenContracts,
        uint8 _numTemplates,
        string memory _initialBaseURI,
        address _owner
    ) ERC721("Wizzmas Cards", "WIZZMAS") Owned(_owner) {
        artworkAddress = _artworkAddress;
        for(uint8 i = 0; i < _tokenContracts.length; i++) {
            supportedTokenContracts[_tokenContracts[i]] = true;
        }
        numTemplates = _numTemplates;
        mintEnabled = false;
        setBaseURI(_initialBaseURI);
    }

    function mint(
        address _tokenContract,
        uint16 _tokenId,
        uint8 _artworkId,
        uint8 _templateId,
        string memory _message,
        address _recipient
    ) public nonReentrant {
        if (!mintEnabled) revert MintClosed();
        if (_templateId >= numTemplates) revert InvalidTemplate();
        if (supportedTokenContracts[_tokenContract] != true) revert InvalidToken();
        if(bytes(_message).length >= 64 || bytes(_message).length < 1) revert InvalidMessageLength();
        if(ERC721(_tokenContract).ownerOf(_tokenId) != msg.sender) revert NotOwnerOfToken();
        if(ERC1155(artworkAddress).balanceOf(msg.sender, _artworkId) < 1) revert NoCover();

        uint24 newId = nextTokenId;
        _safeMint(_recipient, newId);
        ++nextTokenId;

        cards[newId] = Card(
            newId,
            _tokenContract,
            _tokenId,
            _artworkId,
            _templateId,
            _message,
            msg.sender,
            _recipient
        );

        senderCards[msg.sender].push(newId);
        recipientCards[_recipient].push(newId);
        emit WizzmasCardMinted(cards[newId]);
    }

    function getCard(uint24 cardId) public view returns (Card memory) {
        if (nextTokenId > cardId) {
            return cards[cardId];
        }
        revert CardNotMinted();
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string.concat(baseURI, id.toString());
    }

    function getRecipientCardIds(address recipient) public view returns (uint24[] memory){
        return recipientCards[recipient];
    }

    function getSenderCardIds(address sender) public view returns (uint24[] memory) {
        return senderCards[sender];
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint24) {
        return nextTokenId;
    }

    // Only contract owner shall pass
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setNumTemplates(uint8 _numTemplates) public onlyOwner {
        numTemplates = _numTemplates;
    }

    function strikeMessage(uint24 cardId, string memory _message) public onlyOwner {
        if(cardId >= nextTokenId) revert CardNotMinted();
        if(bytes(_message).length >= 64 || bytes(_message).length < 1) revert InvalidMessageLength();
        cards[cardId].message = _message;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintEnabled(bool _newMintEnabled) public onlyOwner {
        mintEnabled = _newMintEnabled;
    }

    function setArtworkAddress(address _address) public onlyOwner {
        artworkAddress = _address;
    }

    function setSupportedTokenContract(address _address, bool supported) public onlyOwner {
        supportedTokenContracts[_address] = supported;
    }
}