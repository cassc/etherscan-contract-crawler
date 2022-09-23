// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

error ErrorSaleNotStarted();
error ErrorInvalidSignature();
error ErrorExceedWalletLimit();
error ErrorExceedMaxSupply();

contract Bacon is ERC2981, ERC721A, Ownable {
    using Address for address payable;
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 100;

    bool public _started;
    string public _metadataURI = "ipfs://bafybeihczix34x24ez7fpozcmp3flt36w4uae53tpfgskxrplbhksdypmy/";

    constructor() ERC721A(unicode"𝗯𝗮𝗰𝗼𝗻", "BACON") {
        _setDefaultRoyalty(owner(), 500);
    }

    modifier verifySignature(address sender, bytes memory signature) {
        bytes32 hash = keccak256(abi.encodePacked(sender));
        address signer = hash.toEthSignedMessageHash().recover(signature);
        if (signer != owner()) revert ErrorInvalidSignature();

        _;
    }

    function mint(bytes memory siganture) external payable verifySignature(msg.sender, siganture) {
        if (!_started) revert ErrorSaleNotStarted();
        if (_numberMinted(msg.sender) > 0) revert ErrorExceedWalletLimit();
        if (totalSupply() >= MAX_SUPPLY) revert ErrorExceedMaxSupply();

        _safeMint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || ERC721A(this).supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}