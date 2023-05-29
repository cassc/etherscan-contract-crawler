// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @custom:security-contact [email protected]
contract ShroomDK is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    bool public mintOpen = false;

    string public _baseURL = "https://api.flipsidenfts.com/metadata/shroomdk/";
    address internal _verifiedSigner;

    mapping(string => uint16) public mintCount; // this is formatUserName(username) to the user's mintcount
    mapping(string => uint16) public round; // this is raw username to the user's minting round

    uint256 public defaultMintPrice = 0;
    uint16 public defaultMaxMint = 3;

    constructor(address verifiedSigner) ERC721("Flipside ShroomDK", "Shroom") {
        _verifiedSigner = verifiedSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function contractURI() public view returns (string memory) {
        return _baseURI();
    }

    function mint(bytes calldata signature, string calldata username) external payable {
        require(msg.value >= defaultMintPrice, "Not enough ETH sent; check price!");
        require(mintOpen, "Minting is not open");
        require(mintCount[formatUserName(username)] < defaultMaxMint, "Cannot mint more any more with this account!");

        uint256 tokenId = _tokenIdCounter.current();
        require(verify(signature, username), "Signature is not valid, can only mint through flipside website!");

        _tokenIdCounter.increment();
        mintCount[formatUserName(username)] = mintCount[formatUserName(username)] + 1;

        _safeMint(_msgSender(), tokenId); // we mint to the sender
    }

    // ----------------------------------------------------------------- Verification

    /**
     * @dev Verifies the data hosted at the URI matches the signature
     */
    function verify(bytes memory signature, string calldata username) public view returns (bool) {
        bytes32 hashed = hashPayload(username);
        address signer = recoverSignerAddress(hashed, signature);

        return (signer == _verifiedSigner);
    }

    /**
     * @dev Hashes the data payload
     */
    function hashPayload(string calldata username) public pure returns (bytes32) {
        return keccak256(abi.encode(username)).toEthSignedMessageHash();
    }

    /**
     * @dev Verifies the data hosted at the URI matches the signature
     */
    function recoverSignerAddress(bytes32 data, bytes memory signedData) public pure returns (address) {
        return data.toEthSignedMessageHash().recover(signedData);
    }

    function formatUserName(string memory username) public view returns (string memory) {
        return string(abi.encodePacked(round[username], "-+-", username));
    }

    // ----------------------------------------------------------------- Owner Functions

    function setMintPrice(uint256 price) external onlyOwner {
        defaultMintPrice = price;
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseURL = newBaseURI;
    }

    function openMint(bool open) external onlyOwner {
        mintOpen = open;
    }

    function setVerifiedSigner(address signer) external onlyOwner {
        _verifiedSigner = signer;
    }

    function withdraw() external onlyOwner {
        payable(address(_msgSender())).transfer(address(this).balance);
    }

    function setMaxMint(uint16 newMax) external onlyOwner {
        defaultMaxMint = newMax;
    }

    function increaseRoundForUser(string memory user) public onlyOwner {
        round[user] = round[user] + 1;
    }

    // ----------------------------------------------------------------- Solidity

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}