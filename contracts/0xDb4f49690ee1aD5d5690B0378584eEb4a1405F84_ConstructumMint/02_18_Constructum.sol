// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IEIP2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Constructum is ERC721, DefaultOperatorFilterer {
    
    address payable  private _royalties_recipient;
    
    uint256 private _royaltyAmount; //in % 
    uint256 public _tokenId;

    string[] private _uriComponents;
    string private _uri;

    mapping(uint256 => string) _visuals;    
    mapping(uint256 => string) _innerColorsOptions;
    mapping(uint256 => string) _outerOptions;
    mapping(uint256 => string) _decorationsOptions;
    mapping(uint256 => uint256) _innerColors;
    mapping(uint256 => uint256) _outerColors;
    mapping(uint256 => uint256) _decorations;
    mapping(address => bool) public _isAdmin;
    
    constructor () ERC721("Constructum", "Constructum") {
        _tokenId = 0;
        _uriComponents = [
                'data:application/json;utf8,{"name":"',
                '", "description":"',
                '", "created_by":"Simply Anders", "image":"',
                '", "image_url":"',
                '", "animation":"',
                '", "animation_url":"',
                '", "attributes":[',
                ']}'];

        _innerColorsOptions[0] = 'Black';
        _innerColorsOptions[1] = 'White';
        _innerColorsOptions[2] = 'Blue';
        _innerColorsOptions[3] = 'Green';
        _innerColorsOptions[4] = 'Pink';

        _outerOptions[0] = '6d';
        _outerOptions[1] = '10d';
        _outerOptions[2] = '10r';
        _outerOptions[3] = '15d';
        _outerOptions[4] = 'Donut';

        _decorationsOptions[0] = 'Circles';
        _decorationsOptions[1] = 'Flow';
        _decorationsOptions[2] = 'Intersection';
        _decorationsOptions[3] = 'Spheres';
        _decorationsOptions[4] = 'Squares';

        _isAdmin[msg.sender] = true;
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
        ERC721.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    modifier adminRequired(){
        require(_isAdmin[msg.sender], 'Only admins can perfom this action');
        _;
    }

    function mint( 
        address to,
        uint256 innerColor,
        uint256 outerColor,
        uint256 decoration
    ) external adminRequired{
        _mint(to, _tokenId);
        _innerColors[_tokenId] = innerColor;
        _outerColors[_tokenId] = outerColor;
        _decorations[_tokenId] = decoration;
        _visuals[_tokenId] = string(abi.encodePacked(
            Strings.toString(innerColor), 
            Strings.toString(outerColor), 
            Strings.toString(decoration)
        ));
        _tokenId ++;
    }

    function toggleAdmin(address admin)external adminRequired{
        _isAdmin[admin] = !_isAdmin[admin];
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(msg.sender == owner, "Owner only");
        _burn(tokenId);
    }

    function setURI(
        string calldata uri
    ) external adminRequired{
        _uri = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory name;
        string memory description;
        string memory image;
        string memory animation;
        string memory attributes;

        name = 'Constructum';
        description = 'Constructum is an interactive drop where minters make choices to customize their NFT. There are 125 possible outcomes, but only 55 will ever come to life. Artwork by Simply Anders. Custom website and smart contract by Smartcontrart.';
        attributes = string(abi.encodePacked(
            '{"trait_type": "Color", "value": "',
            _innerColorsOptions[_innerColors[tokenId]],
            '"},{"trait_type": "Outer Shell", "value": "',
            _outerOptions[_outerColors[tokenId]],
            '"},{"trait_type": "Decoration", "value": "',
            _decorationsOptions[_decorations[tokenId]],
            '"}'));
        image = string(abi.encodePacked(_uri, "/images/", _visuals[tokenId], ".jpg"));
        animation = string(abi.encodePacked(_uri, "/animations/", _visuals[tokenId], ".mp4"));
        bytes memory byteString = abi.encodePacked(
            abi.encodePacked(_uriComponents[0], name),
            abi.encodePacked(_uriComponents[1], description),
            abi.encodePacked(_uriComponents[2], image),
            abi.encodePacked(_uriComponents[3], image),
            abi.encodePacked(_uriComponents[4], animation),
            abi.encodePacked(_uriComponents[5], animation),
            abi.encodePacked(_uriComponents[6], attributes),
            abi.encodePacked(_uriComponents[7])
        );
        return string(byteString);
    }

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

    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external adminRequired {
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(_royalties_recipient != address(0)){
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }

}