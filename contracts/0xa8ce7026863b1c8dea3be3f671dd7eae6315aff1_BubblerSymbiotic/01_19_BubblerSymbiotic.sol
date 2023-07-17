// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BubblerSymbiotic is ContextMixin, NativeMetaTransaction, ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SYMBIOTIC = 555;
    uint256 public constant SYMBIOTIC_LIMIT = 10;

    uint256 public mintPrice = 0.111 ether;
    uint256 public reserve = 75;
    uint256 public reserveMinted = 0;

    address payable public treasury;

    string public baseURI;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant MINT_TYPEHASH = keccak256("SignedMint(address minter,uint256 num)");

    mapping(address => uint256) public signedMints;
    address proxyRegistryAddress;

    constructor(address payable _treasury, address _proxyRegistryAddress)
    ERC721("Bubbler Symbiotic", "BSYM") {
        setBaseURI("https://bubblerclub.web.app/");
        treasury = _treasury;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Bubbler Symbiotic")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712("Bubbler Symbiotic");
    }


    event TreasuryChanged(address newTreasury);

    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    function setReserve(uint256 _reserve) external onlyOwner {
        require(_reserve - reserveMinted + totalSupply() <= MAX_SYMBIOTIC, 'Exceeds MAX_SYMBIOTIC');

        reserve = _reserve;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        require(_price > 0, 'invalid price');

        mintPrice = _price;
    }

    function mint(uint256 num) external payable nonReentrant {
        uint256 supply = totalSupply();
        require(num <= SYMBIOTIC_LIMIT, 'Exceeds SYMBIOTIC_LIMIT');
        require(supply + num <= MAX_SYMBIOTIC - reserve, 'Exceeds MAX_SYMBIOTIC');
        require(treasury != address(0), "Treasury is not set");

        uint256 costToMint = mintPrice * num;
        require(costToMint <= msg.value, 'ETH amount is not sufficient');

        // Start index at 1
        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i + 1);
        }

        treasury.transfer(costToMint);

        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    function signedMint(uint256 num, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        uint256 supply = totalSupply();
        require(reserveMinted + num <= reserve, 'Exceeds reserve');

        // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(MINT_TYPEHASH, msg.sender, num)))
        );

        address signer = ecrecover(digest, v, r, s);
        require(signer == this.owner(), "signedMint: invalid signature");

        require(signedMints[msg.sender] != num, "signedMint: signature is already used");
        signedMints[msg.sender] = num;

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i + 1);
        }

        reserveMinted += num;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), "symbiotic.json"));
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://bubblerclub.web.app/";
    }

    function tokenURI(uint256 _tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId), ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}