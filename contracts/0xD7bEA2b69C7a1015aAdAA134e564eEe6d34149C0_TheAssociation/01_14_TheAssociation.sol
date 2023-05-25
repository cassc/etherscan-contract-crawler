pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./recovery/recovery.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
import "./random/IRNG.sol";


contract TheAssociation is ERC721, Ownable, recovery {
        using Strings for uint256;


    uint256         START        = 18001;
    uint256         _next        = START;
    uint256         _more_next;
    string          _tokenRevealedBaseURI;
    string          _tokenPreRevealURI;
    bool            _randomReceived;
    uint256         _rand;
    bytes32         _reqID;

    IRNG                     public immutable   _iRnd;
    mapping(address => bool) public             _permitted;


    event Allowed(address, bool);
    event RandomProcessed(uint256 randomNumber);

    modifier onlyAllowed() {
        require(
            (msg.sender == owner()) || _permitted[msg.sender] ,
            "Unauthorised"
        );
        _;
    }


    constructor(string memory tempURI, IRNG rng) ERC721("The Association NFT","ASSOC") {
        _tokenPreRevealURI = tempURI;
        _iRnd = rng;
        _permitted[0xd25F03bdC4727B43bf09Ace9CF25C5DEA21D1532] = true;
    }

    function mintBatch(address[] calldata owners) external onlyAllowed {
        uint pos;
        if (!_randomReceived) {
            pos  = _next;
            for (uint j = 0; j < owners.length; j++) {
                _mint(owners[j],pos++);
            }
            _next = pos;
        } else {
            pos  = _more_next;
            for (uint j = 0; j < owners.length; j++) {
                _mint(owners[j],pos++);
            }
            _more_next = pos;
        }
    }

    function setRevealedBaseURI(string calldata revealedBaseURI)
        external
        onlyAllowed
    {
        _tokenRevealedBaseURI = revealedBaseURI;
        if (!_randomReceived) _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    function setPreRevealURI(string memory _pre) external onlyAllowed {
        _tokenPreRevealURI = _pre;
    }

    function setAllowed(address _addr, bool _state)
        external
        onlyAllowed
    {
        _permitted[_addr] = _state;
        emit Allowed(_addr, _state);
    }



    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd), "Unauthorised RNG");
        require (_reqID == reqID,"Incorrect request ID sent");
        require(!(_randomReceived), "Random No. already received");
        _rand = random / 2; // set msb to zero
        _randomReceived = true;
        _more_next = _next;
        emit RandomProcessed(_rand);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        string memory revealedBaseURI = _tokenRevealedBaseURI;

        if (!_randomReceived) return _tokenPreRevealURI;
        uint256 newTokenId = tokenId;
        if (tokenId < _next) {
            newTokenId = (((tokenId - START) + _rand) % (_next - START)) + START;
        }
        string memory folder = (newTokenId % 100).toString();
        string memory file = newTokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(revealedBaseURI, folder, slash, file));
    }
}