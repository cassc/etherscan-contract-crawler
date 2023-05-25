// SPDX-License-Identifier: MIT

// @title: FLUFs
// @author: The FLUF Masters

//  ..............................................................................  \\
// ................................................................................ \\
// ................((.............................................................. \\
// .................(%/*........................................................... \\
// ..................&&#/**........................................................ \\
// [email protected]@&(/**,..................................................... \\
// [email protected]@&%(//**................................................... \\
// ....................*@@&%#(////................................................. \\
// [email protected]@@&%%#(////............................................... \\
// [email protected]@&%%%%#(///.............................................. \\
// [email protected]@&&%%%%##(///............................................ \\
// ......................#@@&%%%%%%#((((........................................... \\
// [email protected]@&%%%%%%%#((((.........*///////****,.................... \\
// [email protected]@@&%%%%%%%#((#.....&%%(((((((((((///*................... \\
// .......................,@@&&%%%%%%####/[email protected]&&%%%%%%%%%%%#((//.................. \\
// ........................%@@&&%%%%%%###/...*@&&%%%%&&&&&&&%#((//................. \\
// [email protected]@@&%%%%###%,...#@&&%%%&@@[email protected]@@@&%#(//................ \\
// ...........................&@@@&%%####[email protected]&&%%%&&[email protected]@@@&%#//*.............. \\
// [email protected]@@&%%#((....&&%%%%%[email protected]@@@&%(/*............ \\
// ...............................&&%%#(////(####(([email protected]@@@&#(.......... \\
// ............................&%%%%%%%%######%%#(///*............................. \\
// ...........................&&&%%%%%%%%%%%%%%%%%#(((*............................ \\
// [email protected]&&%%%%%%%%%%%%%%%%%%#(((............................ \\
// ..........................&&%%%%%%%%%%%%%%%%%%%%##(//........................... \\
// ........................&%%%%%%%%%%%%%%%%%%%%%%%%##(///......................... \\
// .......................&&&%%%%%%%%%%%%%%%%%%%%%%%%%##((#/....................... \\
// [email protected]@@@&&%%%%%%%%%%%%%%%%%%%%%%%&&&&........................ \\
// [email protected]@@@&%%%%%%%%%%%%%%%%%%&&&@........................... \\
// [email protected]@@@&&%%%%%%%%%%%&&@@@@............................. \\
// [email protected]@@@@&&%%%&&&@@@................................. \\
// ..................................#@@@@@@@@@.................................... \\
// ................................................................................ \\
// ........ 10101011 10111010 10110011 10110011 11011111 10101011 10110111 ........ \\
// ........ 10111010 11011111 10111001 10110011 10101010 10111001 11011111 ........ \\
// ........ 10110010 10111110 10101100 10101011 10111010 10101101 10101100 ........ \\
// ........ 11011111 10101100 10111100 10101101 10110000 10110000 10111000 ........ \\
// ........ 10111010 11011111 10110001 10111010 10111010 10111011 10101100 ........ \\
// ........ 11011111 10101011 10110000 11011111 10101100 10111010 10101011 ........ \\
// ........ 10101011 10110011 10111010 11011111 10110111 10110110 10101100 ........ \\
// ........ ........ 11011111 10111011 10111010 10111101 10101011 ........ ........ \\
// ........ ........ ........ ........ ........ ........ ........ ........ ........ \\
//  ....... ........ ........ ........ ........ ........ ........ ........ .......  \\

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract FLUF is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {

    using Address for address payable;
    using SafeMath for uint256;

    uint256 public constant MAX_FLUFS = 10000;
    uint256 public constant MAX_PURCHASE = 6;
    uint256 public constant AMOUNT_RESERVED = 120;
    uint256 public constant FLUF_PRICE = 9E16; // 0.09ETH
    uint256 public constant RENAME_PRICE = 9E15; // 0.009ETH


    enum State {
        Setup,
        PreParty,
        Party
    }

    mapping(address => uint256) private _authorised;

    mapping(uint256 => bool) private _nameChanged;


    State private _state;


    string private _immutableIPFSBucket;
    string private _mutableIPFSBucket;
    string private _tokenUriBase; 


    uint256 _nextTokenId;
    uint256 _startingIndex;


      //Credit to 0xc2c747e0f7004f9e8817db2ca4997657a7746928
    function setStartingIndexAndMintReserve(address reserveAddress) public {
        require(_startingIndex == 0, "Starting index is already set.");
        
        _startingIndex = uint256(blockhash(block.number - 1)) % MAX_FLUFS;
   
        // Prevent default sequence
        if (_startingIndex == 0) {
            _startingIndex = _startingIndex.add(1);
        }

        _nextTokenId = _startingIndex;


        for(uint256 i = 0; i < AMOUNT_RESERVED; i++) {
            _safeMint(reserveAddress, _nextTokenId); 
            _nextTokenId = _nextTokenId.add(1).mod(MAX_FLUFS); 
        }
    }

	event NameAndDescriptionChanged(uint256 indexed _tokenId, string _name, string _description);

  
    constructor() ERC721("FLUF","FLUF") {
        _state = State.Setup;
    }

    function setImmutableIPFSBucket(string memory immutableIPFSBucket_) public onlyOwner {
        require(bytes(_immutableIPFSBucket).length == 0, "This IPFS bucket is immuable and can only be set once.");
        _immutableIPFSBucket = immutableIPFSBucket_;
    }

    function setMutableIPFSBucket(string memory mutableIPFSBucket_) public onlyOwner {
        _mutableIPFSBucket = mutableIPFSBucket_;
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }


    function changeNameAndDescription(uint256 tokenId, string memory newName, string memory newDescription) public payable {
        address owner = ERC721.ownerOf(tokenId);

        require(
            _msgSender() == owner,
            "This isn't your FLUF."
        );

        uint256 amountPaid = msg.value;

        if(_nameChanged[tokenId]) {
            require(amountPaid == RENAME_PRICE, "It costs to create a new identity.");
        } else {
            require(amountPaid == 0, "First time's free my fluffy little friend.");
            _nameChanged[tokenId] = true;
        }

        emit NameAndDescriptionChanged(tokenId, newName, newDescription);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
 


    function baseTokenURI() virtual public view returns (string memory) {
        return _tokenUriBase;
    }

    function state() virtual public view returns (State) {
        return _state;
    }

    function immutableIPFSBucket() virtual public view returns (string memory) {
        return _immutableIPFSBucket;
    }

    function mutableIPFSBucket() virtual public view returns (string memory) {
        return _mutableIPFSBucket;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {

        return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
 
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function startPreParty() public onlyOwner {
        require(_state == State.Setup);
        _state = State.PreParty;
    }

    function setStateToParty() public onlyOwner {
        _state = State.Party;
    }


    function mintFluf(address human, uint256 amountOfFlufs) public nonReentrant payable virtual returns (uint256) {

        require(_state != State.Setup, "FLUFs aren't ready yet!");
        require(amountOfFlufs <= MAX_PURCHASE, "Hey, that's too many FLUFs. Save some for the rest of us!");

        require(totalSupply().add(amountOfFlufs) <= MAX_FLUFS, "Sorry, there's not that many FLUFs left.");
        require(FLUF_PRICE.mul(amountOfFlufs) <= msg.value, "Hey, that's not the right price.");


        if(_state == State.PreParty) {
            require(_authorised[human] >= amountOfFlufs, "Hey, you're not allowed to buy this many FLUFs during the pre-party.");
            _authorised[human] -= amountOfFlufs;
        }

        uint256 firstFlufRecieved = _nextTokenId;

        for(uint i = 0; i < amountOfFlufs; i++) {
            _safeMint(human, _nextTokenId); 
            _nextTokenId = _nextTokenId.add(1).mod(MAX_FLUFS); 
        }

        return firstFlufRecieved;

    }

     function withdrawAllEth(address payable payee) public virtual onlyOwner {
        payee.sendValue(address(this).balance);
    }


    function authoriseFluf(address human, uint256 amountOfFlufs)
        public
        onlyOwner
    {
      _authorised[human] += amountOfFlufs;
    }


    function authoriseFlufBatch(address[] memory humans, uint256 amountOfFlufs)
        public
        onlyOwner
    {
        for (uint8 i = 0; i < humans.length; i++) {
            authoriseFluf(humans[i], amountOfFlufs);
        }
    }

}