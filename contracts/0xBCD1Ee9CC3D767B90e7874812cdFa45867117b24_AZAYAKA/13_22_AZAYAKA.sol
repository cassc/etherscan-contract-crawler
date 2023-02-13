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

contract AZAYAKA is 
    ERC721AUpgradeable,
    OwnableUpgradeable, 
    ERC2981Upgradeable, 
    ReentrancyGuardUpgradeable, 
    DefaultOperatorFiltererUpgradeable
{
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
    mapping(uint64 => mapping(address => uint256)) public mintedLists;
    mapping(address => bool) private teamMember;
    
    function initialize() public initializerERC721A initializer {
        __Ownable_init();
        __ERC2981_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        __ERC721A_init("AZAYAKA", "AZ");
        setMember(_msgSender(), true);
        baseURI = "";
        revealUri = "ar://lNAIB02gWVoIaLnYkSILqTQDIHQtx7QP1EpwcsHwXiY/hidden.json";
        preCost = 0.017 ether;
        publicCost = 0.02 ether;
        isRevealed = false;
        isPause = false;
        salePhase = 0;
        mintedCountPhase = 1;
        maxSupply = 1500;
        //_feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
        setRoyaltyInfo(0xF7b35e524A54D31D3432A6ddC8D45082595898B2, 1000);
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

    // internal override
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if(!_exists(_tokenId)) revert Errors.NonexistentToken();
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
        if (salePhase <= 2) {
            return preCost;
        } else {
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
        bool success;
        (success, ) = payable(0xf46B2B3006F7445Eb7dF2376695f5f8A88f5fA40).call{value: (address(this).balance)}("");
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

    function getStatus() external view returns(uint256 _cost, uint64 _phase, bool _isPause, uint256 _totalSupply) {
        _cost = getCurrentCost();
        _phase = salePhase;
        _isPause = isPause;
        _totalSupply = totalSupply();
        return(_cost, _phase, _isPause, _totalSupply);
    }

    /// @notice Function for changing royalty information
    /// @dev Can only be called by project owner
    /// @dev Owner can prevent any sale by setting the address to any address that can't receive native network token
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    function setRoyaltyInfo(address _royaltyReceiver, uint96 _feePercent)
        public
        onlyTeam
    {
        _setDefaultRoyalty(_royaltyReceiver, _feePercent);
    }

    /// @notice Returns true if this contract implements the interface defined by `interfaceId`
    /// @dev Needs to be overridden cause two base contracts implement it
    /// @param _interfaceId InterfaceId to consider. Comes from type(InterfaceContract).interfaceId
    /// @return bool True if the considered interface is supported
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