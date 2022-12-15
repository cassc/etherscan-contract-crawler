//  Website: https://www.crypnosis.world/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract KRIPCR is
    ERC721A,
    ERC2981,
    DefaultOperatorFilterer,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    uint256 immutable maxSupply = 299;
    uint256 immutable OGPrice = .020 ether;
    uint256 immutable publicMintPrice = .025 ether;
    uint256 public publicMints = 99;
    uint256 public teamMints = 45;
    uint256 public whiteListMints = 145;
    uint256 public presaleStartTime = 1671201060; // Dec 16th, 2022 @ 3:31AM EST
    uint256 public publicSaleStartTime = 1671958800; // Dec 25th, 2022 @ 3:31AM EST

    string public baseTokenUri;
    bytes32 public root;
    address creator = 0xF2844Dd7167AAeB5fe8F8beD7CFfa3c5F6476957;
    address dev = 0x6F9b44c7a86F8e01c85B76d4B6146E2b3f85d419;

    receive() external payable {}

    fallback() external payable {}

    constructor() ERC721A("Crypnosis Galaxy", "KRIP.CR") {
        setRoyaltyInfo(creator, 500); // 5%
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(
            block.timestamp > publicSaleStartTime,
            "Public minting not yet enabled"
        );
        require(
            publicMints + whiteListMints >= quantity,
            "Not enough mints available"
        );
        require(
            msg.value == quantity * publicMintPrice,
            "Not enought ether sent"
        );

        if (quantity > whiteListMints) {
            uint256 count = quantity - whiteListMints;
            whiteListMints = 0;
            publicMints -= count;
        } else {
            whiteListMints -= quantity;
        }

        _mint(msg.sender, quantity);
    }

    function airDropMint(uint256 _quantity) external onlyOwner {
        require(teamMints >= _quantity, "Not enough mints left");
        teamMints -= _quantity;
        _mint(msg.sender, _quantity);
    }

    function whiteListMint(
        bytes32[] memory _proof,
        uint256 _amount
    ) external payable nonReentrant {
        require(block.timestamp > presaleStartTime, "Minting not yet enabled");
        require(_amount <= whiteListMints, "No more whitelist mints available");
        require(msg.value == OGPrice * _amount, "Not enough ether sent");
        bytes32 _sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, root, _sender),
            "Caller Not Whitelisted"
        );
        whiteListMints -= _amount;
        _mint(msg.sender, _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 realId = tokenId + 1;

        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, realId.toString(), ".json")
                )
                : "ipfs://bafkreihisz76ly4xk3p2unknqbuh5kyraqggoatsmfqrmj64spnbfaf4dm";
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");
        uint256 balance = address(this).balance;
        uint256 creatorFee = (balance * 90) / 100; // 90%
        uint256 devFee = (balance * 10) / 100; //10%
        (bool success, ) = payable(creator).call{value: creatorFee}("");
        (bool successs, ) = payable(dev).call{value: devFee}("");
        require(success && successs);
    }

    function setPresaleStartTime(uint256 _time) external onlyOwner {
        presaleStartTime = _time;
    }

    function setPublicStartTime(uint256 _time) external onlyOwner {
        publicSaleStartTime = _time;
    }

    function updateBaseUri(string memory _newURI) external onlyOwner {
        baseTokenUri = _newURI;
    }

    function updateRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function retrieveStatus() external view returns (uint8) {
        uint8 status;
        if (block.timestamp < presaleStartTime) {
            status = 0;
        } else if (
            block.timestamp > presaleStartTime &&
            block.timestamp < publicSaleStartTime
        ) {
            status = 1;
        } else {
            status = 2;
        }
        return status;
    }
}