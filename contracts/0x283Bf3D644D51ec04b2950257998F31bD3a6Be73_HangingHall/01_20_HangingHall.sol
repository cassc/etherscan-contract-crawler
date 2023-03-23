//                                     @@@@,                                      
//                                    *@@@@@*                                     
//                                    (@@@@@@                                     
//                                    /@@@@@@                                     
//                                    @@@@@@@                                     
//                                     @@@@@@                                     
//                                 @@@@@@@@@@@@@@                                 
//                                @@@@@@@@@@@@@@@                                 
//                                 @@@@@@@@@@@@@.                                 
//                                @@@@@@@@@@@@@@                                  
//                               &@@@@@@@@@@@@@@                                  
//                               [email protected]@@@@@@@@@@@@@                                  
//                                  @@@@@@@@@@.                                   
//                                 @@@@@@,@@@@@@                                  
//                                @@@@@@   @@@@@@@                                
//                              @@@@@@@     [email protected]@@@@@@.                             
//                            @@@@@@@          @@@@@@@@                           
//                          @@@@@@@              [email protected]@@@@@@(                        
//                       ,@@@@@@@                   @@@@@@@@                      
//                     [email protected]@@@@@@                       [email protected]@@@@@@                    
//                    @@@@@@@                            @@@@@@@                  
//                  @@@@@@@                                @@@@@@(                
//                 @@@@@@                                   [email protected]@@@@@               
//               %@@@@@@  [email protected]@(        @@@    @@@@       @@@,  @@@@@@              
//              @@@@@@*  &@@@@@      @@@@@   @@@@@     @@@@@.  %@@@@@             
//             %@@@@@.   @@@@@@     @@@@@@   @@@@@     @@@@@.   (@@@@@            
//             @@@@@#    @@@@@@     @@@@@@  [email protected]@@@@     @@@@@     @@@@@@           
//            @@@@@@     @@@@@@     @@@@@@  *@@@@@    (@@@@@      @@@@@           
//            @@@@@*     @@@@@@     @@@@@@  &@@@@@    @@@@@@      @@@@@@          
//            @@@@@      @@@@@@@@@/ @@@@@@  @@@@@@@@@@@@@@@@      @@@@@@          
//            @@@@@      @@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@      @@@@@@          
//            @@@@@%     @@@@@@  &@@@@@@@(  @@@@@@    @@@@@@      @@@@@#          
//            @@@@@@     @@@@@@     @@@@@,  @@@@@@    @@@@@@      @@@@@           
//             @@@@@@    @@@@@@     @@@@@   @@@@@&    @@@@@@     @@@@@@           
//              @@@@@@   @@@@@@    ,@@@@@   @@@@@&    @@@@@@    @@@@@@            
//               @@@@@@    (,      [email protected]@@@@   @@@@@(    @@@@@    @@@@@@             
//                %@@@@@@                                    @@@@@@%              
//                  @@@@@@@.                              [email protected]@@@@@@                
//                    &@@@@@@@@                        @@@@@@@@@                  
//                       @@@@@@@@@@@&            %@@@@@@@@@@@                     
//                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@                         
//                                 @@@@@@@@@@@@@@@@                                                                                                             

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";

contract HangingHall is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    ERC2981,
    DefaultOperatorFilterer
{
    constructor() ERC721("Hanging Hall", "HH") {}

    using Strings for uint256;

    mapping(uint256 => string) public BASE_URIS;
    mapping(address => bool) auth;

    function collectFromGateway(uint256 _id, address _owner) external {
        require(auth[msg.sender], "Not authorized");
        _safeMint(_owner, _id);
    }

    function collectManual(
        uint256[] memory _id,
        address[] memory _owner
    ) external onlyOwner {
        require(_id.length == _owner.length, "Length");
        for (uint i = 0; i < _id.length; i++) {
            _safeMint(_owner[i], _id[i]);
        }
    }

    function tokenURI(
        uint256 _galleryId
    ) public view virtual override returns (string memory) {
        require(_exists(_galleryId));
        uint256 collectionId = _galleryId / 5000;
        return
            string(
                abi.encodePacked(BASE_URIS[collectionId], _galleryId.toString())
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setAuthorised(address _address, bool _auth) external onlyOwner {
        auth[_address] = _auth;
    }

    function setBaseURI(
        string memory _newBaseURI,
        uint256 _index
    ) public onlyOwner {
        BASE_URIS[_index] = _newBaseURI;
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}