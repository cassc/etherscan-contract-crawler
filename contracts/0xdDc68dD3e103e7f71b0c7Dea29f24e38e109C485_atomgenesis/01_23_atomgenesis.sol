pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract atomgenesis is DefaultOperatorFilterer, ERC721, ERC2981, ERC721Enumerable, AccessControl, Ownable {

    string  private constant BASE_URI = "https://ipfs.madworld.io/atomgenesis/";
    address private constant OWNER_ADDRESS = 0xB79fd036d5E0867E0C18FaCf9e2DE95CC71A6bBb;
    uint256 private constant INIT_TOKEN_ID = 100001232006000001;
    uint256 private constant MAX_TOTAL_NUM = 160;

    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("atomgenesis", "atomgenesis") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setDefaultRoyalty(OWNER_ADDRESS, 500); // 5%
        _transferOwnership(OWNER_ADDRESS);
    }

    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(BASE_URI, "metadata.json"));
    }

    function safeMint(address to, uint256 numberOfTokens) public onlyRole(MINTER_ROLE) {
        // check MAX_TOTAL_NUM
        require(_tokenIdCounter.current() + numberOfTokens <= MAX_TOTAL_NUM, "atomgenesis: MAX_TOTAL_NUM exceeded");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId + INIT_TOKEN_ID);
        }
    }

    function batchMint(address[] memory to, uint256[] memory number) public onlyRole(MINTER_ROLE) {
        require(number.length == to.length, "atomgenesis: number and to length mismatch");

        for (uint i = 0; i < number.length; i++) {
            require(number[i] > 0, "atomgenesis: number must be greater than 0");
            safeMint(to[i], number[i]);
        }
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    function setDefaultRoyalty(address recipient, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(recipient, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}