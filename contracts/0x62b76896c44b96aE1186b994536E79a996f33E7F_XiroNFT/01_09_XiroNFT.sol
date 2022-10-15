// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract XiroNFT is ERC721A, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 10000;
    uint256 public price = 0.1 ether;
    uint256 public maxQtyPerUser = 10;
    uint256 public tokenId = 0;
    string _baseUri;
    string _contractUri;
    string _preRevealURI;
    bool _isRevealed = false;
    mapping(address => uint256) public mintedByUser;
    bool public publicSale = false;
    address public treasury;
    address public whitelistingAddress;
    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");

    constructor(
        address _treasury,
        address _whitelistingAddress,
        string memory name,
        string memory version,
        string memory contractUri,
        string memory baseUri
    ) ERC721A("Xiro", "XIRO") {
        require(_treasury != address(0));
        require(_whitelistingAddress != address(0));
        _contractUri = contractUri;
        _baseUri = baseUri;
        treasury = _treasury;
        whitelistingAddress = _whitelistingAddress;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    event NftMinted(
        address indexed minter,
        uint256 indexed fromId,
        uint256 indexed toId
    );

    function reveal(bool _reveal) public onlyOwner {
        _isRevealed = _reveal;
    }

    function setPreRevealURI(string memory _uri) public onlyOwner {
        _preRevealURI = _uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token.");
        if (_isRevealed) {
            string memory baseURI = _baseURI();
            return
                bytes(baseURI).length != 0
                    ? string(
                        abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                    )
                    : "";
        }

        return _preRevealURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(uint256 _qty, bytes calldata _signature)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(
            msg.value >= price * _qty,
            "Ether sent is not sufficient(Public)."
        );

        require(checkWhitelist(_signature), "Invalid signature.");

        require(
            mintedByUser[msg.sender] + _qty <= maxQtyPerUser,
            "One wallet can mint max 10 NFTs."
        );
        require(
            totalSupply() + _qty <= maxSupply,
            "Quantity exceeds maxSupply."
        );
        uint256 from = _nextTokenId();
        mintedByUser[msg.sender] += _qty;
        _safeMint(msg.sender, _qty);
        emit NftMinted(msg.sender, from, from + _qty);
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function activatePublicSale() external onlyOwner {
        publicSale = true;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setMaxQtyPerUser(uint256 newMaxQtyPerUser) external onlyOwner {
        maxQtyPerUser = newMaxQtyPerUser;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0));
        treasury = _treasury;
    }

    function setWhitelistingAddress(address _whitelistingAddress)
        external
        onlyOwner
    {
        require(_whitelistingAddress != address(0));
        whitelistingAddress = _whitelistingAddress;
    }

    function withdrawAll() external onlyOwner {
        (bool success, ) = payable(treasury).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw unsuccessful!");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function checkWhitelist(bytes calldata signature)
        internal
        view
        returns (bool)
    {
        if (publicSale) {
            return true;
        }
        require(
            whitelistingAddress != address(0),
            "Treasury or Whitlist address not set."
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );
        address recoveredAddress = ECDSA.recover(digest, signature);
        return (recoveredAddress == whitelistingAddress);
    }
}