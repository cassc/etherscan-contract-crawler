//SPDX-License-Identifier: MIT

// shoutoutskwidkkxkkOxc,...;c::;;;,,,''',,;cdkkkkxxxxxdddddddd
// xxxxxxxxxxxxxkkxxol;.  ...........'........:xkkkxxxxxxxxxxxx
// kkkkxxxxxxxdoc;,'.......''..........'...''..;dkkxxdddooooood
// kkkkkkkkxl;'....''...'''...',,,;;:ccc;...'...,:;,,'''......;
// OOOkkkkl,...''.''....''''..;oc:::;'.........  ..........,:ld
// OOOOOkl'.''''''''...'''''.............. ............';cloxOO
// kkOOOk:..''''''''...''''''.........  .......';:cc::ccc;':dOO
// kkkkOk:..''''''''....''''....     ...',;:c::clodkkl;clloxkkk
// kkkkkkc..'''''''''........ ...',;:lodxxkkkkkxol:,::,;dkOkkkk
// xkkkkko'.'''.'...........;cooddddddooodxkkkkkkkxc;lddxkkkkkk
// xxkkkkx;...',,;;'':lc::;'cxkdooooododoodkkkkkkkkx::xOOkkkkkx
// xkkkkkd:;ldxkkOd:lkkkkxdodxkxolldxkkkxolccodxxxxxd:ckOkkkkxx
// kkkkdccokOOOOOOc:dxkkkkkkxo:',cokkkkkkko.  ....'cdl;oOkkkkkx
// kdlccokOOOOOOOk::olddooc,..   .;xkkkkkkxoc,.    ,xx:ckOkkkkk
// c,,:llccxOOOO0d:cocloddl:.     .okkkkkkkdc'.    ,odl;dOOOkkk
// xdoooc,:kOxllxo;ldloxxdl,.     .lkkxdood:.  ,:::llod:lOOOOOk
// OOOkl''cc;,;;:;:xxollol'.,'....,okkkkxlod:.'lddddooxc:kOOOOO
// kkdc:coodoloo;,okxoloddooddlcloloxxoooldkxddxkkkxdoxl:dOOOOO
// kd:cxdoooodkxddkkkddxkkkkkkkxo:cldxdodxkkkkkkkkkkkkkl;okkkkk
// xl;okxxkxllxkkkkkkkkkkkkkkkkkdoollc:::ldkkkkkkkkkkkkl;okkkkk
// xo;cxxdooloxdxkkkkkkkkkkkkkkkxxl,.     .:xkkkkkkkkkkc;okxxxx
// xxo::clccll:ldkkkkkkkkkkkkkkx:'.         ;dkkkkkkkkd::xxxxxx
// xxxxocclc;,cxkkkkkkkkkkkkkkx:.           .:kkkkkkkxc;oxxxxxx
// xxxxkkxdxkl:lxkkkkkkkkkkkkko.  ..,,'.';;,.:xkkkkxo::dkkxxxxd
// xxxkkkkkOOkdc:lxkkkkkkkkkkko,';:cccccccccclxkxdlc:oxkkkxxxxd
// xkkkkkOOOOOOkdc:cldxkkkkkkkxo:::cloooooolccccccldkOOkkkkkxxx
// kkkkkOOOOkkkkkkxoccccclllloolc::ccllcccccccloxkkOOOOkkkkkkxx
// kkkkkOOOkkkkkkxxxxxdolc::;;;;::;::cllodxxkkkkkkkkOOOOOkkkkkx

// Ownership of this NFT grants full ownership and commercial usage rights of this NFT to the owner
// All rights relinquished upon transfer. GG

pragma solidity ^0.8.0;

import "ERC721.sol";

import "Ownable.sol";

import "SafeMath.sol";

import "Counters.sol";

contract FuddersNFT is ERC721("Fudders", "NGMI"), Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    modifier isTeam {
        require(isTeamMember[msg.sender]);
        _;
    }

    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_SUPPLY = 6464; // NGMI
    uint256 public price = 32320000000000000; // 6464/2 fer da memes
    uint256 public REMAINING_RESERVED = 130; // 2% team allocation

    mapping(address => bool) public isTeamMember;

    bool public saleIsActive;
    string public baseTokenURI;

    address
        public constant addrOne = 0xF7aDD17E99F097f9D0A6150D093EC049B2698c60;
    address
        public constant addrTwo = 0x0B32b6a775cCF57ff75078a702249A65c8A581Fe;
    address
        public constant addrThree = 0x94e5149AC7B8B1249069f6D9DFCBb2590d641dDC;
    address
        public constant addrFour = 0x8958eBEB998DB0C051b4857aB8c1d758B12e423f;
    address
        public constant addrFive = 0x965891B44F8571545C9DeeB687970Bd53011C8d0;

    constructor() public {
        saleIsActive = false;
        setBaseURI("http://api.fudderverse.com/");
        isTeamMember[addrOne] = true;
        isTeamMember[addrTwo] = true;
        isTeamMember[addrThree] = true;
        isTeamMember[addrFour] = true;
        isTeamMember[addrFive] = true;
    }

    //General mint function using counter instead of ERC721Enumerable's totalSupply() to reduce gas cost
    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(
            numberOfTokens <= MAX_PER_TX,
            "Fudders: Max of 10 tokens per transaction"
        );
        require(
            _tokenSupply.current().add(numberOfTokens) <= MAX_SUPPLY,
            "Fudders: Purchase would exceed max supply"
        );
        require(
            price.mul(numberOfTokens) <= msg.value,
            "Fudders: Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenSupply.increment();
            uint256 newTokenId = _tokenSupply.current();
            _safeMint(msg.sender, newTokenId);
        }
    }

    //function for team token mint in batches of 10, team tokens are capped at 130 (2%)
    function teamMint() public isTeam {
        require(
            REMAINING_RESERVED >= 10,
            "Fudders: Insufficient reserves remaining"
        );
        require(saleIsActive, "Fudders: Sale must be active to mint");

        require(
            _tokenSupply.current().add(10) <= MAX_SUPPLY,
            "Fudders: Purchase would exceed max supply"
        );

        REMAINING_RESERVED -= 10;

        for (uint256 i = 0; i < 10; i++) {
            _tokenSupply.increment();
            uint256 newTokenId = _tokenSupply.current();
            _safeMint(msg.sender, newTokenId);
        }
    }

    function _baseURI() internal virtual override view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawSplit() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance = 0");
        _widthdraw(addrOne, balance.mul(10).div(100));
        _widthdraw(addrTwo, balance.mul(25).div(100));
        _widthdraw(addrThree, balance.mul(30).div(100));
        _widthdraw(addrFour, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function changePrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function getPrice(uint256 _count) public view returns (uint256) {
        return price.mul(_count);
    }

    //If you are reading this,
    //message @DontCryWolf and let him know you love apples,
    //message @Velcrafting and let him know that it rains a lot in England,
    // and message @Metaverse_Yin "Hi from the future".
    //Sincerely, @0xFloop :)

    function totalSupply() external view returns (uint256) {
        return _tokenSupply.current();
    }
}