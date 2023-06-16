// SPDX-License-Identifier: Unlicense

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma solidity ^0.8.4;

contract PartyHorsesPregame is ERC721A, Ownable {
    using ECDSA for bytes32;

    address public signingAddress;

    string public BASE_URI;
    
    uint public constant MAX_MINT = 1;
    uint public constant MAX_SUPPLY = 2000;

    bool public publicSaleActive = false;
    bool public privateSaleActive = false;

    constructor() ERC721A("Party Horses Pregame", "PREGAME") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function togglePrivateSaleActive() external onlyOwner {
        privateSaleActive = !privateSaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        BASE_URI = uri;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function numberMinted(address owner) public view returns (uint) {
        return _numberMinted(owner);
    }

    function privateMint(bytes calldata _allowlistSignature) external payable {
        require(verifySignature(keccak256(abi.encode(msg.sender)), _allowlistSignature), "signature not valid");
        require(privateSaleActive, "Private sale not currently active");
        require(totalSupply() < MAX_SUPPLY, "No supply left.");
        require(
            numberMinted(msg.sender) < MAX_MINT,
            "One mint per wallet."
        );

        _safeMint(msg.sender, MAX_MINT);
    }

    function mint() external payable {
        require(publicSaleActive, "Public sale not currently active");
        require(totalSupply() < MAX_SUPPLY, "No supply left.");
        require(
            numberMinted(msg.sender) < MAX_MINT,
            "One mint per wallet."
        );

        _safeMint(msg.sender, MAX_MINT);
    }

    function adminMint(uint256 count) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY);
        _safeMint(msg.sender, count);
    }

    function verifySignature(bytes32 hash, bytes memory signature) private view returns(bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signingAddress;
    }

    function setSigningAddress(address _addr) external onlyOwner {
        signingAddress = _addr;
    }
}