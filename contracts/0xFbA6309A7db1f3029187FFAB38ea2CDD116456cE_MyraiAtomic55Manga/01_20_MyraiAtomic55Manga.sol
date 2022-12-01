// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

import 'hardhat/console.sol';

contract MyraiAtomic55Manga is
    DefaultOperatorFilterer,
    ERC721A,
    ERC2981,
    Ownable,
    Pausable
{
    string public contractURI;
    uint256 public maxTokens;
    uint256 public numOfAllowedFreeMints = 1;
    uint256 public maxFreeTokens = 2000;
    bool public isRevealed;
    bool public freeMintActive;
    bool public holderMintActive;
    address public admin;
    string private baseURIAddress;
    bytes32 private wlMerkleRoot;
    /** addr to # of allowed mints */
    mapping(address => uint256) public holdersWl;

    constructor(
        string memory _contractURI,
        uint256 _maxTokens,
        address _admin,
        string memory baseURI,
        bytes32 _wlMerkleRoot
    ) ERC721A('MyraiAtomic55Manga', 'MYRAI_ATOMIC_55_MANGA') {
        _setDefaultRoyalty(_admin, 1000);
        contractURI = _contractURI;
        maxTokens = _maxTokens;
        baseURIAddress = baseURI;
        admin = _admin;
        wlMerkleRoot = _wlMerkleRoot;
    }

    function buildWl(address[] memory addresses, uint256[] memory allowedQty)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            holdersWl[addresses[i]] = allowedQty[i];
        }
    }

    /** ------------------------
    Minting
    ---------------------------- */

    function freeMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        whenNotPaused
    {
        require(isfreeMintActive(), 'Sale not active');
        require(msg.sender == tx.origin, 'NotContractMintable');
        require(quantity > 0, 'zero');

        // this might crash for non holder wl's
        bool isHolder = holdersWl[msg.sender] > 0;
        require(
            isPartOfWhitelist(msg.sender, merkleProof) || isHolder,
            'wallet not allowed to mint'
        );

        uint256 mints = _numberMinted(msg.sender);
        require(
            mints + quantity < numOfAllowedFreeMints + 1,
            'max qty per wallet minted'
        );

        require(
            _totalMinted() + quantity < maxFreeTokens + 1,
            'Qty exceeds max available tokens'
        );
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external whenNotPaused {
        require(isHolderMintActive(), 'Sale not active');
        require(msg.sender == tx.origin, 'NotContractMintable');
        require(quantity > 0, 'zero');
        uint256 numberOfAllowedMints = holdersWl[msg.sender];
        require(numberOfAllowedMints > 0, 'wallet not allowed to mint');
        numberOfAllowedMints = numberOfAllowedMints + 1;

        uint256 mints = _numberMinted(msg.sender);
        require(
            mints + quantity < numberOfAllowedMints + 1,
            'max qty per wallet minted'
        );
        require(
            _totalMinted() + quantity < maxTokens + 1,
            'Qty exceeds max available tokens'
        );
        _safeMint(msg.sender, quantity);
    }

    function isHolderMintActive() private view returns (bool) {
        return holderMintActive && !paused() && (_totalMinted() != maxTokens);
    }

    function isfreeMintActive() private view returns (bool) {
        return freeMintActive && !paused() && (_totalMinted() != maxTokens);
    }

    function adminMint(uint256 quantity) external onlyOwner {
        _safeMint(admin, quantity);
    }

    function burnYourTokens(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i != tokenIds.length; ++i) {
            _burn(tokenIds[i], true);
        }
    }

    function isPartOfWhitelist(address _address, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, wlMerkleRoot, leaf);
    }

    /** ------------------------
    Overrides
    ---------------------------- */

    function _baseURI() internal view override returns (string memory) {
        return baseURIAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isRevealed) {
            return
                string(
                    abi.encodePacked(
                        _baseURI(),
                        Strings.toString(tokenId),
                        '.json'
                    )
                );
        }

        return _baseURI();
    }

    /** -----------------------
    Getters
    --------------------------- */

    function getTotalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /** ----------------------------
    Setters - Owner Only Accessible
    -------------------------------- */

    function setBaseURI(string memory _baseURIAddress) external onlyOwner {
        baseURIAddress = _baseURIAddress;
    }

    function setMaxTokens(uint256 _maxTokens) external onlyOwner {
        maxTokens = _maxTokens;
    }

    function setMaxFreeTokens(uint256 _maxFreeTokens) external onlyOwner {
        maxFreeTokens = _maxFreeTokens;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setWlMerkleRoot(bytes32 _wlMerkleRoot) external onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    function setRoyalty(address _address, uint96 royaltyFee)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_address, royaltyFee);
    }

    function setIsRevealed(bool _isRevealed, string memory _baseURIAddress)
        external
        onlyOwner
    {
        isRevealed = _isRevealed;
        baseURIAddress = _baseURIAddress;
    }

    /** ----------------------------
    Toggles - Owner Only Accessible
    -------------------------------- */

    function toggleFreeMint() external onlyOwner {
        freeMintActive = !freeMintActive;
        holderMintActive = false;
    }

    function toggleHoldersMint() external onlyOwner {
        holderMintActive = !holderMintActive;
        freeMintActive = false;
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}