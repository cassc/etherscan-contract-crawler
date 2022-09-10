// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './MyraiCrystal.sol';
import "hardhat/console.sol";

contract MyraiKohoCollection is ERC721AQueryable, ERC2981, Ownable, Pausable, PaymentSplitter {
    string public contractURI;
    uint256 public maxTokens;
    uint256 public maxTokensForPhaseOne;
    address public myraiCrystalAddr;
    string public baseURIAddress;
    uint256 public price = 0.06 ether;
    uint256 public maxMintsPerWalletForPublic = 1;
    uint256 public maxMintsPerWalletForT1Presale = 1;
    uint256 public maxMintsPerWalletForT2Presale = 2; /* OG */
    uint256 public maxMintsPerWalletForT3Presale = 1;
    uint256 public reservedTokensAmount;
    bool public isRevealed;
    address[] public payees;
    uint256[] public shares;
    address public admin;

    bytes32 private _t1PresaleMerkleRoot;
    bytes32 private _t2PresaleMerkleRoot;
    bytes32 private _t3PresaleMerkleRoot;
    bool private _phaseOnePresaleActive;
    bool private _phaseTwoPresaleActive;
    bool private _publicSaleActive;
    uint256 private uuid = 1;

    event publicMintEvent(address addr, uint256 qty);
    event t1MintEvent(address addr, uint256 qty);
    event t2MintEvent(address addr, uint256 qty);
    event t3MintEvent(address addr);
    
    constructor(
        string memory _contractURI,
        string memory baseURI,
        address _myraiCrystalAddr,
        address[] memory _payees,
        uint256[] memory _shares,
        address _admin
    ) ERC721A('MyraiKohoCollection', 'KOHO') PaymentSplitter(_payees, _shares) {
        _setDefaultRoyalty(_admin, 500);
        contractURI = _contractURI;
        baseURIAddress = baseURI;
        myraiCrystalAddr = _myraiCrystalAddr;
        payees = _payees;
        shares = _shares;
        admin = _admin;
    }

    function setup(
        uint256 _maxTokens,
        uint256 _maxTokensForPhaseOne,
        uint256 _reservedTokensAmount,
        bytes32 t1PresaleMerkleRoot,
        bytes32 t2PresaleMerkleRoot,
        bytes32 t3PresaleMerkleRoot
    ) external onlyOwner {
        maxTokens = _maxTokens;
        maxTokensForPhaseOne = _maxTokensForPhaseOne;
        _t1PresaleMerkleRoot = t1PresaleMerkleRoot;
        _t2PresaleMerkleRoot = t2PresaleMerkleRoot;
        _t3PresaleMerkleRoot = t3PresaleMerkleRoot;
        reservedTokensAmount = _reservedTokensAmount;

    }

    /** ------------------------
    Minting
    ---------------------------- */

    function phaseOneMint(uint256 quantity, bytes32[] calldata merkleProof) external payable whenNotPaused {
        require(_isPhaseOnePresaleMintable(), 'sale not active');
        runCommonChecks(quantity);
        require (
            isPartOfT1Whitelist(msg.sender, merkleProof) || isPartOfT2Whitelist(msg.sender, merkleProof),
            "wallet not part of any wl"
        );
        
        if (isPartOfT1Whitelist(msg.sender, merkleProof))  {
            tieredPresaleMint(quantity, maxMintsPerWalletForT1Presale);
            emit t1MintEvent(msg.sender, quantity);
        } else if (isPartOfT2Whitelist(msg.sender, merkleProof)) {
            tieredPresaleMint(quantity, maxMintsPerWalletForT2Presale);
            emit t2MintEvent(msg.sender, quantity);
            /** TODO: require successful mint */

            /* mint myrai ticket */
            MyraiCrystal myraiCrystal = MyraiCrystal(myraiCrystalAddr);
            if (myraiCrystal.balanceOf(msg.sender) < 1) {
                myraiCrystal.mintFromKohoContract(1, msg.sender);    
            }
        }
    }

    function phaseTwoMint(bytes32[] calldata merkleProof) external payable whenNotPaused {
        uint256 quantity = 1;
        require(_isPhaseTwoPresaleMintable(), 'sale not active');
        runCommonChecks(quantity);
        require (
            isPartOfT3Whitelist(msg.sender, merkleProof),
            "wallet not part of any wl"
        );
        require(quantity < maxMintsPerWalletForT3Presale + 1, 'qty exceeds max per txn');
        require(msg.value == price * quantity, 'wrong value');
        uint256 mints = _numberMinted(msg.sender);
        require(mints + quantity < maxMintsPerWalletForT3Presale + 1, 'qty per wallet would be exceeded');
        _mintToken(quantity);
        emit t3MintEvent(msg.sender);
    }

    function publicMint(uint256 quantity) external payable whenNotPaused {
        require(_isPublicSaleMintable(), 'sale not active');
        require(msg.value == price * quantity, 'wrong value');
        runCommonChecks(quantity);
        uint256 mints = _numberMinted(msg.sender);
        require(mints + quantity < maxMintsPerWalletForPublic + 1, 'qty would exceed allowed limit');
        _mintToken(quantity);
        emit publicMintEvent(msg.sender, quantity);
    }

    function tieredPresaleMint(uint256 quantity, uint256 maxMintsPerWallet) internal whenNotPaused {
        require(quantity < maxMintsPerWallet + 1, 'qty exceeds max per txn');
        require(msg.value == price * quantity, 'wrong value');
        uint256 mints = _numberMinted(msg.sender);
        require(mints + quantity < maxMintsPerWallet + 1, 'qty per wallet would be exceeded');
        require(
            _totalMinted() + quantity < (maxTokensForPhaseOne + 1),
            'all presale tokens minted'
        );
        _mintToken(quantity);
    }

    function _mintToken(uint256 quantity) private {
        require(_totalMinted() + quantity < maxTokens + 1, 'max tokens minted');
        _safeMint(msg.sender, quantity);
    }

    function runCommonChecks(uint256 quantity) internal view {
        require(quantity > 0, 'zero');
        require(msg.sender == tx.origin, 'not contract mintable');
    }

    function isPartOfT1Whitelist(
        address _address,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, _t1PresaleMerkleRoot, leaf);
    }

    function isPartOfT2Whitelist(
        address _address,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, _t2PresaleMerkleRoot, leaf);
    }

    function isPartOfT3Whitelist(
        address _address,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, _t3PresaleMerkleRoot, leaf);
    }

    function _isPhaseOnePresaleMintable() private view returns (bool) {
        return
            _phaseOnePresaleActive &&
            !paused() &&
            !_publicSaleActive &&
            (_totalMinted() != maxTokensForPhaseOne);
    }

    function _isPhaseTwoPresaleMintable() private view returns (bool) {
        return
            _phaseTwoPresaleActive &&
            !paused() &&
            !_publicSaleActive &&
            (_totalMinted() != maxTokens);
    }

    function _isPublicSaleMintable() private view returns (bool) {
        return
            _publicSaleActive &&
            !paused() &&
            !_phaseOnePresaleActive &&
            (_totalMinted() != maxTokens);
    }

    function mintReservedTokens() external onlyOwner {
        _safeMint(admin, reservedTokensAmount);
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

    function releaseFunds(address account) public {
        release(payable(account));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isRevealed) {
            return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId + 1), '.json'));
        }

        
        return _baseURI();
    }

    function burnYourTokens(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i != tokenIds.length; ++i) {
            _burn(tokenIds[i], true);
        }
    }

    function adminMint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    /** -----------------------
    Getters
    --------------------------- */

    function getPhaseOnePresaleActive() external view returns (bool) {
        return _isPhaseOnePresaleMintable();
    }

    function getPhaseTwoPresaleActive() external view returns (bool) {
        return _isPhaseTwoPresaleMintable();
    }

    function getPublicSaleActive() external view returns (bool) {
        return _isPublicSaleMintable();
    }

    function getTotalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function _getTotalMinted() internal view returns (uint256) {
        return _totalMinted() - reservedTokensAmount;
    }

    function getT1PresaleMerkleRoot() external view onlyOwner returns (bytes32) {
        return _t1PresaleMerkleRoot;
    }
    
    function getT2PresaleMerkleRoot() external view onlyOwner returns (bytes32) {
        return _t2PresaleMerkleRoot;
    }    

    function getT3PresaleMerkleRoot() external view onlyOwner returns (bytes32) {
        return _t3PresaleMerkleRoot;
    }

    /** ----------------------------
    Setters - Owner Only Accessible
    -------------------------------- */

    function setReservedTokensAmount(uint256 _reservedTokensAmount) external onlyOwner {
        reservedTokensAmount = _reservedTokensAmount;
    }

    function setBaseURI(string memory _baseURIAddress) external onlyOwner {
        baseURIAddress = _baseURIAddress;
    }

    function setIsRevealed(bool revealed, string memory _baseURIAddress) external onlyOwner {
        isRevealed = revealed;
        baseURIAddress = _baseURIAddress;
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setPrice(uint256 amount) external onlyOwner {
        price = amount;
    }

    function setT1PresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _t1PresaleMerkleRoot = merkleRoot;
    }

    function setT2PresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _t2PresaleMerkleRoot = merkleRoot;
    }

    function setT3PresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _t3PresaleMerkleRoot = merkleRoot;
    }

    function setMaxTokens(uint256 amount) external onlyOwner {
        maxTokens = amount;
    }

    function setmaxTokensForPhaseOne(uint256 amount) external onlyOwner {
        maxTokensForPhaseOne = amount + reservedTokensAmount;
    }

    function setRoyalty(address _address, uint96 royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_address, royaltyFee);
    }

    function setMaxMintsPerWalletForPublic(uint256 amount) external onlyOwner {
        maxMintsPerWalletForPublic = amount;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function setMyraiCrystalAddr(address _myraiCrystalAddr) external onlyOwner {
        myraiCrystalAddr = _myraiCrystalAddr;
    }

    function setMaxMintsPerWalletForT1Presale(uint256 amount) external onlyOwner {
        maxMintsPerWalletForT1Presale = amount;
    }

    function setMaxMintsPerWalletForT2Presale(uint256 amount) external onlyOwner {
        maxMintsPerWalletForT2Presale = amount;
    }

    function setMaxMintsPerWalletForT3Presale(uint256 amount) external onlyOwner {
        maxMintsPerWalletForT3Presale = amount;
    }

    function togglePhaseOnePresaleActive() external onlyOwner {
        _phaseOnePresaleActive = !_phaseOnePresaleActive;
        if (_publicSaleActive) {
            _publicSaleActive = false;
        }        
        if (_phaseTwoPresaleActive) {
            _phaseTwoPresaleActive = false;
        }
    }

    function togglePhaseTwoPresaleActive() external onlyOwner {
        _phaseTwoPresaleActive = !_phaseTwoPresaleActive;
        if (_publicSaleActive) {
            _publicSaleActive = false;
        }        
        if (_phaseOnePresaleActive) {
            _phaseOnePresaleActive = false;
        }
    }

    function togglePublicSaleActive() external onlyOwner {
        _publicSaleActive = !_publicSaleActive;
        if (_phaseOnePresaleActive) {
            _phaseOnePresaleActive = false;
        }        
        if (_phaseTwoPresaleActive) {
            _phaseTwoPresaleActive = false;
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