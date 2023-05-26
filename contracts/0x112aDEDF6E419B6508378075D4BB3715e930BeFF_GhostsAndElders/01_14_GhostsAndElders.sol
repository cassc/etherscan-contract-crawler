// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract GhostsAndElders is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    string public baseURI;
    uint256 public immutable collectionSize;
    bool public isMintingActive;
    address private _signer;

    error ContractNotAllowed();
    error InvalidToken();
    error AmountMustBeNonZero();
    error MaxSupplyExceeded();
    error MintingNotActive();
    error WithdrawalFailed();

    event BaseURIChanged(string newBaseURI);
    event Minted(address minter, uint256 amount);
    event SignerChanged(address signer);

    constructor(
        string memory initBaseURI,
        address signer,
        uint256 _collectionSize
    ) ERC721A('SPC: Ghosts And Elders', 'SGE') {
        _signer = signer;
        baseURI = initBaseURI;
        collectionSize = _collectionSize;
        isMintingActive = true;
    }

    modifier whenMintingActive() {
        if (!isMintingActive) revert MintingNotActive();
        _;
    }

    function _hash(
        string calldata salt,
        uint256 amount,
        address _address
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(salt, address(this), amount, _address));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (bool) {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function mint(
        uint256 amount,
        string calldata salt,
        bytes calldata token
    ) external payable whenMintingActive {
        if (tx.origin != msg.sender) revert ContractNotAllowed();
        if (!_verify(_hash(salt, amount, msg.sender), token)) revert InvalidToken();
        if (amount <= 0) revert AmountMustBeNonZero();
        if (totalSupply() + amount >= collectionSize) revert MaxSupplyExceeded();

        _safeMint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function toggleMinting() external onlyOwner {
        isMintingActive = !isMintingActive;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        if (!success) revert WithdrawalFailed();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}