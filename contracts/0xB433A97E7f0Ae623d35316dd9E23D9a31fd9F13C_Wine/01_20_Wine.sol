//                               .''..    
//                              ,ONWNKkd, 
//                             '0MMMMMMMN:
//                             cWMMMMMMMX;
//                            .kMMMMMMMWd.
//                           .xWMMMMMMWd. 
//                          .xWMMMMMMMO.  
//                         .kWMMMMMMMN:   
//                        ;0MMMMMMMMMk.   
//                      .dXMMMMMMMMMWl    
//                   ,cdKMMMMMMMMMMMN:    
//                .ckNMMMMMMMMMMMMMMX:    
//              ,xXWMMMMMMMMMMMMMMMMWl    
//            .dNMMMMMMMMMMMMMMMMMMMMO.   
//           'OMMMMMMMMMMMMMMMMMMMMMMNc   
//          '0MMMMMMMMMMMMMMMMMMMMMMMMk.  
//         ,0MMMMMMMMMMMMMMMMMMMMMMMMMX;  
//        'OMMMMMMMMMMMMMMMMMMMMMMMMMMN:  
//       .kWMMMMMMMMMMMMMMMMMMMMMMMMMMX;  
//      .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMk.  
//      lNMMMMMMMMMMMMMMMMMMMMMMMMMMMN:   
//     ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.   
//    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,    
//   .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMWl     
//   cNMM CEL MATES TOILET WINE MMMO.     
//  '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMX:      
// .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMWd       
// cNMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'       
//.OMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc        
//;XMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.        
//'OMMMMMMMMMMMMMMMMMMMMMMMMMMMK,         
// 'xNMMMMMMMMMMMMMMMMMMMMMMMMMd.         
//   'ckXWMMMMMMMMMMMMMMMMMMMMK,          
//      .:xKWMMMMMMMMMMMMMMMW0;           
//         .,:ldxkOOOOOOkxdl;.            
//                 ..          
//            
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";

contract Wine is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    ERC2981,
    DefaultOperatorFilterer
{
    constructor() ERC721("ToiletWine", "WINE") {}

    modifier isAuth() {
        require(authorised[msg.sender], "Not authorised");
        _;
    }

    using Strings for uint256;

    mapping(address => bool) authorised;
    mapping(uint256 => string) baseURIs;
    string public baseURI;
    bool public singleURI;
    uint256 public header;
    uint256 public counter;
    mapping(uint256 => uint256) headerToCutoff;

    // ------------------ External ------------------ //

    function minter(address _to) external isAuth {
        _safeMint(_to, counter);
        counter++;
    }

    // ------------------ Public ------------------ //

    function tokenURI(uint256 _wineId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_wineId));
        return
            singleURI ? string(
                abi.encodePacked(
                    baseURI,_wineId.toString()
                )
            ) : string(
                abi.encodePacked(
                    _getURI(_wineId)
                )
            );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ------------------ Internal ------------------ //

    function _getURI(uint256 _wineId)
        internal
        view
        returns (string memory _uri)
    {
        for (uint256 i = 0; i <= header; i++) {
            if (_wineId < headerToCutoff[i]) {
                return baseURIs[i];
            }
        }
    }

    // ------------------ Owner ------------------ //

    function safeMint(address[] memory _to) public onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], counter);
            counter++;
        }
    }

    function setHeader(uint256 _collection, uint256 _cutoff, uint256 _header) public onlyOwner {
        headerToCutoff[_collection] = _cutoff;
        header=_header;
    }


    function setBaseURIs(uint256 _collection, string memory _baseUri)
        public
        onlyOwner
    {
        baseURIs[_collection] = _baseUri;
    }

    function setBaseURI(string memory _baseUri, bool _flag) public onlyOwner {
        baseURI = _baseUri;
        singleURI = _flag;
    }

    function setAuthorised(address _address, bool _auth) external onlyOwner {
        authorised[_address] = _auth;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}