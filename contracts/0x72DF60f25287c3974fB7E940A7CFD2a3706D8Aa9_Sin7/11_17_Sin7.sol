// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Sin7 is ERC721A, ERC2981, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    using ECDSA for bytes32;

    error ContractPausedError();
    error CallerIsContractError();
    error AllowListMintClosedError();
    error WhitelistMintClosedError();
    error AllowanceAmountError();
    error ExceedsMaxSupplyError();
    error MintClosedError();
    error IncorrectAmountError();
    error MintAmountError();
    error InvalidSignatureError();
    error BelowCurrentSupplyError();

    bool public paused;
    bool public minting;
    bool public waitListMinting;
    bool public allowListMinting;
    uint256 public maxMintAmount = 1;
    uint256 public cost = 0.077 ether;
    uint256 public maxSupply = 7777;
    uint256 public mintPhase = 1;
    address public signer;
    bool public revealed = false;
    string public uriPrefix = '';
    string public uriSuffix;
    string public hiddenMetadataUri;

    constructor(
        address _signer,
        string memory _hiddenMetadataUri
    ) ERC721A("SIN7official", "SIN7") {
        signer = _signer;
        _setDefaultRoyalty(msg.sender, 700);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContractError();
        _;
    }

     function setPauseStatus() external onlyOwner {
        paused = !paused;
    }

    function setMintStatus() external onlyOwner {
        minting = !minting;
    }

    function setAllowlistMintStatus() external onlyOwner {
        allowListMinting = !allowListMinting;
    }

    function setWaitlistMintStatus() external onlyOwner {
        waitListMinting = !waitListMinting;
    }

    function setMintingPrice(uint256 _price) external onlyOwner {
        cost = _price;
    }

    function setMintAmount(uint256 _amount) external onlyOwner {
        maxMintAmount = _amount;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply < totalSupply()) revert BelowCurrentSupplyError();
        maxSupply = _maxSupply;
    }

    function setMintingPhase(uint256 _phase) external onlyOwner {
        mintPhase = _phase;
    }

    function reserveMint(address to, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > maxSupply)
            revert ExceedsMaxSupplyError();
        _mint(to, quantity);
    }
    
    function allowlistMint(
        bytes calldata _sig,
        uint256 _mintAmount
    ) external payable callerIsUser {
        if (paused) revert ContractPausedError();
        if (!allowListMinting) revert AllowListMintClosedError();
        if (_numberMinted(msg.sender) + _mintAmount > 2)
            revert AllowanceAmountError(); 
        if (_totalMinted() >= maxSupply) revert ExceedsMaxSupplyError();
        if (msg.value != cost * _mintAmount) revert IncorrectAmountError();
        address sig_recover = keccak256(
            abi.encodePacked(msg.sender, _mintAmount, uint256(1))
        ).toEthSignedMessageHash().recover(_sig);

        if (sig_recover != signer) revert InvalidSignatureError();
        _mint(msg.sender, _mintAmount);
    }

    function waitListMint( 
        bytes calldata _sig
    ) external payable callerIsUser {
        if (paused) revert ContractPausedError();
        if (!waitListMinting) revert WhitelistMintClosedError();
        if (_numberMinted(msg.sender) != 0)
            revert AllowanceAmountError();
        if (_totalMinted() > maxSupply)
            revert ExceedsMaxSupplyError();
        if (msg.value != cost) revert IncorrectAmountError();
        address sig_recover = keccak256(
            abi.encodePacked(msg.sender, uint256(1), uint256(2))
        ).toEthSignedMessageHash().recover(_sig);

        if (sig_recover != signer) revert InvalidSignatureError();
        _mint(msg.sender, 1);
    }

    function mint(uint256 _mintAmount) external payable callerIsUser {
        if (paused) revert ContractPausedError();
        if (!minting) revert MintClosedError();
        if (_mintAmount > maxMintAmount) revert MintAmountError();
        if (_numberMinted(msg.sender) >= maxMintAmount)
            revert AllowanceAmountError();
        if (_totalMinted() + _mintAmount > maxSupply)
            revert ExceedsMaxSupplyError();
        if (msg.value != cost * _mintAmount) revert IncorrectAmountError();
        _mint(msg.sender, _mintAmount);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view  override returns (string memory) {
        return uriPrefix;
    }

    function setRevealed(bool _state) external  onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public  onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) external  onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external  onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function tokenURI(uint256 _tokenId) public view  override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
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

    function setDefaultRoyalty(
        address payable receiver,
        uint96 numerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}