pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../recovery/recovery_split.sol";
import "../interfaces/IRNG.sol";

import "hardhat/console.sol";




contract as10k_token is ERC721, Ownable, recovery_split  {
    using Strings  for uint256;

    IRNG                        immutable   public  _iRnd;
    mapping (address => bool)               public  permitted;

    string                                          _tokenPreRevealURI;
    uint256                             constant    _maxSupply = 10395;
    uint256                                         _rand;

    bytes32                                         _reqID;
    bool                                            _randomReceived;
    uint256                                         _revealPointer;
    mapping(uint=>string)                           _tokenRevealedBaseURI;  
    uint                                            current;


    event Allowed(address,bool);
    event RandomProcessed(uint256 randomNumber);

    modifier onlyAllowed() {
        //console.log("only allowed",msg.sender);
        require(permitted[msg.sender] || (msg.sender == owner()),"Unauthorised");
        _;
    }


    constructor(
        IRNG _rng, 
        string memory _name, 
        string memory _symbol,
        string memory __tokenPreRevealURI,
        address[] memory _wallets, 
        uint256[] memory _shares 
    ) ERC721(_name,_symbol) recovery_split(_wallets,_shares){
        _tokenPreRevealURI = __tokenPreRevealURI;
        _iRnd = _rng;
    }

    function setAllowed(address _addr, bool _state) external  onlyAllowed {
        permitted[_addr] = _state;
        emit Allowed(_addr,_state);
    }

    receive() external payable {

    }

    function mintCards(uint256 numberOfCards, address recipient) external  onlyAllowed {
        //console.log("mint cards");
        _mintCards(numberOfCards,recipient);
    }

    function _mintCards(uint256 numberOfCards, address recipient) internal {
        require(!_randomReceived,"no minting after RNG invoked");
        uint256 supply = current;
        require(supply+numberOfCards <= _maxSupply,"This would exceed the number of cards available");
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient,supply+j+1);
        }
        current += numberOfCards;
    }

    // RANDOMISATION --cut-here-8x------------------------------

    function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
        _tokenRevealedBaseURI[_revealPointer += 1] = revealedBaseURI;
        if (!_randomReceived) _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd),"Unauthorised RNG");
        require (_reqID == reqID,"Incorrect request ID sent"); 
        require(!_randomReceived, "Random N already received");
        _rand = random / 2; // set msb to zero
        _randomReceived = true;
        emit RandomProcessed(_rand);       
    }

    function setPreRevealURI(string memory _pre) external onlyOwner {
        _tokenPreRevealURI = _pre;
    }
 
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        if (!_randomReceived) return _tokenPreRevealURI;
        
        string memory revealedBaseURI = _tokenRevealedBaseURI[_revealPointer];
        uint256 newTokenId = ((tokenId + _rand) % current) + 1;
                 
        string memory file = newTokenId.toString();
        return string(abi.encodePacked(revealedBaseURI,file)) ;
        //
    }

    function oldTokenURI(uint256 tokenId, uint256 version) public view returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        require(version > 0 ,"Versions start at 1");
        require(version <= _revealPointer,"Version does not exist");
        if (!_randomReceived) return _tokenPreRevealURI;
        
        string memory revealedBaseURI = _tokenRevealedBaseURI[version];
        uint256 newTokenId = ((tokenId + _rand) % current) + 1;
                 
        string memory file = newTokenId.toString();
        return string(abi.encodePacked(revealedBaseURI,file)) ;

    }


    // Add lock until sellout or unlocked
    function tokenPreRevealURI() external view  returns (string memory) {
        return _tokenPreRevealURI;
    }

    function totalSupply() external view returns (uint256) {
        return current;
    }


}