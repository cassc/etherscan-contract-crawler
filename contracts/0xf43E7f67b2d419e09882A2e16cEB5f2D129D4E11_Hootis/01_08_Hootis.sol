// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

error Hootis__TransferFailed();
error Hootis__SoldOut();
error Hootis__OutOfMaxPerWallet();
error Hootis__PublicMintStopped();
error Hootis__AllowlistMintStopped();
error Hootis__InvalidSigner();
error Hootis__WaitlistMintStopped();
error Hootis__IncorrectValue();
error Hootis__StageNotStartedYet(uint256 stage);
error Hootis__InvalidNewSupply();

contract Hootis is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    enum SaleStage {
        Stop, // 0
        Allowlist, // 1
        Waitlist, // 2
        SoldOut // 4
    }

    uint256 public maxSupply = 5000;
    uint256 public maxPerAddress = 2;
    uint256 public tokenPrice = 0.005 ether;

    address private signerAddressAllowlist;
    address private signerAddressWaitlist;

    SaleStage public saleStage = SaleStage.Stop;
    string private baseTokenUri;

    modifier mintCompliance(uint256 quantity) {
        if (totalSupply() + quantity > maxSupply) {
            revert Hootis__SoldOut();
        }
        if (numberMinted(msg.sender) + quantity > maxPerAddress) {
            revert Hootis__OutOfMaxPerWallet();
        }
        if (
            (quantity > 1 || numberMinted(msg.sender) > 0) &&
            (quantity * tokenPrice != msg.value)
        ) {
            revert Hootis__IncorrectValue();
        }

        _;
    }

    constructor(string memory defaultBaseUri) ERC721A('The Hootis', 'HOOTIS') {
        baseTokenUri = defaultBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json'))
                : '';
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mintAllowlist(uint256 quantity, bytes memory signature)
        external
        payable
        mintCompliance(quantity)
    {
        if (SaleStage.Allowlist != saleStage) {
            revert Hootis__StageNotStartedYet(uint256(saleStage));
        }
        if (
            !_verify(
                signerAddressAllowlist,
                keccak256(abi.encodePacked(msg.sender)),
                signature
            )
        ) {
            revert Hootis__InvalidSigner();
        }
        internalMint(quantity);
    }

    function mintWaitlist(uint256 quantity, bytes memory signature)
        external
        payable
        mintCompliance(quantity)
    {
        if (SaleStage.Waitlist != saleStage) {
            revert Hootis__StageNotStartedYet(uint256(saleStage));
        }
        if (
            !_verify(
                signerAddressWaitlist,
                keccak256(abi.encodePacked(msg.sender)),
                signature
            )
        ) {
            revert Hootis__InvalidSigner();
        }
        internalMint(quantity);
    }

    function mintDev(uint256 quantity) external onlyOwner {
        if (maxSupply <= totalSupply() + quantity) {
            revert Hootis__SoldOut();
        }
        _safeMint(msg.sender, quantity);
    }

    function internalMint(uint256 quantity) internal {
        _safeMint(msg.sender, quantity);
    }

    function withdrawTo(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}('');
        if (!success) {
            revert Hootis__TransferFailed();
        }
    }

    function _verify(
        address signer,
        bytes32 _hash,
        bytes memory signature
    ) internal pure returns (bool) {
        return _hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    function setSaleStage(uint256 newStage) external onlyOwner {
        saleStage = SaleStage(newStage);
    }

    function setMaxPerAddress(uint256 newMax) external onlyOwner {
        maxPerAddress = newMax;
    }

    function setAllowlistSigner(address signer) external onlyOwner {
        signerAddressAllowlist = signer;
    }

    function setWaitlistSigner(address signer) external onlyOwner {
        signerAddressWaitlist = signer;
    }

    function numberMinted(address claimer) public view returns (uint256) {
        return _numberMinted(claimer);
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseTokenUri = _baseUri;
    }

    function cutSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply >= maxSupply) {
            revert Hootis__InvalidNewSupply();
        }
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }
}