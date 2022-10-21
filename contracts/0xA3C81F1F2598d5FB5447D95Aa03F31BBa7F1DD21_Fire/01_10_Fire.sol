// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Fire is ERC721 {
    using Strings for uint256;

    address public owner;
    bool public isSaleActive;
    string public baseTokenURI;

    uint256 public minted = 0;
    uint256 public genesisMinted = 0;

    uint256 public immutable LIMIT = type(uint256).max;
    uint256 public immutable genesisLimit;

    uint256 public limitPerWallet;

    mapping(address => uint8) public allowlist;

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    constructor(uint256 _genesisLimit, string memory _baseTokenURI)
        ERC721("Fire", "FIRE")
    {
        // default settings
        isSaleActive = false;
        limitPerWallet = 1;

        owner = msg.sender;
        genesisLimit = _genesisLimit;
        baseTokenURI = _baseTokenURI;
    }

    function setAllowlist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowlist[_addresses[i]] = 1;
        }
    }

    function mint() external {
        if (!isSaleActive) revert SaleNotActive();
        if (minted >= LIMIT) revert SoldOut();
        if (balanceOf(msg.sender) >= limitPerWallet)
            revert LimitPerWalletReached();

        uint256 toMint = genesisLimit + minted - genesisMinted;

        if (allowlist[msg.sender] > 0 && genesisMinted < genesisLimit) {
            // mint between 0 and genesisLimit - 1

            toMint = genesisMinted;
            genesisMinted += 1;
        }

        minted += 1;
        emit FireMinted(msg.sender, toMint);
        _safeMint(msg.sender, toMint);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setLimitPerWallet(uint256 _limitPerWallet) external onlyOwner {
        limitPerWallet = _limitPerWallet;
    }

    event FireMinted(address indexed minter, uint256 tokenId);
    error OnlyOwner();
    error SoldOut();
    error SaleNotActive();
    error LimitPerWalletReached();
}