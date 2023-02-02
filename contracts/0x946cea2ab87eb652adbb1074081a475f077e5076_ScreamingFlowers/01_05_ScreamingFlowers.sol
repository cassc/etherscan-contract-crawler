// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ScreamingFlowers is ERC721A {
    using ECDSA for bytes32;
    string public baseTokenURI;
    address public owner;
    uint256 constant MAX_SUPPLY = 3000;
    uint256 constant PUB_PRICE = 0.02 ether;
    uint256 constant ALLOW_PRICE = 0.01 ether;
    uint256 public PUB_SALE_TIME = 1675310400;
    address public signAddress;
    mapping(address => uint256) public minteds;

    enum AllowList {
        Builder,
        Ambassador,
        Supporter,
        Whitelist
    }

    constructor(string memory _baseTokenUri, address _signAddress)
        ERC721A("Screaming Flowers", "SF")
    {
        baseTokenURI = _baseTokenUri;
        signAddress = _signAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function mint(uint256 amount) external payable {
        require(block.timestamp >= PUB_SALE_TIME, "Not in sales time");
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out!");
        require(msg.value >= PUB_PRICE * amount, "Not paying enough fees");
        _mint(msg.sender, amount);
    }

    function wlMint(
        uint256 amount,
        AllowList allowList,
        bytes calldata signature
    ) external payable {
        require(
            keccak256(abi.encodePacked(msg.sender, amount, allowList))
                .toEthSignedMessageHash()
                .recover(signature) == signAddress,
            "You're not on the whitelist"
        );
        require(msg.value >= ALLOW_PRICE * amount, "Not paying enough fees");
        if (allowList == AllowList.Builder) {
            require(
                minteds[msg.sender] + amount <= 20,
                "Exceeded the quantity limit"
            );
        } else if (allowList == AllowList.Ambassador) {
            require(
                minteds[msg.sender] + amount <= 12,
                "Exceeded the quantity limit"
            );
        } else if (allowList == AllowList.Supporter) {
            require(
                minteds[msg.sender] + amount <= 6,
                "Exceeded the quantity limit"
            );
        } else if (allowList == AllowList.Whitelist) {
            require(
                minteds[msg.sender] + amount <= 2,
                "Exceeded the quantity limit"
            );
        } else {
            revert("Error type");
        }
        minteds[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    function gift(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out!");
        _mint(to, amount);
    }

    function setPublicSaleTime(uint256 _publicSaleTime) external onlyOwner {
        PUB_SALE_TIME = _publicSaleTime;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}