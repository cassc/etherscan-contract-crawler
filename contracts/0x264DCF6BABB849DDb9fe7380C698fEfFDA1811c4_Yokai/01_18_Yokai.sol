// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./ERC721A.sol";

contract Yokai is ERC721A, Ownable, ReentrancyGuard {
    string private _baseURIextended = "https://yokailabs.net/metadata/";
    uint256 private MAX_SUPPLY = 4444;
    uint256 public immutable maxGoldenTicket = 100;
    uint256 public immutable maxGoldenTicketPerAmount = 1;
    uint256 public immutable maxPublicPerAmount = 2;
    uint256 public constant whitelistSalePrice = 0.033 ether;
    uint256 public constant publicSalePrice = 0.044 ether;
    uint256 public immutable maxTeamAmount = 200;
    bytes32 public goldenTicketMerkleRoot =
        0xd21478dda10a140d0f0bad99f4e4826230fa3d864712cdae342bd0122de14543;

    // set time
    uint256 public immutable goldenTicketStartTime = 1662213600; // 2022-09-03 22:00:00 GMT+8
    uint256 public immutable goldenTicketEndTime = 1662256800; // 2022-09-04 10:00:00 GMT+8
    uint256 public immutable whitelistStartTime = 1662213600; // 2022-09-03 22:00:00 GMT+8
    uint256 public immutable whitelistEndTime = 1662256800; // 2022-09-04 10:00:00 GMT+8
    uint256 public immutable publicSaleStartTime = 1662256800; // 2022-09-04 10:00:00 GMT+8
    uint256 public immutable publicSaleEndTime = 1762256800; // over

    mapping(address => uint256) public goldenTicketMinted;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    uint256 public goldenTicketMintedAmount;
    uint256 public whitelistMintedAmount;
    uint256 public teamMintedAmount;

    address public cSigner =
        address(0x23d5577bC398B5eDaA280cdE0536AdEbB4F18Ee9);

    uint256 public lastPublicSoldTime = 1662256800;

    constructor() ERC721A("Yokai Labs", "YOKAI") {}

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier canGoldenTicketMint(uint256 numberOfTokens) {
        uint256 ts = goldenTicketMintedAmount;
        require(
            ts + numberOfTokens <= maxGoldenTicket,
            "Purchase would exceed max golden ticket amount"
        );
        _;
    }

    modifier canTeamMint(uint256 numberOfTokens) {
        uint256 ts = teamMintedAmount;
        require(
            ts + numberOfTokens <= maxTeamAmount,
            "Purchase would exceed max team tokens"
        );
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <= getMaxSupply(),
            "Purchase would exceed max amount"
        );
        _;
    }

    modifier checkGoldenTicketTime() {
        require(
            block.timestamp >= goldenTicketStartTime &&
                block.timestamp <= goldenTicketEndTime,
            "Outside golden ticket round hours"
        );
        _;
    }
    modifier checkWhitelistTime() {
        require(
            block.timestamp >= whitelistStartTime &&
                block.timestamp <= whitelistEndTime,
            "Outside whitelist round hours"
        );
        _;
    }
    modifier checkPublicSaleTime() {
        require(
            block.timestamp >= publicSaleStartTime &&
                block.timestamp <= publicSaleEndTime,
            "Outside public sale hours"
        );
        _;
    }

    function adminMint(uint256 n) public onlyOwner canTeamMint(n) {
        _safeMint(msg.sender, n, "");
    }

    function mintWGoldenTicket(uint256 n, bytes32[] calldata merkleProof)
        public
        isValidMerkleProof(merkleProof, goldenTicketMerkleRoot)
        canGoldenTicketMint(n)
        canMint(n)
        checkGoldenTicketTime
        nonReentrant
    {
        require(
            goldenTicketMinted[msg.sender] + n <= maxGoldenTicketPerAmount,
            "NFT is already exceed max mint amount by this wallet"
        );
        _safeMint(msg.sender, n, "");
        goldenTicketMinted[msg.sender] += n;
        goldenTicketMintedAmount += n;
    }

    function mintWhitelist(
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 maxAmount,
        uint256 n
    )
        public
        payable
        isCorrectPayment(whitelistSalePrice, n)
        canMint(n)
        checkWhitelistTime
        nonReentrant
    {
        require(
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(abi.encode(maxAmount)),
                        keccak256(abi.encode(msg.sender)),
                        keccak256(abi.encode(999))
                    )
                ),
                v,
                r,
                s
            ) == cSigner,
            "Invalid signer"
        );
        require(
            whitelistMinted[msg.sender] + n <= maxAmount,
            "NFT is already exceed max mint amount by this wallet"
        );
        _safeMint(msg.sender, n, "");
        whitelistMinted[msg.sender] += n;
        whitelistMintedAmount += n;
    }

    function publicMint(uint256 n)
        public
        payable
        isCorrectPayment(publicSalePrice, n)
        canMint(n)
        checkPublicSaleTime
        nonReentrant
    {
        require(
            publicMinted[msg.sender] + n <= maxPublicPerAmount,
            "NFT is already exceed max mint amount by this wallet"
        );
        uint256 ms = getMaxSupply();
        if (MAX_SUPPLY != ms) {
            MAX_SUPPLY = ms;
        }
        _safeMint(msg.sender, n, "");
        publicMinted[msg.sender] += n;
        lastPublicSoldTime = block.timestamp;
    }

    function getMaxSupply() public view virtual returns (uint256) {
        uint256 ts = totalSupply();
        if (block.timestamp < publicSaleStartTime) {
            return MAX_SUPPLY;
        } else if ((block.timestamp > publicSaleEndTime)) {
            uint256 interval = publicSaleEndTime - lastPublicSoldTime;
            uint256 supply = MAX_SUPPLY - ((interval / 900) * 10);
            if (supply < ts) {
                return ts;
            } else {
                return supply;
            }
        } else {
            uint256 interval = block.timestamp - lastPublicSoldTime;
            uint256 supply = MAX_SUPPLY - ((interval / 900) * 10);
            if (supply < ts) {
                return ts;
            } else {
                return supply;
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function getMessageHash(uint256 maxAmount, address user)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encode(maxAmount)),
                    keccak256(abi.encode(user)),
                    keccak256(abi.encode(999))
                )
            );
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setGoldenTicketMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        goldenTicketMerkleRoot = merkleRoot;
    }

    function setSignerAddress(address newAddress) public onlyOwner {
        cSigner = newAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}