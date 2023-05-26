// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                     *@@@@@                                     //
//           #@@@#                   @@@@@@@@@@.                   @@@@,          //
//            ,@@@@@@               [email protected]@@@@@@@@@@               [email protected]@@@@@            //
//               &@@@@@@             #@@@@@@@@@             ,@@@@@@,              //
//                  @@@@@@@.            #@@@*            (@@@@@@&                 //
//                    (@@@@@@@*                       &@@@@@@@                    //
//                       @@@@@@@@(                 @@@@@@@@(                      //
//                         [email protected]@@@@@@@%           @@@@@@@@@                         //
//                            &@@@@@@@@&    ,@@@@@@@@@*                           //
//                               @@@@@@@@@@@@@@@@@@%                              //
//                                 /@@@@@@@@@@@@@.                                //
//                                    @@@@@@@@/                                   //
//                   [email protected]@@@@&            ,@@@            ,@@@@@@                   //
//                  @@@@@@@@@@                        ,@@@@@@@@@@                 //
//                 &@@@@@@@@@@,                       &@@@@@@@@@@                 //
//                  @@@@@@@@@(                         @@@@@@@@@(                 //
//                     #@@*                               #@@*                    //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721.sol";
import "./WithdrawFairly.sol";

contract MekaBot is ERC721, Ownable, ReentrancyGuard, WithdrawFairly  {

    using MerkleProof for bytes32[];
    bytes32 merkleRoot;

    uint16 public constant MAX_SUPPLY = 8888;
    uint16 public constant START_AT = 1;

    uint16 public mintTracked;
    uint16 public burnedTracker;

    struct Sale {
        uint64 start;
        uint64 end;
        uint16 maxPerWallet;
        uint8 maxPerTx;
        uint256 price;
        bool paused;
    }

    string public baseTokenURI;

    mapping(string => Sale) public sales;
    mapping(string => mapping(address => uint16)) balance;

    event EventMint(uint256 _tokenId);
    event EventSaleChange(string _name, Sale sale);

    constructor(string memory baseURI) ERC721("MekaBot", "MBOT") WithdrawFairly(){
        setBaseURI(baseURI);
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier canMint(string memory _name, uint16 _count){

        require(mintTracked + _count <= MAX_SUPPLY, "Sold out!");

        require(saleIsOpen(_name), "Sale not open");
        require(msg.value >= price(_name, _count), "Value limit");
        require(_count <= sales[_name].maxPerTx, "Max per tx limit");

        if(sales[_name].maxPerWallet > 0){
            require(balance[_name][_msgSender()] + _count <= sales[_name].maxPerWallet, "Max per wallet limit");
            balance[_name][_msgSender()] += _count;
        }
        _;
    }

    //******************************************************//
    //                     Sales logic                      //
    //******************************************************//
    function setSale(string memory _name, Sale memory _sale) public onlyOwner{
        sales[_name] = _sale;
        emit EventSaleChange(_name, _sale);
    }
    function pauseSale(string memory _name, bool _pause) public onlyOwner{
        sales[_name].paused = _pause;
    }
    function saleIsOpen(string memory _name) public view returns(bool){
        return sales[_name].start > 0 && block.timestamp >= sales[_name].start && block.timestamp <= sales[_name].end  && !sales[_name].paused;
    }
    function saleCurrent() public view returns (string memory){
        if (saleIsOpen("CLAIM")) return "CLAIM";
        if (saleIsOpen("PUBLIC")) return "PUBLIC";
        return "NONE";
    }

    //******************************************************//
    //                      Mint                            //
    //******************************************************//
    function claimBot(bytes32[] memory _proof, uint256 _countMax, uint16 _count) public payable canMint("CLAIM", _count) nonReentrant {

        require(canClaim(_proof, _msgSender(), _countMax), "Caller is not a claimer");
        require(balance["CLAIM"][_msgSender()] <= uint16(_countMax), "Max per wallet limit");

        _mintTokens(_count);
    }

    function canClaim(bytes32[] memory _proof, address _wallet, uint256 _countMax) public view returns(bool){
        return _proof.verify(merkleRoot, keccak256(abi.encodePacked(_wallet, _countMax)));
    }

    function buyBot(uint16 _count) public payable canMint("PUBLIC", _count) nonReentrant {
        _mintTokens(_count);
    }

    function _mintTokens(uint16 _count) private {
        for(uint16 i = 0; i < _count; i++){
            uint256 _tokenId = mintTracked + START_AT;
            _safeMint(_msgSender(), _tokenId);
            mintTracked += 1;
            emit EventMint(_tokenId);
        }
    }

    //******************************************************//
    //                      Base                            //
    //******************************************************//
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    //******************************************************//
    //                      Getters                         //
    //******************************************************//
    function totalSupply() public view returns (uint256) {
        return mintTracked - burnedTracker;
    }
    function price(string memory _name, uint256 _count) public view returns(uint256){
        return sales[_name].price * _count;
    }
    function minted(string memory _name, address _wallet) public view returns(uint16){
        return balance[_name][_wallet];
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 count = balanceOf(_owner);
        uint256 key = 0;
        uint256[] memory tokensIds = new uint256[](count);

        for (uint256 tokenId = START_AT; tokenId < mintTracked + START_AT; tokenId++) {
            if(rawOwnerOf(tokenId) != _owner) continue;
            if(key == count) break;

            tokensIds[key] = tokenId;
            key++;
        }
        return tokensIds;
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    //******************************************************//
    //                      Burn                            //
    //******************************************************//
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not owner nor approved");
        burnedTracker += 1;
        _burn(_tokenId);
    }
}