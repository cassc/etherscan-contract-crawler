// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GodMode is ERC721, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint16 private _maxSupply = 1000;
    uint256 private _mintPrice = 0.1 * 10**18;

    bytes32 private _publicMintRoot;
    bytes32 private _cantinaMintRoot;
    bytes32 private _waitlistRoot;
    mapping(address => bool) _minted;

    bool public waitListOpen = false;
    bool public mintOpen = false;

    string public _baseURL = "https://api.flipsidenfts.com/metadata/godmode/";

    constructor(
        bytes32 publicRoot,
        bytes32 cantinaRoot,
        bytes32 waitlistRoot
    ) ERC721("Flipside GODMODE", "GODMODE") {
        _publicMintRoot = publicRoot;
        _cantinaMintRoot = cantinaRoot;
        _waitlistRoot = waitlistRoot;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    // ----------------------------------------------------------------- NFT Functions

    function mint(bytes32[] calldata merkleProof) external payable {
        require(msg.value >= _mintPrice, "Not enough ETH sent; check price!");
        require(_minted[_msgSender()] == false, "Address already minted");
        require(isOnAllowList(merkleProof, _msgSender()), "Address not on Allowlist");
        require(mintOpen, "Minting is not open");

        _minted[_msgSender()] = true;

        _mint(_msgSender());
    }

    function mintCantina(bytes32[] calldata merkleProof) external {
        require(_minted[_msgSender()] == false, "Address already minted");
        require(isOnCantinaList(merkleProof, _msgSender()), "Address not on cantinalist");
        require(mintOpen, "Minting is not open");

        _minted[_msgSender()] = true;

        _mint(_msgSender());
    }

    function mintWaitList(bytes32[] calldata merkleProof) external payable {
        require(msg.value >= _mintPrice, "Not enough ETH sent; check price!");
        require(waitListOpen, "Waitlist is closed");
        require(_minted[_msgSender()] == false, "Address already minted");
        require(isOnWaitList(merkleProof, _msgSender()), "Address not on waitlist");
        require(mintOpen, "Minting is not open");

        _minted[_msgSender()] = true;

        _mint(_msgSender());
    }

    function _mint(address newOwner) private {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < _maxSupply, "Max supply reached");

        _tokenIdCounter.increment();

        _safeMint(newOwner, tokenId);
    }

    function contractURI() public view returns (string memory) {
        return _baseURI();
    }

    // ----------------------------------------------------------------- List Checks

    function isOnAllowList(bytes32[] calldata merkleProof, address sender) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(merkleProof, _publicMintRoot, leaf);
    }

    function isOnCantinaList(bytes32[] calldata merkleProof, address sender) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(merkleProof, _cantinaMintRoot, leaf);
    }

    function isOnWaitList(bytes32[] calldata merkleProof, address sender) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(merkleProof, _waitlistRoot, leaf);
    }

    // ----------------------------------------------------------------- Owner Functions

    function withdraw() public onlyOwner {
        payable(address(_msgSender())).transfer(address(this).balance);
    }

    function mintBatch(address[] calldata receivers) public onlyOwner {
        uint256 count = receivers.length;
        for (uint256 i = 0; i < count; i++) {
            _mint(receivers[i]);
        }
    }

    function updateBaseURI(string calldata newBaseURI) public onlyOwner {
        _baseURL = newBaseURI;
    }

    function openWaitList(bool open) public onlyOwner {
        waitListOpen = open;
    }

    function openMint(bool open) public onlyOwner {
        mintOpen = open;
    }

    // ----------------------------------------------------------------- Solidity Overrides

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