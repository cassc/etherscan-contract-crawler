// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IEIP2981.sol";

contract WXYZ is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    EIP2981RoyaltyOverrideCore
{
    enum MintState {
        ALLOW,
        PUBLIC,
        FREE,
        DISABLED
    }

    struct Config {
        uint8 mintState;
        uint256 mintPrice;
        uint16 maxSupply;
        uint256 totalSupply;
        uint8 maxMintsPerTx;
    }

    bytes32 public allowlistMerkleRoot =
        0x59fa68dc0e3cae0595133148c404fb25c3b8c1ccf315311de739c5a469441f5d;
    bytes32 public freelistMerkleRoot =
        0x59fa68dc0e3cae0595133148c404fb25c3b8c1ccf315311de739c5a469441f5d;
    string public baseTokenURI = "https://wxyz-staging.onrender.com/api/tokens/";
    uint256 public mintPrice = 0.0001 ether;
    MintState public mintState = MintState.DISABLED;
    uint16 public maxSupply = 10;
    uint16 public freeMintSupply;
    uint8 public maxMintsPerTx = 5;
    address public fundsReceiver = 0xe62cfbd11cdF646Ce76c21d79c93071f8f0C3148;
    mapping(bytes32 => bool) public freeMintedList;
    uint8 public freeListVersion = 0;

    // MODIFIERS
    modifier mintCompliance(uint256 _mintAmount) {
        require(mintState != MintState.DISABLED, "Mint disabled");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintsPerTx,
            "Invalid mint amount"
        );

        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded"
        );
        _;
    }

    constructor() ERC721A("WXYZ", "WXYZ") {
        defaultRoyalty = TokenRoyalty(fundsReceiver, 500);
    }

    // OVERRIDES
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // MESSAGES
    function setMaxSupply(uint16 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Cannot increase the supply");
        maxSupply = _maxSupply;
    }

    function setBaseTokenURI(string memory newBaseUri) public onlyOwner {
        baseTokenURI = newBaseUri;
    }

    function setMintState(
        MintState _mintState,
        uint8 _maxMintsPerTx
    ) public onlyOwner {
        mintState = _mintState;
        maxMintsPerTx = _maxMintsPerTx;
    }

    function setAllowlistMerkleRoot(
        bytes32 _allowlistMerkleRoot
    ) public onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function setFreeListMintData(
        bytes32 _freeListMerkleRoot,
        uint16 _freeMintListCount
    ) public onlyOwner {
        freelistMerkleRoot = _freeListMerkleRoot;
        freeMintSupply = _freeMintListCount;
    }

    function publicMint(uint256 amount) public payable mintCompliance(amount) {
        require(mintState == MintState.PUBLIC, "Public mint is disabled");
        require(msg.value == mintPrice * amount, "Insufficient funds");
        require(
            totalSupply() + amount <= maxSupply - freeMintSupply,
            "Can't mint that many"
        );

        _safeMint(msg.sender, amount);
    }

    function allowlistMint(
        uint256 amount,
        bytes32[] calldata proof
    ) public payable mintCompliance(amount) {
        require(mintState == MintState.ALLOW, "Allow list mint is disabled");
        require(msg.value == mintPrice * amount, "Insufficient funds");
        require(
            totalSupply() + amount <= maxSupply - freeMintSupply,
            "Can't mint that many"
        );
        require(_verifyAllowlist(proof, msg.sender), "Invalid proof");

        _safeMint(msg.sender, amount);
    }

    function freeMint(bytes32[] calldata proof) public nonReentrant {
        bytes32 key = keccak256(abi.encodePacked(freeListVersion, msg.sender));
        require(mintState == MintState.FREE, "Free mint is disabled");
        require(totalSupply() + 1 <= maxSupply, "Can't mint that many");
        require(_verifyFreeMint(proof, msg.sender), "Invalid proof");
        require(freeMintedList[key] == false, "Can't mint more than 1 token");

        _safeMint(msg.sender, 1);

        freeMintedList[key] = true;
    }

    function resetFreeList() public onlyOwner {
        freeListVersion++;
    }

    function withdrawFunds() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        // solhint-disable-next-line
        (bool success, ) = payable(fundsReceiver).call{value: contractBalance}(
            ""
        );

        require(success, "Transfer failed");
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setTokenRoyalties}.
     */
    function setTokenRoyalties(
        TokenRoyaltyConfig[] calldata royaltyConfigs
    ) external override onlyOwner {
        _setTokenRoyalties(royaltyConfigs);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setDefaultRoyalty}.
     */
    function setDefaultRoyalty(
        TokenRoyalty calldata royalty
    ) external override onlyOwner {
        _setDefaultRoyalty(royalty);
    }

    // MERKLE TREE
    function _verifyAllowlist(
        bytes32[] memory proof,
        address account
    ) internal view returns (bool) {
        bytes32 leaf = _leaf(account);
        return MerkleProof.verify(proof, allowlistMerkleRoot, leaf);
    }

    function _verifyFreeMint(
        bytes32[] memory proof,
        address account
    ) internal view returns (bool) {
        bytes32 leaf = _leaf(account);
        return MerkleProof.verify(proof, freelistMerkleRoot, leaf);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    // QUERIES
    function getOwnerTokens(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);
        uint256 ownerTokenIdx = 0;
        for (
            uint256 tokenIdx = _startTokenId();
            tokenIdx <= totalSupply();
            tokenIdx++
        ) {
            if (ownerOf(tokenIdx) == _owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                ownerTokenIdx++;
            }
        }
        return ownerTokens;
    }

    function getConfig() public view returns (Config memory) {
        Config memory config = Config({
            mintState: uint8(mintState),
            mintPrice: mintPrice,
            maxSupply: maxSupply,
            totalSupply: totalSupply(),
            maxMintsPerTx: maxMintsPerTx
        });
        return config;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, EIP2981RoyaltyOverrideCore)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }

    function hasUserFreeMinted(address owner) public view returns (bool) {
        return
            freeMintedList[keccak256(abi.encodePacked(freeListVersion, owner))];
    }
}