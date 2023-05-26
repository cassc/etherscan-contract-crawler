pragma solidity ^0.8.0;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

import "../interfaces/community_interface.sol";


import "../recovery/recovery.sol";
import "../interfaces/IRNG.sol";


import "../ec_configuration/ec_configuration.sol";

import "./ec_token_interface.sol";

import "hardhat/console.sol";




contract ec_token is ERC721Enumerable, ec_configuration , Ownable, recovery , ReentrancyGuard, ec_token_interface {
    using Strings  for uint256;

    IRNG                        immutable   public  _iRnd;
    mapping (address => bool)       public override permitted;

    bytes32                                         _reqID;
    bytes32                                         _secondReq;
    bool                                            _randomReceived;
    bool                                            _secondReceived;
    uint256                                         _randomCL;
    uint256                                         _randomCL2;
    string                                          _tokenRevealedBaseURI;  // base of URI points to a folder in EtherCards format (see readme)
    uint256                                         _ts1;                   // total supply when baseURI set
    uint256                                         _ts2;                   // total supply after second reveal (no more minting after this please)

    event Allowed(address,bool);
    event Locked(bool);
    event RandomProcessed(uint stage,uint256 randUsed_,uint256 _start,uint256 _stop,uint256 _supply);

    modifier onlyAllowed() {
        //console.log("only allowed",msg.sender);
        require(permitted[msg.sender] || (msg.sender == owner()),"Unauthorised");
        _;
    }

    modifier onlyAdmin() {
        //admin.permitted(msg.sender);
        _;
    }

    constructor( IRNG _rng ) ERC721(_name,_symbol) {
        _iRnd = _rng;
    }

    function setAllowed(address _addr, bool _state) external override onlyAllowed {
        permitted[_addr] = _state;
        emit Allowed(_addr,_state);
    }

    function mintCards(uint256 numberOfCards, address recipient) external override onlyAllowed {
        //console.log("mint cards");
        _mintCards(numberOfCards,recipient);
    }

    function _mintCards(uint256 numberOfCards, address recipient) internal {
        uint256 supply = totalSupply();
        require(supply+numberOfCards <= _maxSupply,"This would exceed the number of cards available");
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient,supply+j+1);
        }
    }

    // RANDOMISATION --cut-here-8x------------------------------

    function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
        if (!_randomReceived) _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    uint _start1;
    uint _stop1;
    uint _start2;

    function secondReveal() external onlyOwner {
        require(_randomReceived,"First Reveal not complete yet");
        if (!_secondReceived) _secondReq = _iRnd.requestRandomNumberWithCallback();
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd),"Unauthorised RNG");
        if (_reqID == reqID) {
            require(!(_randomReceived), "Random No. already received");
            _randomCL  = random / 2; // set msb to zero
            _start1 = _randomCL % (_maxSupply + 1);
            _randomReceived = true;
            _ts1 = totalSupply();
            _stop1 = uri(_ts1);
            emit RandomProcessed(1,_randomCL,_start1,_stop1,_ts1);
        } else if (_secondReq == reqID){
            _secondReceived = true;
            _ts2 = totalSupply();
            _randomCL2 = random / 2;
            _start2 = _randomCL2 % (_maxSupply - _ts1 + 1);
            emit RandomProcessed(2,_randomCL2,_start2,uri(_ts2),_ts2);
        }  else revert("Incorrect request ID sent");
    }

    function setPreRevealURI(string memory _pre) external onlyOwner {
        _tokenPreRevealURI = _pre;
    }
 
    function uri(uint n) public view returns (uint) {
        if (n <= _ts1) {
            if ((n + _start1) <= _maxSupply) {
                return n + _start1;
            } 
            return n + _start1 - _maxSupply;
        } else {
            uint range = _maxSupply - _ts1;
            uint pos_in_range = 1 + ((n - _ts1 + _randomCL2) % range);
            
            if ((_stop1+pos_in_range) <= _maxSupply) {
                //console.log("A");
                return _stop1+pos_in_range;
            }
            if ((_stop1+pos_in_range) - _maxSupply <= _start1) {
                //console.log("B");
                return (_stop1+pos_in_range) - _maxSupply;
            }
            //console.log("C");
            uint from_left =  (_stop1+pos_in_range) - _maxSupply + 1;
            return (from_left - _start1) + _stop1;
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        string memory revealedBaseURI = _tokenRevealedBaseURI;

        if (!_randomReceived) return _tokenPreRevealURI;
        
        if ((tokenId > _ts1) && !_secondReceived) return _tokenPreRevealURI;


        uint256 newTokenId = uri(tokenId);
        
        string memory folder = (newTokenId % 100).toString(); 
        string memory file = newTokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(revealedBaseURI,folder,slash,file)) ;
        //
    }

    function tellEverything() external view override returns (TKS memory) {
        return TKS(
            totalSupply(),
            _ts1,
            _ts2,
            _randomReceived,
            _secondReceived,
            _randomCL,
            _randomCL2,
            _lockTillSaleEnd
        );
    }

    function setTransferLock(bool locked) external onlyAdmin {
        _lockTillSaleEnd = locked;
        emit Locked(locked);
    }

    // Add lock until sellout or unlocked
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override {
        if (_lockTillSaleEnd)
            require( (block.timestamp > _saleEnd) || (from == address(0)),"Tokens cannot be moved until the end of the sale");
        super._beforeTokenTransfer(from,to,_tokenId);
    }


}