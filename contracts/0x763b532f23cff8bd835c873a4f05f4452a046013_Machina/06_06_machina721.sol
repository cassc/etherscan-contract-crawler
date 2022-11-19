// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Solidity Modules
import {ERC721B} from "cyphersuite/tokens/ERC721/ERC721B.sol";
import {ERC721TokenURI} from "cyphersuite/metadata/ERC721TokenURI.sol";
import {Ownable} from "cyphersuite/access/Ownable.sol";
import {Controllerable} from "cyphersuite/access/Controllerable.sol";
import {OSSubscribeFilter} from "cyphersuite/control/OSSubscribeFilter.sol";

contract Machina is ERC721B("Machina", "MACHINA"), ERC721TokenURI, Ownable,
Controllerable, OSSubscribeFilter {

    ///// Proxy Initializer /////
    bool public proxyIsInitialized;
    function proxyInitialize(address newOwner_) public {
        require(!proxyIsInitialized, "Proxy already initialized");
        proxyIsInitialized = true;

        // Hardcode
        owner = newOwner_; // Ownable.sol

        name = "Machina"; // ERC721B.sol
        symbol = "MACHINA"; // ERC721B.sol
        nextTokenId = startTokenId(); // ERC721B.sol
    }

    ///// Constructor (For Implementation Contract) /////
    constructor() {
        proxyInitialize(msg.sender);
    }

    ///// Controllerable Config /////
    modifier onlyMinter() {
        require(isController("Minter", msg.sender),
                "Controllerable: Not Minter!");
        _;
    }

    ///// ERC721B Overrides /////
    function startTokenId() public pure virtual override returns (uint256) {
        return 1;
    }

    ///// Ownable Functions /////
    function ownerMint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }
    function ownerBurn(uint256[] calldata tokenIds_) external onlyOwner {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do {
            _burn(tokenIds_[i], false);
        } while (++i < l); }
    }

    ///// Controllerable Functions /////
    function mintAsController(address to_, uint256 amount_) external onlyMinter {
        _mint(to_, amount_);
    }

    ///// Metadata Governance /////
    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }

    ///// OS Subscribe Filter Config /////
    function setOSRegisterAndSubscribe(address subscribeTo_) external onlyOwner {
        _OSRegisterAndSubscribe(subscribeTo_);
    }

    ///// OS Subscribe Filter Overrides /////
    function setApprovalForAll(address operator_, bool approved_) public override
    onlyAllowedOperatorApproval(operator_) {
        super.setApprovalForAll(operator_, approved_);
    }
    function approve(address operator_, uint256 tokenId_) public override
    onlyAllowedOperatorApproval(operator_) {
        super.approve(operator_, tokenId_);
    }
    function transferFrom(address from_, address to_, uint256 tokenId_) public override
    onlyAllowedOperator(from_) {
        super.transferFrom(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public
    override onlyAllowedOperator(from_) {
        super.safeTransferFrom(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, 
    bytes memory data_) public override onlyAllowedOperator(from_) {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    ///// OS Subscribe Filter View /////
    function isOperatorAllowedOS(address operator_) external view returns (bool) {
        return OSFilterRegistry.isOperatorAllowed(address(this), operator_);
    }

    ///// TokenURI /////
    function tokenURI(uint256 tokenId_) public virtual view override 
    returns (string memory) {
        require(ownerOf(tokenId_) != address(0), "Token does not exist!");
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_)));
    }
}