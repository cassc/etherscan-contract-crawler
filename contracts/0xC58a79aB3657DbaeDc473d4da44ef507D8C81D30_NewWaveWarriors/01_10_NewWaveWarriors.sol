// SPDX-License-Identifier: None

pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NewWaveWarriors is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable
{
    string public baseURI = "ipfs://QmaHLkSdPCEqkiDAXxTNPQfYu83FjVFicgXi9mQPHYhM3L/?";

    uint256 public price = 0.008 ether;
    uint256 public maxPerTx = 6;
    uint256 public maxPerFree = 1;
    uint256 public maxSupply = 6666;

    bool public mintEnabled = false;
    bool public publicMintEnabled = false;

    bytes32 private _merkleRoot;

    mapping(address => uint256) public _mintedFreeAmount;

    constructor() ERC721A("New Wave Warriors", "NWW") {}

    function mint(uint256 count, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(mintEnabled, "Mint is not live yet");
        require(totalSupply() + count <= maxSupply, "No more");
        require(count <= maxPerTx, "Max per TX reached");

        if (!publicMintEnabled) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

            require(
                MerkleProof.verify(_merkleProof, _merkleRoot, leaf),
                "Address not in allowlist"
            );
        }

        uint256 cost = price;
        bool isFree = _mintedFreeAmount[msg.sender] < maxPerFree;

        if (isFree) {
            if (count >= (maxPerFree - _mintedFreeAmount[msg.sender])) {
                require(
                    msg.value >=
                        (count * cost) -
                            ((maxPerFree - _mintedFreeAmount[msg.sender]) *
                                cost),
                    "Please send the exact ETH amount"
                );
                _mintedFreeAmount[msg.sender] = maxPerFree;
            } else if (count < (maxPerFree - _mintedFreeAmount[msg.sender])) {
                require(msg.value >= 0, "Please send the exact ETH amount");
                _mintedFreeAmount[msg.sender] += count;
            }
        } else {
            require(
                msg.value >= count * cost,
                "Please send the exact ETH amount"
            );
        }

        _mint(msg.sender, count);
    }

    function batchTransfer(
        uint256[] calldata tokenIds,
        address[] calldata recipients
    ) external {
        require(tokenIds.length == recipients.length, "Invalid input");

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    function costCheck() public view returns (uint256) {
        return price;
    }

    function maxFreePerWallet() public view returns (uint256) {
        return maxPerFree;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    function setBaseUri(string memory baseuri_) public onlyOwner {
        baseURI = baseuri_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxPerFree(uint256 MaxPerFree_) external onlyOwner {
        maxPerFree = MaxPerFree_;
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function togglePublicMint() external onlyOwner {
        publicMintEnabled = !publicMintEnabled;
    }

    function giveawayReserves() external onlyOwner {
        require(totalSupply() == 0, "Giveaway reserves claimed");

        _mint(msg.sender, 50);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}