pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RaxTribute is DefaultOperatorFilterer, ERC721A, ERC2981, AccessControl, Ownable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant BASE_URI = "https://ipfs.madworld.io/raxtribute/";
    address public constant OWNER_ADDRESS = 0x58B7105220a6C64f47A63Ef0C396Af8d5fCe5933;
    address public constant ROYALTY_FEE_ADDRESS = 0x2Bc20C35F7a5059D38CfDafAbC70F9d8cB1AA5f1;
    
    constructor() ERC721A("RaxTribute", "RaxTribute") {
        _grantRole(DEFAULT_ADMIN_ROLE, OWNER_ADDRESS);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(ROYALTY_FEE_ADDRESS, 250); // 2.5%
        _transferOwnership(OWNER_ADDRESS);
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(BASE_URI, "metadata.json"));
    }

    function safeMint(
        address to,
        uint256 quantity
    ) public onlyRole(MINTER_ROLE) {
        _mint(to, quantity);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function setDefaultRoyalty(address recipient, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(recipient, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        payable
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}