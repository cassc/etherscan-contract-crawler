// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './erc721a/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./opensea/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

error CallerIsAnotherContract();
error NonexistentToken();
error PresaleIsActive();
error MintAmountOver();
error PresaleIsNotActive();
error InvalidMerkleProof();
error OverMintLimit();
error MintAmountCannotBeZero();
error MaxSupplyOver();
error NotEnoughFunds();
error CallerIsNotTeam();
error NowPaused();
error FailedWithdraw();
error BurnMintNotPaused();
error BurnMintMaxSupply();
error BurnMintCallerNotOwner();


contract KUMAGOROU is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, DefaultOperatorFiltererUpgradeable, ERC721AUpgradeable {  //ERC721AQueryableUpgradeable , ERC721ABurnableUpgradeable 
    using StringsUpgradeable for uint256;

    string private baseURI;
    string internal revealUri;
    uint256 public preCost;
    uint256 public publicCost;
    bool internal isRevealed;
    bool public isPause;
    uint64 public salePhase;
    uint64 private mintedCountPhase;
    uint64 public maxSupply;
    bytes32 private merkleRoot1;
    bytes32 private merkleRoot2;
    bytes32 private merkleRoot3;
    bytes32 private merkleRoot4;
    mapping(uint64 => mapping(address => uint256)) public mintedLists;
    mapping(address => bool) private teamMember;
    
    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Kumagorou And Kumarvel Generative", "KK");
        __Ownable_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        setMember(_msgSender(), true);
        baseURI = "";
        revealUri = "ar://NxovpIeTQjzTucXPOgjb2tRXRRnSJnoX3YkumjiIDno";
        preCost = 0.02 ether;
        publicCost = 0.1 ether;
        isRevealed = false;
        isPause = false;
        salePhase = 0;
        mintedCountPhase = 1;
        maxSupply = 1000;
    }

    modifier onlyTeam() {
        if(!teamMember[msg.sender]) revert CallerIsNotTeam();
        _;
    }
    event SetMember(address member, bool enable);
    function setMember(address member ,bool enable) public onlyOwner {
        teamMember[member] = enable;
        emit SetMember(member, enable);
    }

    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert CallerIsAnotherContract();
        _;
    }

    // internal override
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if(!_exists(_tokenId)) revert NonexistentToken();
        if(isRevealed == false) {
            return revealUri;
        }
        return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId), ".json"));
    }
    // start from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public mint
    function publicMint(uint256 _mintAmount) external payable callerIsUser nonReentrant {
        mintCheck(_mintAmount, publicCost * _mintAmount);
        if(!(salePhase == 5)) revert PresaleIsActive();
        if(_mintAmount > 10) revert MintAmountOver();
        _safeMint(msg.sender, _mintAmount);
    }

    // pre Mint
    function preMint(
        uint256 _mintAmount,
        uint256 _maxCount,
        bytes32[] calldata _proof
    ) external payable callerIsUser nonReentrant {
        mintCheck(_mintAmount,  getCurrentCost() * _mintAmount);
        if(!(salePhase >= 1 && salePhase <= 4)) revert PresaleIsNotActive();
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _maxCount));
        bytes32 _merkleRoot;
        if(salePhase == 1){
            _merkleRoot = merkleRoot1;
        }else if(salePhase == 2){
            _merkleRoot = merkleRoot2;
        }else if(salePhase == 3){
            _merkleRoot = merkleRoot3;
        }else if(salePhase == 4){
            _merkleRoot = merkleRoot4;
        }
        if(!MerkleProofUpgradeable.verify(_proof, _merkleRoot, _leaf)) revert InvalidMerkleProof();     
        if(mintedLists[mintedCountPhase][msg.sender] + _mintAmount > _maxCount) revert OverMintLimit();
        mintedLists[mintedCountPhase][msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 _cost
    ) private view {
        if(isPause) revert NowPaused();
        if(_mintAmount < 1) revert MintAmountCannotBeZero();
        if(totalSupply() + _mintAmount > maxSupply) revert MaxSupplyOver();
        if(msg.value < _cost) revert NotEnoughFunds();
    }

    function ownerMint(address _address, uint256 count) external onlyTeam {
       _safeMint(_address, count);
    }

    function setSalePhase(uint64 _phase) external onlyTeam {
        salePhase = _phase;
    }

    function setPreCost(uint256 _preCost) external onlyTeam {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) external onlyTeam {
        publicCost = _publicCost;
    }

    function getCurrentCost() public view returns (uint256) {
        if (salePhase == 1){
            return 0;
        } else if (salePhase == 2 || salePhase == 3 || salePhase == 4) {
            return preCost;
        } {
            return publicCost;
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyTeam {
        baseURI = _newBaseURI;
    }

    function setPause(bool _bool) external onlyTeam {
        isPause = _bool;
    }

    function withdraw() external onlyTeam {
        uint256 sendAmount = address(this).balance;
        bool success;
        (success, ) = payable(0x9A2c7b7B5E3cc2C2232341211f3F9F9D53b51D2E).call{value: (sendAmount * 500/1000)}("");
        if(!success) revert FailedWithdraw();
        (success, ) = payable(0x4679edB1Ca9CEfc30198e43c72b193329A03cD3C).call{value: (sendAmount * 500/1000)}("");
        if(!success) revert FailedWithdraw();
    }

    function setMerkleRoot(bytes32 _merkleRoot1, bytes32 _merkleRoot2, bytes32 _merkleRoot3, bytes32 _merkleRoot4) external onlyTeam {
        merkleRoot1 = _merkleRoot1;
        merkleRoot2 = _merkleRoot2;
        merkleRoot3 = _merkleRoot3;
        merkleRoot4 = _merkleRoot4;
    }

    function setMintedCountPhase() external onlyTeam {
        mintedCountPhase = mintedCountPhase + 1;
    }

    function getMintedCount(address _address) external view returns (uint256) {
        return mintedLists[mintedCountPhase][_address];
    }

    function setMaxSupply(uint64 _maxSupply) external onlyTeam {
        maxSupply = _maxSupply;
    }

    function setHiddenBaseURI(string memory _uri) external virtual onlyTeam {
        revealUri = _uri;
    }

    function setReveal(bool _bool) external virtual onlyTeam {
        isRevealed = _bool;
    }

    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    // ========================
    // Opensea library
    // ========================
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}