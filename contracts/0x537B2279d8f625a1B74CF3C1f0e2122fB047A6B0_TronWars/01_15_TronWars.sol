// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//             _____ _____ _____ _____ _ _ _ _____ _____ _____             //
//            |_   _| __  |     |   | | | | |  _  | __  |   __|            //
//              | | |    -|  |  | | | | | | |     |    -|__   |            //
//              |_| |__|__|_____|_|___|_____|__|__|__|__|_____|            //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./WithdrawFairly.sol";

contract TronWars is ERC721, Ownable, WithdrawFairly, ReentrancyGuard {

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant RESERVE_NFT = 88;
    uint256 public constant START_AT = 1;
    uint16 private constant HASH_SIGN = 55319;

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

    constructor(string memory baseURI, address _signAddress) ERC721("TronWars", "TRON") WithdrawFairly() {
        setBaseURI(baseURI);
        setSignAddress(_signAddress);

        setSale("PRESALES", Sale(1644004800, 1644091199, 2, 2, 0.15 ether, false));
        setSale("COMMUNITY",Sale(1644004800, 1644091199, 100, 100, 0.15 ether, false));
        setSale("PUBLIC",   Sale(1644091200, 1991332800, 3, 3, 0.15 ether, false));
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier canMint(string memory _name, uint16 _count){

        require(saleIsOpen(_name), "Sale not open");
        require(_count <= sales[_name].maxPerTx, "Max per tx limit");
        require(mintTracked + _count <= MAX_SUPPLY, "Sold out!");
        require(msg.value >= price(_name, _count), "Value limit");

        if(sales[_name].maxPerWallet > 0){
            require(balanceSale[_name][_msgSender()] + _count <= sales[_name].maxPerWallet, "Max per wallet limit");
            balanceSale[_name][_msgSender()] += _count;
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
        if (saleIsOpen("PRESALES")) return "PRESALES";
        if (saleIsOpen("PUBLIC")) return "PUBLIC";
        return "NONE";
    }


    //******************************************************//
    //                      Mint                            //
    //******************************************************//
    function preSalesMint(uint16 _count, bool _isOG, uint256 _signatureId, bytes memory _signature) public payable canMint("PRESALES", _count) nonReentrant {

        address wallet = _msgSender();

        if(!_isOG){
            require(balanceSale["PRESALES"][wallet] <= 1, "Max per wallet limit (PRESALES)");
        }

        require(signatureIds[_signatureId] == false, "Signature already used");
        require(checkSignature(wallet, _count, _isOG, _signatureId, _signature) == signAddress, "Signature error : bad owner");
        signatureIds[_signatureId] = true;

        _mintTokens(_count);

    }

    function communityMint(uint16 _count) public payable canMint("COMMUNITY", _count) nonReentrant {

        require(_msgSender() == address(0xDfd143aE8592e8E3C13aa3E401f72E1ca7deAED0), "Bad community wallet");

        _mintTokens(_count);
    }

    function publicSalesMint(uint16 _count) public payable canMint("PUBLIC", _count) nonReentrant {
        _mintTokens(_count);
    }

    function checkSignature(address _wallet, uint256 _count, bool _isOG, uint256 _signatureId, bytes memory _signature) public pure returns(address){
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(_wallet, _count, _isOG, _signatureId, HASH_SIGN)))), _signature);
    }

    function _mintTokens(uint16 _count) private {
        for(uint16 i = 0; i < _count; i++){
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
    function price(string memory _name, uint256 _count) public view returns(uint256){
        return sales[_name].price * _count;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function minted(string memory _name, address _wallet) public view returns(uint16){
        return balanceSale[_name][_wallet];
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256 key = 0;
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = START_AT; i <= mintTracked; i++) {
            if(rawOwnerOf(i) == _owner){
                tokensId[key] = i;
                key++;

                if(key == tokenCount){
                    break;
                }
            }
        }
        return tokensId;
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setSignAddress(address _signAddress) public onlyOwner{
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