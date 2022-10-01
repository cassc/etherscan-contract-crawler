// SPDX-License-Identifier: MIT
// Creator: Andrew Cunningham

pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract BakedBuds is ERC721A, ERC2981, Ownable, Pausable, PaymentSplitter {
    uint96 public maxQuantityPerTxn = 5;
    string public contractURI;
    uint256 public maxTokens = 4200;
    uint256 public price = 0.03 ether;
    uint256 public maxQuantityForPresale = 4;

    string private _baseURIAddress;
    bytes32 private _presaleMerkleRoot;
    address public admin;

    /** Hardcoded parameters */
    uint256 private _maxPresaleAmount = 1010; // max presale + reserved tokens
    uint256 private _reservedTokensAmount = 220;
    string private _metadataExtension = '.json';

    /** flags */
    bool private _presaleActive;
    bool private _publicSaleActive;
    bool private _isRevealed;

    constructor(
        string memory baseURI,
        string memory _contractURI,
        bytes32 merkleRoot,
        address _admin,
        uint96 royaltyFee,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721A('BakedBuds', 'BAKE') PaymentSplitter(payees, shares) {
        /* URI for unrevealed */
        _baseURIAddress = baseURI;
        admin = _admin;

        _presaleMerkleRoot = merkleRoot;

        /* secondary market royalties */
        _setDefaultRoyalty(admin, royaltyFee);

        /* contract metadata */
        contractURI = _contractURI;
    }

    /** ------------------------
    Minting
    ---------------------------- */

    function publicMint(uint256 quantity) external payable whenNotPaused {
        require(_isPublicSaleMintable(), 'Sale not active');
        require(quantity > 0, 'Zero');
        require(msg.value == price * quantity, 'NonEqualValue');
        _mintToken(quantity);
    }

    function presaleMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
    {
        require(_isPresaleMintable(), 'Sale not active');
        
        require(msg.value == price * quantity, 'NonEqualValue');
        uint256 mints = _numberMinted(msg.sender);
        require(mints + quantity < maxQuantityForPresale + 1, 'Max quantity reached');
        require(
            _totalMinted() + quantity < _maxPresaleAmount + 1,
            'Max presale quantity per wallet minted'
        );
        require(_isWhitelistApproved(msg.sender, merkleProof), 'Not on whitelist');
        _mintToken(quantity);
    }

    function _mintToken(uint256 quantity) private {
        require(msg.sender == tx.origin, 'NotContractMintable');
        require(quantity < maxQuantityPerTxn + 1, 'Max presale quantity per wallet minted');
        require(_totalMinted() + quantity < maxTokens + 1, 'Max tokens minted');

        _safeMint(msg.sender, quantity);
    }

    function _isWhitelistApproved(
        address _address,
        bytes32[] calldata merkleProof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, _presaleMerkleRoot, leaf);
    }

    function _isPresaleMintable() private view returns (bool) {
        return
            _presaleActive &&
            !paused() &&
            !_publicSaleActive &&
            (_totalMinted() < _maxPresaleAmount);
    }

    function _isPublicSaleMintable() private view returns (bool) {
        return
            _publicSaleActive &&
            !paused() &&
            !_presaleActive &&
            (_totalMinted() < maxTokens);
    }

    function adminMint(uint256 quantity) external onlyOwner {
        _safeMint(admin, quantity);
    }

    function mintReservedTokens() external onlyOwner {
        _safeMint(admin, _reservedTokensAmount);
    }

    /** ------------------------
    Overrides
    ---------------------------- */

    function _baseURI() internal view override returns (string memory) {
        return _baseURIAddress;
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

    function releaseFunds(address account) public {
        release(payable(account));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_isRevealed) {
            return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), _metadataExtension));
        }

        return _baseURI();
    }

    /** -----------------------
    Getters
    --------------------------- */

    function getPresaleActive() external view returns (bool) {
        return _isPresaleMintable();
    }

    function getPublicSaleActive() external view returns (bool) {
        return _isPublicSaleMintable();
    }

    function getTotalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function getWhitelistApproved(
        address _address,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        return _isWhitelistApproved(_address, merkleProof);
    }

    function getMaxPerTxn() external view returns (uint256) {
        if (_isPresaleMintable()) {
            return maxQuantityForPresale;
        }
        return maxQuantityPerTxn;
    }

    /** ----------------------------
    Setters - Owner Only Accessible
    -------------------------------- */

    function setMaxQuantityPerTxn(uint96 amount) external onlyOwner {
        maxQuantityPerTxn = amount;
    }

    function setMaxQuantityForPresale(uint256 amount) external onlyOwner {
        maxQuantityForPresale = amount;
    }

    function setMaxPresaleAmount(uint256 amount) external onlyOwner {
        _maxPresaleAmount = amount;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function setReservedTokensAmount(uint256 amount) external onlyOwner {
        _reservedTokensAmount = amount;
    }

    function setBaseURI(string memory baseURIAddress, bool isRevealed)
        external
        onlyOwner
    {
        _baseURIAddress = baseURIAddress;
        _isRevealed = isRevealed;
    }

    function setMetadataExtension(string memory metadataExtension) external onlyOwner {
        _metadataExtension = metadataExtension;
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setPrice(uint256 amount) external onlyOwner {
        price = amount;
    }

    function setPresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _presaleMerkleRoot = merkleRoot;
    }

    function setMaxTokens(uint256 amount) external onlyOwner {
        maxTokens = amount;
    }

    function setRoyalty(address _address, uint96 royaltyFee)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_address, royaltyFee);
    }

    function togglePresaleActive() external onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        _publicSaleActive = !_publicSaleActive;
        if (_presaleActive) {
            _presaleActive = false;
        }
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}