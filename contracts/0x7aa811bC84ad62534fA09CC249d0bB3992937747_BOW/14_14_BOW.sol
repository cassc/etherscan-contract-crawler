// SPDX-License-Identifier: LGPL-3.0-or-later 

pragma solidity ^0.8.17;

/**
* BUSTY ORIGINAL WAIFUS
*/

import '@ERC721A/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@closedsea/OperatorFilterer.sol';

contract BOW is ERC721A, ERC2981, OperatorFilterer, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    error CallerIsContractError();
    error ContractPausedError();
    error AllowanceAmountError();
    error ExceedsMaxSupplyError();
    error MintClosedError();
    error IncorrectAmountError();
    error InvalidSignatureError();
    error BelowCurrentSupplyError();
    error CannotIncreaseSupplyError();

    bool public paused;
    bool public minting;
    bool public operatorFilteringEnabled;
    uint256 public cost = 0.69 ether;
    uint256 public maxSupply = 420;
    address public signer;
    string private _baseTokenURI = 'https://bow.moe/api/';
    string public provenance;

    constructor(address _signer) ERC721A("BOW", "B.O.W") {
        paused = true;
        signer = _signer;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 1000);
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContractError();
        _;
    }
    function flipPause() public onlyOwner {
        paused = !paused;
    }
    function flipMint() public onlyOwner {
        minting = !minting;
    }
    function setItemPrice(uint256 _price) public onlyOwner {
        cost = _price;
    }
    function setMaxSupply(uint256 _max) external onlyOwner {
        if (_max > maxSupply) revert CannotIncreaseSupplyError();
        if (_max < totalSupply()) revert BelowCurrentSupplyError();
        maxSupply = _max;
    }

    function issueBOW(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) revert ExceedsMaxSupplyError();

        _mint(to, quantity);
    }

    function mintBOW(uint256 _mintAmount, uint256 _allowance, bytes calldata _sig) public payable callerIsUser {
        uint64 _BOWClaimed = _getAux(msg.sender);
        if(paused) revert ContractPausedError();
        if(!minting) revert MintClosedError();
        if(_BOWClaimed + _mintAmount > _allowance) revert AllowanceAmountError();
        if(totalSupply() + _mintAmount > maxSupply) revert ExceedsMaxSupplyError();
        if(msg.value != cost * _mintAmount) revert IncorrectAmountError();
        address sig_recover = keccak256(abi.encodePacked(msg.sender, _allowance))
            .toEthSignedMessageHash()
            .recover(_sig);

        if(sig_recover != signer) revert InvalidSignatureError();

        _setAux(msg.sender,uint64(_BOWClaimed + _mintAmount));
        _mint(msg.sender, _mintAmount);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setProvenance(string memory hash) public onlyOwner {
        provenance = hash;
    }
    function withdrawETH() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }
    function registerForOperatorFiltering(address subscription, bool subscribe) external onlyOwner {
        _registerForOperatorFiltering(subscription, subscribe);
    }
    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setDefaultRoyalty(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}