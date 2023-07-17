// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ERC721A.sol";

contract AACPass is ERC721A, Ownable {
    using Strings for uint8;
    using Strings for uint256;
    using ECDSA for bytes32;

    string private baseURI =
        "https://gateway.pinata.cloud/ipfs/QmaoL46KKtXtKgbog1fmyqkCaTJC2rbRcRdtgmKJE1wELE/";
    uint256 public constant maxSupply = 600;
    uint256 private minted = 0;
    uint256 public constant genesisSupply = 200;
    mapping(address => bool) genesisMintedAccounts;
    mapping(address => bool) alphaMintedAccounts;

    address[] public systemAddresses; // publicMint:0, whiteList:1, dutchAuction:2

    uint256 public mintPrice = 0.2 ether;

    bool public isPublicMintActive = false;
    bool public isWhiteListActive = false;

    //　Dutch auction
    uint256 public daStartTime = 1647779400;
    uint256 public daTimeStep = 300;
    uint256 public daStartPrice = 1 ether;
    uint256 public daEndPrice = 0.5 ether;
    uint256 public daPriceStep = 0.05 ether;

    // tokenId -> tokenType: 1 genesis, 2 alpha
    mapping(uint256 => uint8) private tokens;

    constructor() ERC721A("AAC Pass", "AAC Pass", 1, maxSupply) {}

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function publicMint(bytes calldata salt, bytes calldata signature)
        external
        payable
    {
        validSignature(salt, signature, 0);
        require(msg.sender == tx.origin, "We like real users");
        require(isPublicMintActive, "Public mint has not begun yet");
        require(!alphaMintedAccounts[msg.sender], "Address has minted");
        require(minted < maxSupply, "Exceeds max supply");
        require(msg.value >= mintPrice, "Not enough ETH sent");

        alphaMintedAccounts[msg.sender] = true;
        mint(msg.sender, 2);
    }

    function whiteListMint(bytes calldata salt, bytes calldata signature)
        external
        payable
    {
        validSignature(salt, signature, 1);
        require(msg.sender == tx.origin, "We like real users");
        require(isWhiteListActive, "White list mint has not begun yet");
        require(!alphaMintedAccounts[msg.sender], "Address has minted");        
        require(minted < maxSupply, "Exceeds max supply");
        require(msg.value >= mintPrice, "Not enough ETH sent");

        alphaMintedAccounts[msg.sender] = true;
        mint(msg.sender, 2);
    }

    function dutchAuctionMint(bytes calldata salt, bytes calldata signature)
        external
        payable
    {
        validSignature(salt, signature, 2);
        require(msg.sender == tx.origin, "We like real users");
        require(!genesisMintedAccounts[msg.sender], "Address has minted");
        require(block.timestamp >= daStartTime, "Auction not start");
        require(minted < genesisSupply, "Auction has ended");
        
        uint256 price = getDutchAuctionPrice();
        require(msg.value >= price, "Not enough ether sent");

        genesisMintedAccounts[msg.sender] = true;
        mint(msg.sender, 1);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function mint(
        address to,
        uint8 tokenType
    ) internal {
        uint256 tokenId = totalSupply();
        tokens[tokenId] = tokenType;
        minted++;
        _safeMint(to, 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint8 tokenType = tokens[tokenId];
        require(tokenType > 0, "URI query for nonexistent token");

        string memory name = tokenType.toString();
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "AAC Pass #',
                        tokenId.toString(),
                        '", "description": "AAC Genesis Pass/Alpha Pass is a membership NFT that grants you access to private community chat and announcements, exclusive Alpha-bot,Alpha Analysis, early access to partner NFT projects and more.", "image": "',
                        baseURI,
                        name,
                        ".mp4",
                        '","attributes":[{"trait_type":"type","value":"',
                        tokenType == 1 ? "Genesis" : "Alpha",
                        '"}]}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setIsPublicMintActive(bool bl) external onlyOwner {
        isPublicMintActive = bl;
    }

    function setIsWhiteListActive(bool bl) external onlyOwner {
        isWhiteListActive = bl;
    }

    function isMinitedGenesis(address addr) external view returns (bool) {
        return genesisMintedAccounts[addr];
    }

    function isMinitedAlpha(address addr) external view returns (bool) {
        return alphaMintedAccounts[addr];
    }

    function setDutchAuction(uint256 startTime) external onlyOwner {
        daStartTime = startTime;
    }

    function getDutchAuctionPrice() public view returns (uint256) {
        if (block.timestamp <= daStartTime) {
            return daStartPrice;
        }
        if ((daStartTime + 3000) < block.timestamp) {
            return daEndPrice;
        }
        uint256 step = (block.timestamp - daStartTime) / daTimeStep;
        return daStartPrice - step * daPriceStep;
    }

    function setSystemAddress(address[] calldata addresses) external onlyOwner {
        systemAddresses = addresses;
    }

    function validSignature(
        bytes calldata salt,
        bytes calldata signature,
        uint256 index
    ) internal view {
        require(systemAddresses[index] != address(0), "Invalid signature");
        require(
            keccak256(abi.encodePacked(msg.sender, salt)).recover(signature) ==
                systemAddresses[index],
            "Invalid signature"
        );
    }
}