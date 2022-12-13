// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AiProfilePicture is ERC721, ERC721Enumerable, Ownable {
    string private _baseTokenURI;
    bytes32 private _merkleRoot;
    mapping(bytes32 => bool) private _claimedMintKeys;
    bool public isPublicMintActive = false;

    uint256 public constant PRESALE_MINT_PRICE = 0.01 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.05 ether;

    uint256 public immutable maxSupply;

    constructor(uint256 maxSupply_) ERC721("AiProfilePicture", "AIPFP") {
        maxSupply = maxSupply_;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    function setPublicMintState(bool isActive) external onlyOwner {
        isPublicMintActive = isActive;
    }

    function devMint(address to) external onlyOwner {
        uint256 ts = totalSupply();

        require(ts + 1 <= maxSupply, "Purchase would exceed max tokens");

        _safeMint(to, ts);
    }

    function whitelistMint(bytes16 key, bytes32[] calldata proof)
        public
        payable
    {
        uint256 ts = totalSupply();

        require(ts + 1 <= maxSupply, "Purchase would exceed max tokens");
        require(
            PRESALE_MINT_PRICE <= msg.value,
            "Ether value sent is incorrect"
        );
        require(!_claimedMintKeys[key], "Key has already been used");
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(key))
            ),
            "Invalid key"
        );

        _claimedMintKeys[key] = true;
        _safeMint(msg.sender, ts);
    }

    function mint() public payable {
        uint256 ts = totalSupply();

        require(isPublicMintActive, "Public minting is unavailable");
        require(ts + 1 <= maxSupply, "Purchase would exceed max tokens");
        require(
            PUBLIC_MINT_PRICE <= msg.value,
            "Ether value sent is incorrect"
        );

        _safeMint(msg.sender, ts);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}