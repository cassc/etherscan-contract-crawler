// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "hardhat/console.sol";

/** TODO: all vars should setters */
contract MyraiCrystal is ERC721A, ERC2981, Ownable, Pausable {
    uint256 public maxQuantityPerTxn = 1;
    string public contractURI;
    uint256 public maxTokens;
    uint256 public maxMintsPerWallet = 1;
    bytes32 public merkleRoot;
    bool public saleActive;
    address public kohoContractAddress;
    string private _baseURIAddress;

    constructor(
        string memory _contractURI,
        uint256 _maxTokens,
        address _admin,
        bytes32 _merkleRoot,
        string memory baseURI
    ) ERC721A('MyraiCrystal', 'MYRAI_CRYSTAL') {
        _setDefaultRoyalty(_admin, 1000);
        contractURI = _contractURI;
        maxTokens = _maxTokens;
        _baseURIAddress = baseURI;
        merkleRoot = _merkleRoot;
    }

    /** ------------------------
    Minting
    ---------------------------- */

    function mintFromKohoContract(uint256 quantity, address addr) external {
        require(kohoContractAddress != address(0), 'No address for Koho contract');
        require(msg.sender == kohoContractAddress, 'Only mintable by Koho contract');
        uint256 mints = _numberMinted(addr);
        require(mints + quantity < maxMintsPerWallet + 1, 'Max quantity per wallet minted');
        require(
            _totalMinted() + quantity < maxTokens + 1,
            'Qty exceeds max available tokens'
        );
        _safeMint(addr, quantity);
    }

    function mint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        whenNotPaused
    {
        require(_isMintable(), 'Sale not active');
        require(msg.sender == tx.origin, 'NotContractMintable');
        require(quantity > 0, 'zero');
        require(isPartOfWhitelist(msg.sender, merkleProof), 'Not part of wl');
        uint256 mints = _numberMinted(msg.sender);
        require(mints + quantity < maxMintsPerWallet + 1, 'Max quantity per wallet minted');
        require(
            _totalMinted() + quantity < maxTokens + 1,
            'Qty exceeds max available tokens'
        );
        _safeMint(msg.sender, quantity);
    }

    function isPartOfWhitelist(
        address _address,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function _isMintable() private view returns (bool) {
        return
            saleActive &&
            !paused() &&
            (_totalMinted() != maxTokens);
    }

    function adminMint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
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


    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {        
        return _baseURI();
    }

    /** -----------------------
    Getters
    --------------------------- */

    function getSaleActive() external view returns (bool) {
        return _isMintable();
    }

    function getTotalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function getMaxTokens() internal view returns (uint256) {
        return maxTokens;
    }

    /** ----------------------------
    Setters - Owner Only Accessible
    -------------------------------- */

    function setBaseURI(string memory baseURIAddress) external onlyOwner {
        _baseURIAddress = baseURIAddress;
    }

    function setMaxQuantityPerTxn(uint256 _maxQuantityPerTxn) external onlyOwner {
        maxQuantityPerTxn = _maxQuantityPerTxn;
    }

    function setMaxTokens(uint256 _maxTokens) external onlyOwner {
        maxTokens = _maxTokens;
    }

    function setAdmin(string memory baseURIAddress) external onlyOwner {
        _baseURIAddress = baseURIAddress;
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setRoyalty(address _address, uint96 royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_address, royaltyFee);
    }

    function setMaxMintsPerWallet(uint256 amount) external onlyOwner {
        maxMintsPerWallet = amount;
    }

    function setKohoContractAddress(address addr) external onlyOwner {
        kohoContractAddress = addr;
    }

    /** ----------------------------
    Toggles - Owner Only Accessible
    -------------------------------- */

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}