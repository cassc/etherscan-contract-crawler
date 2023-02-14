// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/interfaces/IERC2981.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

contract LoveBirds is ERC721, IERC2981, DefaultOperatorFilterer  {

    string [] uriComponents;
    uint256 public tokenId;
    uint256 royaltyAmount;
    address royaltiesRecipient;
    bool public foundLove;
    mapping(address => bool) private isAdmin;
    mapping(uint256 => mapping(bool=> string[])) private uris;

    error InvalidAddress();
    error InvalidUris();
    error InvalidTokenId();
    error Unauthorized();

    constructor() ERC721("Love Birds", "Love Birds"){
        isAdmin[msg.sender] = true;
        uriComponents = [
            'data:application/json;utf8,{"name":"',
            '", "description":"',
            '", "created_by":"Smokestacks & Smartcontrart", "image":"data:image/svg+xml;utf8,',
            '", "attributes":[',
            ']}'
        ];
        tokenId = 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
        ERC721.supportsInterface(interfaceId) ||
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    modifier adminRequired() {
        if (!isAdmin[msg.sender]) revert Unauthorized();
        _;
    }

    function toggleAdmin(address _admin) external adminRequired {
        isAdmin[_admin] = !isAdmin[_admin];
    }

    function mint(address _to) external adminRequired {
        if(tokenId > 0){
            if(_to == ownerOf(0)) revert InvalidAddress();
            if(tokenId > 1) revert InvalidTokenId();
        }
        _mint(_to, tokenId);
        tokenId ++;
    }

    function burn(uint256 _tokenId) external {
        if(ownerOf(_tokenId) != msg.sender) revert InvalidTokenId();
        _burn(_tokenId);
    }

    function setURI(uint256 _tokenId, bool _foundLove, string[] calldata _uris) external adminRequired {
        if(_foundLove){
            if(_uris.length != 1) revert InvalidUris();
        }else{
            if(_uris.length != 2) revert InvalidUris();
        }
        delete uris[_tokenId][_foundLove];
        for(uint8 i=0; i < _uris.length; i++){
            uris[_tokenId][_foundLove].push(_uris[i]);
        }
    }

    function _afterTokenTransfer(
        address _from, 
        address _to, 
        uint256 _firstTokenId, 
        uint256 _batchSize
    ) override internal {
        if(_from != address(0)){
            if(ownerOf(0) == ownerOf(1)){
                foundLove = true;
            }else{
                foundLove = false;
            }
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory name = _tokenId == 0 ? 'Noah' : 'Allie';
        string memory description = 'Swear an oath to bring them both within their lovers light';
        string memory image;
        bool searchCondition;
        if(_tokenId == 0){
            searchCondition = (block.number % 7200 >= 4800);
        }else{
            searchCondition = (block.number % 7200 < 2400);
        }
        if(foundLove || searchCondition){
            image = uris[_tokenId][foundLove][0];
        }else{
            image = uris[_tokenId][foundLove][1];
        }
        string memory attributes = '';
        bytes memory byteString = abi.encodePacked(
            abi.encodePacked(uriComponents[0], name),
            abi.encodePacked(uriComponents[1], description),
            abi.encodePacked(uriComponents[2], image),
            abi.encodePacked(uriComponents[3], attributes),
            abi.encodePacked(uriComponents[4])
        );
        return string(byteString);
    }

    // Royalties functions
    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external adminRequired {
        royaltiesRecipient = _recipient;
        royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 _tokenId, uint256 salePrice) external view returns (address, uint256) {
        if(royaltiesRecipient != address(0)){
            return (royaltiesRecipient, (salePrice * royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    // Opensea's gatekeeping functions
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }



}