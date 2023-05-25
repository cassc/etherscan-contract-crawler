// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../OperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract DelabsAdventurePass is ERC721, OperatorFilterer, Ownable, ReentrancyGuard, ERC2981 {
    bool public operatorFilteringEnabled;
    
    using ECDSA for bytes32;
    using Address for address;

    uint64 public totalSupply;
    uint64 private _tokenIdCounter;
 
    // Minting
    bool public allowlistSaleActive = false;
    bool public publicSaleActive = false;
    uint256 public maxMintPerAccount = 1;
    uint256 public price = 0.1 ether;
    uint256 public MAX_SUPPLY = 3433;

    // Base URI
    string private baseURI;

    // Allowlist verification
    mapping (address => uint256) public mintClaimed;
    address private signVerifier;

    event Mint(address recipient, uint256 tokenId);


    constructor() ERC721("DelabsAdventurePass", "DAP") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(msg.sender, 500);

        signVerifier = 0x35d82668A68b8b77c9ca6C742fF08c822f32406a;
        baseURI = "https://api.delabs.gg/adventurepass/";
    }

    function toggleAllowlistSale() external onlyOwner {
        allowlistSaleActive = !allowlistSaleActive;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    // @dev Generate hash to prove whitelist eligibility
    function getSigningHash(address recipient) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(recipient));
    }

    // @dev Sets a new signature verifier
    function setSignVerifier(address verifier) external onlyOwner {
        signVerifier = verifier;
    }

    function isValidSignature(address recipient, bytes memory sig) private view returns (bool) {
        bytes32 message = getSigningHash(recipient).toEthSignedMessageHash();
        return ECDSA.recover(message, sig) == signVerifier;
    }

    function allowlistSaleMint(bytes memory sig) external payable nonReentrant {
        uint256 claimed = mintClaimed[msg.sender];

        require(allowlistSaleActive, "Allowlist Sale must be active to mint");
        require(isValidSignature(msg.sender, sig), "Account is not authorized for Allowlist Sale");
        require(claimed + 1 <= maxMintPerAccount, "Amount exceeds mintable limit");
        require(totalSupply + 1 <= MAX_SUPPLY, "Further minting would exceed max supply");
        require(msg.value >= price, "Ether value sent is not correct");

        mintClaimed[msg.sender] = claimed + 1;
       
        uint256 tokenId = ++_tokenIdCounter;
        ++totalSupply;
        emit Mint(msg.sender, tokenId);
        _safeMint(msg.sender, tokenId);

    }


    function publicMint() external payable nonReentrant {
        uint256 claimed = mintClaimed[msg.sender];
        require(publicSaleActive, "Public Sale must be active to mint");
        require(claimed +1 <= maxMintPerAccount, "Amount exceeds mintable limit");
        require(totalSupply + 1 <= MAX_SUPPLY, "Further minting would exceed max supply");
        require(msg.value >= price, "Ether value sent is not correct");
        require(msg.sender == tx.origin, "Sender is not tx origin");

        mintClaimed[msg.sender] = claimed + 1;
        ++totalSupply;

        uint256 tokenId = ++_tokenIdCounter;
        emit Mint(msg.sender, tokenId);
        _safeMint(msg.sender, tokenId);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner nonReentrant{
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function bulkTransfer(uint256[] calldata tokenIds, address _to) external onlyOwner nonReentrant {
        for (uint256 i; i < tokenIds.length;i++) {
            _transfer(msg.sender, _to, tokenIds[i]);
        }
    }

    // @dev Private mint function reserved for company.
    function adminMint(uint256 numberOfMints, address recipient) external onlyOwner nonReentrant {

        require(numberOfMints > 0, "The minimum number of mints is 1");
        require(totalSupply + numberOfMints <= MAX_SUPPLY, "Further minting would exceed max supply");

        for (uint256 i; i < numberOfMints; i++) {
            uint256 tokenId = ++_tokenIdCounter;
            ++totalSupply;

            emit Mint(recipient, tokenId);
            _safeMint(recipient, tokenId);
        }
    }


    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}