// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./interface/IFTNFT.sol";

contract FTNFT is ERC721Enumerable, ERC721Burnable, IFTNFT {
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using Strings for uint256;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseTokenURI;

    mapping (uint256 => uint256) private _tokens;

    EnumerableMap.UintToUintMap private _templateIds;

    TemplateStruct[] private _templates;

    constructor() ERC721("FTNFT", "FTNFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function mint(address to, uint256 templateId) public override returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "FTNFT: Must have minter role to mint");
        require(_templateIds.contains(templateId), "FTNFT: Template id is not exist");
        
        uint256 index = _templateIds.get(templateId);
        TemplateStruct storage template = _templates[index];
        require(template.enable, "FTNFT: Template is not enable");
        require(template.issue + 1 <= template.amount, "FTNFT: Template amount Insufficient quantity");
        template.issue += 1;

        uint256 tokenId = template.templateId * 100000 + template.issue;
        _mint(to, tokenId);

        _tokens[tokenId] = templateId;

        return tokenId;
    }

    /**
     * Set templates
     */
    function setTemplate(TemplateStruct calldata template) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FTNFT: Must have admin role to set template");
        
        uint256 index = _templates.length;
        bool isFound = false;
        for (uint256 i = 0; i < index; i++) {
            if (_templates[i].templateId == template.templateId) {
                isFound = true;
                _templates[i] = template;
                _templateIds.set(template.templateId, i);
            }
        }
        if (!isFound) {
            _templates.push(template);
            _templateIds.set(template.templateId, index);
        }
    }

    /**
     * Get templates
     */
    function getTemplates() public view override returns (TemplateStruct[] memory) {
        return _templates;
    }

    /**
     * Get template
     */
    function getTemplateById(uint256 templateId) public view override returns (TemplateStruct memory) {
        require(_templateIds.contains(templateId), "FTNFT: Template id is not exist");
        uint256 index = _templateIds.get(templateId);
        require(_templates[index].enable, "FTNFT: Template is not enable");

        return _templates[index];
    }

    /**
     * Get template id by tokenId
     */
    function getTemplateIdByTokenId(uint256 tokenId) public view override returns (uint256) {
        require(_exists(tokenId), "FTNFT: TemplateId query for nonexistent token");
        
        return _tokens[tokenId];
    }

    /**
     * Get template by tokenId
     */
    function getTemplateByTokenId(uint256 tokenId) public view override returns (TemplateStruct memory) {
        require(_exists(tokenId), "FTNFT: URI query for nonexistent token");

        uint256 templateId = _tokens[tokenId];
        return getTemplateById(templateId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json")) : "";
    }

    function setBaseURI(string calldata baseTokenURI) public  {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FTNFT: Must have admin role to chande baseURI");

        _baseTokenURI = baseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

     /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, IFTNFT)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}