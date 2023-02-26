// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./opensea/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {Errors} from "./libraries/Errors.sol";

abstract contract GBIF {
    function getCurrentSet() public view virtual returns (string memory);
}

contract PROJECT_HOP is 
    ERC721AUpgradeable,
    OwnableUpgradeable, 
    ERC2981Upgradeable, 
    ReentrancyGuardUpgradeable, 
    DefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;
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
    mapping(uint64 => mapping(address => uint256)) public mintedLists;
    mapping(address => bool) private teamMember;
    GBIF GBIFContract;
    
    function initialize() public initializerERC721A initializer {
        __Ownable_init();
        __ERC2981_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        __ERC721A_init("666PROJECT HOP", "MAKER6");
        setMember(_msgSender(), true);

        revealUri = "ar://aHOmUPg3UlCqiWqlM4UYF2Ci6_amVVeHg-I1p7VUwlQ";
        preCost = 0.033 ether;
        publicCost = 0.04 ether;
        isRevealed = false;
        isPause = false;
        salePhase = 0;
        mintedCountPhase = 1;
        maxSupply = 666;
        setRoyaltyInfo(0x6abb96ff62603B0646624f2CB517476194263fc8, 1000);
    }

    modifier onlyTeam() {
        if(!teamMember[msg.sender]) revert Errors.CallerIsNotTeam();
        _;
    }
    event SetMember(address member, bool enable);
    function setMember(address member ,bool enable) public onlyOwner {
        teamMember[member] = enable;
        emit SetMember(member, enable);
    }
    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert Errors.CallerIsAnotherContract();
        _;
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if(!_exists(_tokenId)) revert Errors.NonexistentToken();
        if(isRevealed == false) {
            return revealUri;
        }
        return string(abi.encodePacked(GBIFContract.getCurrentSet(), StringsUpgradeable.toString(_tokenId), ".json"));
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public mint
    function publicMint(uint256 _mintAmount) external payable callerIsUser nonReentrant {
        mintCheck(_mintAmount, publicCost * _mintAmount);
        if(!(salePhase == 5)) revert Errors.PresaleIsActive();
        if(_mintAmount > 10) revert Errors.MintAmountOver();
        _safeMint(msg.sender, _mintAmount);
    }

    // pre Mint
    function preMint(
        uint256 _mintAmount,
        uint256 _maxCount,
        bytes32[] calldata _proof
    ) external payable callerIsUser nonReentrant {
        mintCheck(_mintAmount,  getCurrentCost() * _mintAmount);
        if(!(salePhase >= 1 && salePhase <= 2)) revert Errors.PresaleIsNotActive();
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _maxCount));
        bytes32 _merkleRoot;
        if(salePhase == 1){
            _merkleRoot = merkleRoot1;
        }else if(salePhase == 2){
            _merkleRoot = merkleRoot2;
        }
        if(!MerkleProofUpgradeable.verify(_proof, _merkleRoot, _leaf)) revert Errors.InvalidMerkleProof();     
        if(mintedLists[mintedCountPhase][msg.sender] + _mintAmount > _maxCount) revert Errors.OverMintLimit();
        mintedLists[mintedCountPhase][msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 _cost
    ) private view {
        if(isPause) revert Errors.NowPaused();
        if(_mintAmount < 1) revert Errors.MintAmountCannotBeZero();
        if(totalSupply() + _mintAmount > maxSupply) revert Errors.MaxSupplyOver();
        if(msg.value < _cost) revert Errors.NotEnoughFunds();
    }

    function ownerMint(address _address, uint256 count) external onlyTeam {
       _safeMint(_address, count);
    }

    function setSalePhase(uint64 _phase) external onlyTeam {
        if(_phase == 2){
            setMintedCountPhase();
        }
        salePhase = _phase;
    }

    function setPreCost(uint256 _preCost) external onlyTeam {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) external onlyTeam {
        publicCost = _publicCost;
    }

    function getCurrentCost() public view returns (uint256) {
        if (salePhase >= 1 && salePhase <= 2) {
            return preCost;
        } else {
            return publicCost;
        }
    }

    function setGBIFAddress(address _address) external onlyTeam {
        GBIFContract = GBIF(_address);
    }

    function setPause(bool _bool) external onlyTeam {
        isPause = _bool;
    }

    function withdraw() external onlyTeam {
        bool success;
        (success, ) = payable(0x6abb96ff62603B0646624f2CB517476194263fc8).call{value: (address(this).balance)}("");
        if(!success) revert Errors.FailedWithdraw();
    }

    function setMerkleRoot(bytes32 _merkleRoot1, bytes32 _merkleRoot2) external onlyTeam {
        merkleRoot1 = _merkleRoot1;
        merkleRoot2 = _merkleRoot2;
    }

    function setMintedCountPhase() public onlyTeam {
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

    function burn(uint256[] memory _burnTokenIds) external virtual {
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            if (_msgSender() != ownerOf(tokenId)) revert Errors.BurnCallerNotOwner();
            _burn(tokenId);
        }
    }

    function setRoyaltyInfo(address _royaltyReceiver, uint96 _feePercent)
        public
        onlyTeam
    {
        _setDefaultRoyalty(_royaltyReceiver, _feePercent);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(_interfaceId) ||
            ERC2981Upgradeable.supportsInterface(_interfaceId) ||
            super.supportsInterface(_interfaceId);
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