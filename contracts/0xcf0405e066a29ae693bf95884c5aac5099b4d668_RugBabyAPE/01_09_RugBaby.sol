// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RugBabyAPE is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public publicPrice = 0.1 ether;
    uint256 public whitelistPrice = 0.08 ether;

    uint16 public maxSupply = 10000;
    uint16 public whitelistSupply = 4000;
    uint8 public publicMaxPerTxn = 5;
    uint8 public whitelistMaxPerWallet = 10;

    bool public isWhitelistSale;
    bool public isPublicSale;
    bool public isRevealed;

    bytes32 public whitelistMerkleRoot;
    mapping(address => uint8) public minted;

    string private unrevealedURI;
    string private baseURI;

    address[] public team;

    constructor(
        string memory unrev,
        string memory base
    ) ERC721A("RugBaby APE", "RBA") {
        unrevealedURI = unrev;
        baseURI = base;
    }

    function mint(uint16 quantity) external payable {
        require(isPublicSale, "The public sale has not started!");
        require(tx.origin == _msgSender(), "No contracts");
        require(totalSupply() + quantity <= maxSupply, "Excedes max supply.");
        require(quantity <= publicMaxPerTxn, "Exceeds max per transaction.");
        require(msg.value >= publicPrice * quantity, "Insufficient funds!");

        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(
        uint8 quantity,
        bytes32[] calldata merkleProof
    ) external payable {
        require(isWhitelistSale, "The whitelist sale has not started!");
        require(
            totalSupply() + quantity <= whitelistSupply,
            "Whitelist supply exceeded"
        );
        require(tx.origin == _msgSender(), "No contracts");
        require(
            minted[msg.sender] + quantity <= whitelistMaxPerWallet,
            "Exceeded per wallet limit"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require(msg.value >= whitelistPrice * quantity, "Insufficient funds!");
        minted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function airdrop(uint16 _mintAmount, address _receiver) external onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Excedes max supply."
        );
        _safeMint(_receiver, _mintAmount);
    }

    function cutSupply(uint16 _maxSupply) external onlyOwner {
        require(
            _maxSupply < maxSupply,
            "New max supply should be lower than current max supply"
        );
        require(
            _maxSupply > totalSupply(),
            "New max suppy should be higher than current number of minted tokens"
        );
        maxSupply = _maxSupply;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if (!isRevealed) return unrevealedURI;
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                )
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function flipWhitelistSale() external onlyOwner {
        isWhitelistSale = !isWhitelistSale;
    }

    function flipPublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
    }

    function flipRevealed() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function setWhitelistPrice(uint256 _price) external onlyOwner {
        whitelistPrice = _price;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setWhitelistMaxPerWallet(uint8 _limit) external onlyOwner {
        whitelistMaxPerWallet = _limit;
    }

    function setPublicMaxPerTxn(uint8 _limit) external onlyOwner {
        publicMaxPerTxn = _limit;
    }

    function setWhitelistMerkleRoot(bytes32 _root) external onlyOwner {
        whitelistMerkleRoot = _root;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTeam(address[] calldata addresses) external onlyOwner {
        team = addresses;
    }

    function withdraw() external onlyOwner {
        require(team.length > 0, "No wallets set");
        require(address(this).balance > 0, "Nothing to withdraw");
        uint256 share = address(this).balance / team.length;
        for (uint8 i = 0; i < team.length; i++) {
            (bool success, ) = payable(team[i]).call{value: share}("");
            require(success, "Withdraw failed");
        }
    }
}