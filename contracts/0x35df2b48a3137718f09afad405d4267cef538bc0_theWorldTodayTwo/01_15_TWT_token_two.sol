pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "../recovery/recovery.sol";


contract theWorldTodayTwo is 
    ERC721, 
    Ownable, 
    IERC2981,
    recovery
{
    using Strings  for uint256;

    mapping (address => bool)               public  admins;

    string                                          _thisURI = "https://arweave.net/Ll3Xs2ffaW3AnvtSd3LazQWQ-F38MnEzj5wQA3u0goY/";
    uint256                             constant    _maxSupply = 13800;
    uint256                             constant    _rand = 20600;

    bytes32                                         _reqID;
    bool                                            _randomReceived;
    uint256                                         _revealPointer;
    mapping(uint=>string)                           uris;  

    address                                         _twtAddress;
    uint256                                         _royalty = 10;
    mapping(uint256 => address)                     _per_token_royalty_destination; // use defaults if this is address(0)
    mapping(uint256 => uint256)                     _per_token_royalty_amount;

    mapping (uint256 => uint256)             public allTokens;
    uint256                                         count;
 

   


    event Allowed(address,bool);
    event BaseURIChanged(string _thisURI);
    event UpdatedURI(uint256 tokenId,string replacement);
    event SetDefaultRoyalties(address destination,uint256 amount);
    event SetPerTokenRoyalties(uint256 tokenId,address destination,uint256 amount);

    modifier onlyAdmin() {
        require(admins[msg.sender] || (msg.sender == owner()),"Unauthorised");
        _;
    }


    constructor(
        string memory _name, 
        string memory _symbol,
        address _wallet
    ) ERC721(_name,_symbol) recovery(_wallet) {
        _twtAddress = _wallet;
    }

    receive() external payable {

    }

    function yesterday(uint256 serial) public pure returns (uint256) {
        return ((serial + (serial%10)*100) % _maxSupply) + 1;
    }


    function setAdmin(address _addr, bool _state) external  onlyAdmin {
        admins[_addr] = _state;
        emit Allowed(_addr,_state);
    }


    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token does not exist");
        address dest = _per_token_royalty_destination[tokenId];
        if (dest == address(0)){
            uint256 _royaltyAmount = (salePrice * _royalty) / 100;
            return (_twtAddress, _royaltyAmount);
        }
        return (dest,salePrice * _per_token_royalty_amount[tokenId] / 100);
    }


    function mintBatchToOne(address recipient, uint256[] memory tokenIds) external  onlyAdmin {
        for (uint j = 0; j < tokenIds.length; j++) {
            require(!_exists(tokenIds[j]),"mintBatchToOne: One or more allocated tokens exists");
        }
        for (uint j = 0; j < tokenIds.length; j++) {
            _minty(recipient,tokenIds[j]);
        }
    }

    function mintBatchToOneR(address recipient, uint256[] memory tokenIds ) external  onlyAdmin {
        uint256 len = tokenIds.length;
        uint256[] memory newTids = new uint256[](len);
        for (uint j = 0; j < len; j++) {
            newTids[j] = yesterday(tokenIds[j]);
            require(!_exists(newTids[j]),"mintBatchToOne: One or more allocated tokens exists");
        }
        for (uint j = 0; j < len; j++) {
            _minty(
                recipient,
                newTids[j]
            );
        }
    }


    function mintBatchToMany(address[] memory recipients, uint256[] memory tokenIds) external  onlyAdmin {
        require(tokenIds.length == recipients.length,"mintBatchToMany: Array length error");
        for (uint j = 0; j < tokenIds.length; j++) {
            require(!_exists(tokenIds[j]),"mintBatchToMany: One or more allocated tokens exists");
        }
        for (uint j = 0; j < tokenIds.length; j++) {
            _minty(
                recipients[j],
                tokenIds[j]
            );
        }
    }

    function mintBatchToManyR(address[] memory recipients, uint256[] memory tokenIds) external  onlyAdmin {
        uint256 len = tokenIds.length;
        uint256[] memory newTids = new uint256[](len);
        require(tokenIds.length == recipients.length,"mintBatchToManyR: Array length error");
        for (uint j = 0; j < tokenIds.length; j++) {
            newTids[j] = yesterday(tokenIds[j]);
            require(!_exists(newTids[j]),"mintBatchToManyR: One or more allocated tokens exists");
        }
        for (uint j = 0; j < tokenIds.length; j++) {
            _minty(
                recipients[j],
                newTids[j]
            );
        }
    }

    function mintReplacement(address user, uint256 tokenId) external onlyAdmin {
        _minty(user, tokenId);
    }


    function _minty(address user, uint256 tokenId) internal {
        require(tokenId > 0, "No Zero TokenIds");
        _mint(user,tokenId);
        allTokens[count++] = tokenId;
    }
 



    // RANDOMISATION --cut-here-8x------------------------------

    function setRevealedBaseURI(string calldata thisURI) external onlyAdmin {
        _thisURI = thisURI;
        emit BaseURIChanged(thisURI);
    }

 
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        uint256 folderNo;
        uint256 fileNo;
        
        require(_exists(tokenId), 'Token does not exist');
        
        string memory revealedBaseURI = _thisURI;

        if (bytes(uris[tokenId]).length != 0) {
            return uris[tokenId] ;
        }


        if (tokenId <= 10000) {
            folderNo = ((((tokenId / 100) + _rand) % 100) + 1);
            fileNo     = (tokenId % 100);
            
        } else {
            folderNo = ((tokenId-1) / 100)+1;  // 10,000 => 100, 13800 => 138
            fileNo   = (tokenId -1) % 100;
        }
        string memory folder     = folderNo.toString();
        string memory file       = fileNo.toString();

        return string(abi.encodePacked(revealedBaseURI,folder,"/",file)) ;
    }

    function totalSupply() external view returns (uint256) {
        return count;
    }
    
    function setURI(uint256 tokenId, string memory replacement) external onlyAdmin {
        uris[tokenId] = replacement;
        emit UpdatedURI(tokenId,replacement);
    }

    function setPerTokenRoyalty(uint256 tokenId, address destination, uint256 amount) external onlyAdmin {
        _per_token_royalty_destination[tokenId] = destination;
        _per_token_royalty_amount[tokenId]        = amount;
        emit SetPerTokenRoyalties(tokenId,destination,amount);
    }

    function setDefaultRoyalties(address destination, uint256 amount) external onlyAdmin {
        _twtAddress = destination;
        _royalty    = amount;
        emit SetDefaultRoyalties(destination,amount);
    }

}