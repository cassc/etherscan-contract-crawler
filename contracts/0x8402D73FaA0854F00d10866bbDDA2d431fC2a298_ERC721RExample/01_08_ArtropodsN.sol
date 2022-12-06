// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ERC721RExample is ERC721A, Ownable {
    using ECDSA for bytes32;
    
    uint256 public constant mintPrice = 0.022 ether; 
    uint256 public constant refundAmount = 0.0209 ether; // 95%
    uint256 public constant refundPeriod = 1 days;
    uint256 public maxMintSupply = 2662; 
    string public unrevealedUri;
    address public wlSigner;

    // Sale Status
    bool public publicSaleActive;
    bool public presaleActive;
    uint256 public refundEndTime;
    bool public isRevealed;
    address public refundAddress;
    uint256 public constant maxUserMintAmount = 3;

    mapping(uint256 => bool) public hasRefunded; // users can search if the NFT has been refunded

    string public baseURI;

    constructor(address _wlSigner) ERC721A("Artropods", "ARTP") {
        wlSigner = _wlSigner;
        refundAddress = msg.sender;
    }

    function verifyWlSignature(bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(signature) == wlSigner;
    }

    function setWlSigner(address _wlSigner) external onlyOwner {
         wlSigner = _wlSigner;
    }

    function ownerMint(address to, uint amount) external onlyOwner {
        _safeMint(to, amount);
    }

    function preSaleMint(uint amount, bytes memory sig) public payable {
        require(presaleActive, "Presale is not active");
        require(verifyWlSignature(sig), "You are not whitelisted");
        require(msg.value >= amount * mintPrice, "insufficient balance");
        require(
            _numberMinted(msg.sender) + amount <= maxUserMintAmount,
            "Your mint limit reached"
        );
        require(
            _totalMinted() + amount <= maxMintSupply,
            "Max mint supply reached"
        );
        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require(publicSaleActive, "Public sale is not active");
        require(msg.value >= amount * mintPrice, "insufficient balance");
        require(
            _numberMinted(msg.sender) + amount <= maxUserMintAmount,
            "Your mint limit reached"
        );
        require(
            _totalMinted() + amount <= maxMintSupply,
            "Max mint supply reached"
        );
        _safeMint(msg.sender, amount);
    }

    function refund(uint256[] calldata tokenIds) external {
        require(isRefundGuaranteeActive(), "Refund expired");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not token owner");
            require(!hasRefunded[tokenId], "Already refunded");
            hasRefunded[tokenId] = true;
            transferFrom(msg.sender, refundAddress, tokenId);
        }

        uint256 _refundAmount = tokenIds.length * refundAmount;
        Address.sendValue(payable(msg.sender), _refundAmount);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function getRefundGuaranteeEndTime() public view returns (uint256) {
        return refundEndTime;
    }

    function isRefundGuaranteeActive() public view returns (bool) {
        return (block.timestamp <= refundEndTime);
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        require(block.timestamp > refundEndTime, "Refund period not over");
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function numberMinted(address _address) external view returns (uint) {
        return _numberMinted(_address);
    } 

    function changeMaxSupply(uint _supply) external onlyOwner  {
        maxMintSupply = _supply;
    }

    function setRefundAddress(address _refundAddress) external onlyOwner {
        refundAddress = _refundAddress;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setUnrevealedUri(string memory uri) external onlyOwner { 
        unrevealedUri = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if  (isRevealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        } 
        return unrevealedUri;
    }

    function toggleRefundCountdown() public onlyOwner {
        refundEndTime = block.timestamp + refundPeriod;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }
}