// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                         :-===-:                                          //
//                                     :++=:.   .:=++:                                      //
//                                   -*-             =*.                                    //
//                                  *=                .#-                                   //
//                                 #:                   #:                                  //
//                                ++                     %.                                 //
//                                %.                   =:-#                                 //
//                                -            .:      @@.#:                                //
//                                =:           *@=     .- -#                                //
//                               .+%==-         +:  -++:   @.                               //
//                             :*=. ..                :#   *-                               //
//                            :# .*+-.               -+.   =+                               //
//                            %. %.                 -=+*.  -#                               //
//                            %:                  =*: :#:  :#                               //
//                            :#.     .*:         :*+=++.  .%                               //
//                              =+++**=                    .*                               //
//                                  %.                      .                               //
//                                 :#                       .                               //
//                                 #-                      ==                               //
//                                .%                       *-                               //
//                                *=                       %:                               //
//                               .%                        @                                //
//                               +=                        @                                //
//                                                         @                                //
//                              #:                         @                                //
//                            .+%=-                        @                                //
//                          +*-.  :+=                      %+++=.                           //
//                        -#.                              *=  .*=                          //
//                       -#                                      *=                         //
//                      .%                                  %     %.                        //
//                      ::                                  #-    -*                        //
//                      =           -+                      :#     %:                       //
//                      .           ::                       *:    .%                       //
//                     ==           :-                        ..    ++                      //
//                     *=           :*                        :%     #-                     //
//                     *-            %                         -#     %:                    //
//                     *-            *-                         :#.    #-                   //
//////////////////////////////////////////////////////////////////////////////////////////////

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./WithdrawFairly.sol";

contract NeckVille is ERC721, Ownable, WithdrawFairly {

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant RESERVE_NFT = 150;
    uint256 public constant START_AT = 1;
    uint16 private constant HASH_SIGN = 33541;

    struct Sale {
        uint64 start;
        uint64 end;
        uint16 maxPerWallet;
        uint8 maxPerTx;
        uint256 price;
        bool paused;
    }

    mapping(string => Sale) public sales;
    mapping(string => mapping(address => uint16)) balanceSale;
    mapping(uint256 => bool) private signatureIds;

    address public signAddress;
    string public baseTokenURI;

    uint16 public mintTracked;
    uint16 public burnedTracker;

    event EventSaleChange(string _name, Sale sale);
    event EventMint(address _to, uint256 _tokens);

    constructor(string memory baseURI, address _signAddress) ERC721("NeckVille", "NV") WithdrawFairly() {
        setBaseURI(baseURI);
        setSignAddress(_signAddress);

        setSale("PRESALES_1", Sale(1641668400, 1641711599, 3, 3, 0.05 ether, false));
        setSale("PRESALES_2", Sale(1641711600, 1641754799, 2, 2, 0.05 ether, false));
        setSale("PUBLIC", Sale(1641754800, 1991332800, 0, 2, 0.05 ether, false));
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier isOpen(string memory _name, uint16 _count){

        require(saleIsOpen(_name), "Sale not open");
        require(_count <= sales[_name].maxPerTx, "Max per tx limit");
        require(mintTracked + _count <= MAX_SUPPLY, "Sold out!");
        require(msg.value >= price(_name, _count), "Value limit");

        if (sales[_name].maxPerWallet > 0) {
            require(balanceSale[_name][_msgSender()] + _count <= sales[_name].maxPerWallet, "Max per wallet limit");
            balanceSale[_name][_msgSender()] += _count;
        }
        _;
    }

    //******************************************************//
    //                     Sales logic                      //
    //******************************************************//
    function setSale(string memory _name, Sale memory _sale) public onlyOwner {
        sales[_name] = _sale;
        emit EventSaleChange(_name, _sale);
    }

    function pauseSale(string memory _name, bool _pause) public onlyOwner {
        sales[_name].paused = _pause;
    }

    function saleIsOpen(string memory _name) public view returns (bool){
        return sales[_name].start > 0 && block.timestamp >= sales[_name].start && block.timestamp <= sales[_name].end && !sales[_name].paused;
    }

    function saleCurrent() public view returns (string memory){
        if (saleIsOpen("PRESALES_1")) return "PRESALES_1";
        if (saleIsOpen("PRESALES_2")) return "PRESALES_2";
        if (saleIsOpen("PUBLIC")) return "PUBLIC";
        return "NONE";
    }


    //******************************************************//
    //                      Mint                            //
    //******************************************************//
    function preSalesMint(string memory _name, uint16 _count, uint256 _signatureId, bytes memory _signature) public payable isOpen(_name, _count) {

        require(signatureIds[_signatureId] == false, "Signature already used");
        signatureIds[_signatureId] = true;
        require(checkSignature(_msgSender(), _name, _count, _signatureId, _signature) == signAddress, "Signature error : bad owner");

        _mintTokens(_count);

    }

    function publicSalesMint(uint16 _count) public payable isOpen("PUBLIC", _count) {
        _mintTokens(_count);
    }

    function checkSignature(address _wallet, string memory _name, uint256 _count, uint256 _signatureId, bytes memory _signature) public pure returns (address){
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(_wallet, _name, _count, _signatureId, HASH_SIGN)))), _signature);
    }

    function _mintTokens(uint16 _count) private {
        for (uint16 i = 0; i < _count; i++) {
            uint256 _tokenId = mintTracked + START_AT;
            _safeMint(_msgSender(), _tokenId);
            mintTracked += 1;
            emit EventMint(_msgSender(), _tokenId);
        }
    }

    function reserve(uint16 _count) public onlyOwner {
        require(mintTracked + _count <= RESERVE_NFT, "Exceeded RESERVE_NFT");
        _mintTokens(_count);
    }

    //******************************************************//
    //                      Base                            //
    //******************************************************//
    function totalSupply() public view returns (uint256) {
        return mintTracked - burnedTracker;
    }

    function price(string memory _name, uint256 _count) public view returns (uint256){
        return sales[_name].price * _count;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function minted(string memory _name, address _wallet) public view returns (uint16){
        return balanceSale[_name][_wallet];
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256 key = 0;
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = START_AT; i <= mintTracked; i++) {
            if (rawOwnerOf(i) == _owner) {
                tokensId[key] = i;
                key++;

                if (key == tokenCount) {
                    break;
                }
            }
        }
        return tokensId;
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setSignAddress(address _signAddress) public onlyOwner {
        signAddress = _signAddress;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
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