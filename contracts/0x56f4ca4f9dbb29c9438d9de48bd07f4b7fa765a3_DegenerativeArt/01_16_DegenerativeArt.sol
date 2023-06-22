// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///////////////////////////////////////////////////
//   _                                           //
//  | \ _  _  _ ._  _ .__._|_o   _   /\ .__|_ _  //
//  |_/(/_(_|(/_| |(/_|(_| |_|\/(/_ /--\|  |__>  //
//         _|                                    //
///////////////////////////////////////////////////

import "ozc-4/access/AccessControl.sol";
import "ozc-4/token/ERC721/extensions/ERC721Burnable.sol";
import "ozc-4/token/ERC721/extensions/ERC721Enumerable.sol";
import "ozc-4/utils/Counters.sol";


contract DegenerativeArt is AccessControl, ERC721Burnable, ERC721Enumerable {
    using Counters for Counters.Counter;

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");
        _;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant MAX_SUPPLY = 200;
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;
    
    bool public isSaleActive;
    string public baseURI;
    bool public isFrozen;

    Counters.Counter private _nextId;

    constructor(string memory newBaseURI) ERC721("Degenerative ART", "DGEN") {
        baseURI = newBaseURI;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint() external payable {
        require(isSaleActive, "Sale isn't active");
        require(PRICE_PER_TOKEN <= msg.value, "Invalid price");
        require(_nextId.current() < MAX_SUPPLY, "Will exceed supply");

        _nextId.increment();
        _safeMint(msg.sender, _nextId.current());
    }

    function reserveMint(uint256 count, address to) public onlyRole(MINTER_ROLE) {
        require(_nextId.current() + count <= MAX_SUPPLY, "Will exceed supply");

        for (uint idx = 0; idx < count; idx++) {
            _nextId.increment();
            _safeMint(to, _nextId.current());
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function flipSaleState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        isSaleActive = !isSaleActive;
    }

    function freeze() public onlyRole(DEFAULT_ADMIN_ROLE) {
        isFrozen = true;
    }

    function setBaseURI(string calldata newBaseUri) external 
        contractIsNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function batchReserveMint(address[] calldata recipients) external onlyRole(MINTER_ROLE) {
        require(_nextId.current() + recipients.length <= MAX_SUPPLY, "Will exceed supply");

        for (uint i = 0; i < recipients.length; ++i) {
            _nextId.increment();
            _safeMint(recipients[i], _nextId.current());
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}