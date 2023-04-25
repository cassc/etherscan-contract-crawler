// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721AUpgradeable} from "./utils/ERC721AUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {UpdatableOperatorFilterer} from "./OpenseaRegistries/UpdatableOperatorFilterer.sol";

contract TestIMS is
OwnableUpgradeable,
ERC721AUpgradeable,
RevokableDefaultOperatorFiltererUpgradeable {
    
    string public baseURI;
    
    mapping(address => bool) public isController;
    
    modifier onlyController(address from) {
        require(isController[from], "Not a Controller");
        _;
    }
    
    function initialize(string memory name, string memory symbol) external initializer {
        __Ownable_init();
        __ERC721A_init(name,symbol);
        __RevokableDefaultOperatorFilterer_init();
    }
    
    function mint(address to, uint256 amount) external onlyController(msg.sender) {
        _mint(to,amount);
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(bytes(newBaseURI).length > 0, "Invalid Base URI Provided");
        baseURI = newBaseURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function toggleController(address controller) public onlyOwner {
        isController[controller] = !isController[controller];
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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
    
    function owner()
    public
    view
    virtual
    override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
    returns (address)
    {
        return OwnableUpgradeable.owner();
    }
}