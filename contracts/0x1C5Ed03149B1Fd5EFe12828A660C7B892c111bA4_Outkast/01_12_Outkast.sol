// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Outkast is Ownable, ERC721 {
    using ECDSA for bytes32;

    uint256 constant public MAX_OUTKASTS = 10000;
    uint256 constant public OUTKAST_PRICE = 0.05 ether;
    uint256 constant public MAX_OUTKASTS_PER_TXNS = 3;

    mapping(bytes32 => bool) public usedHashes;
   
    /*
    // Metadata will start on AWS and once enough Outkasts have upgraded will be moved to IPFS in order to stay frozen
    // The Metadata generator will be given out once all outkasts have been revealed
    // The contract address will be used as the seed for the randomness so everyone can verify its integrity
    */
    string private _outkastBaseURI = "https://outkasts.s3.us-east-2.amazonaws.com/";
    address private _signatureVerifier = 0x82629De19B3e450b5CDC9a0E5E8Fab638DBFef9d;

    uint256 public totalSupply = 0;
    bool public isSaleActive = false;
    bool public isURIFrozen = false;
    bool public saleHasConcluded = false;

    /*
    // Initalize the Outkast token
    // Reserve 30 Outkast for special, charity, and sponsoring events (not randomly generated)
    // Reserve 30 more randomly generated Outkast's for giveaways (randomly generated like the rest)
    */
    constructor() ERC721("Outkast", "OK") {
        for (uint256 i = 0; i < 60; i++) {
            _safeMint(msg.sender, ++totalSupply);
        }
    }

    /*
    // Rehash the message to verify all the information is valid
    */
    function hashMessage(address sender, uint256 tokenQuantity, uint256 nonce) internal pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, tokenQuantity, nonce))));
        return hash;
    }

    /*
    // Presale is handled internally using the hash system, so no need for 2 seperate functions
    */
    function mintOutkast(uint256 tokenQuantity, bytes calldata signature, uint256 nonce) external payable {
        require(isSaleActive, "Sale Inactive");
        require(totalSupply + tokenQuantity <= MAX_OUTKASTS, "Sold Out");
        require(tokenQuantity <= MAX_OUTKASTS_PER_TXNS, "Mint Overflow");
        require(OUTKAST_PRICE * tokenQuantity <= msg.value, "Insufficient Funds");

        bytes32 messageHash = hashMessage(msg.sender, tokenQuantity, nonce);
        require(messageHash.recover(signature) == _signatureVerifier, "Unrecognizable Hash");
        require(!usedHashes[messageHash], "Reused Hash");

        usedHashes[messageHash] = true;

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, ++totalSupply);
        }

        if(totalSupply == MAX_OUTKASTS) {
            saleHasConcluded = true;
        }
    }

    /*
    // To be used during staking for upgradable Outkasts
    */ 
    function burnOutkast(uint256 tokenId) external {
        require(saleHasConcluded, "Ongoing Sale");
        require(_exists(tokenId), "Inexistant Token");
        require(msg.sender == ownerOf(tokenId), "Not Owner");
        totalSupply -= 1;
        _burn(tokenId);
    } 

    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function freezeURI() external onlyOwner {
        isURIFrozen = true;
    }

    /*
    // In the unlikely scenario that someone discovers it's secret key and begins mass minting
    */
    function setSignatureVerifier(address newVerifier) external onlyOwner {
        _signatureVerifier = newVerifier;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        require(!isURIFrozen, "URI is Frozen");
        _outkastBaseURI = newURI;
    }

    function withdrawAll(address treasury) external payable onlyOwner {
        require(payable(treasury).send(address(this).balance));
    }

    function _baseURI() internal view override returns (string memory) {
        return _outkastBaseURI;
    }
}