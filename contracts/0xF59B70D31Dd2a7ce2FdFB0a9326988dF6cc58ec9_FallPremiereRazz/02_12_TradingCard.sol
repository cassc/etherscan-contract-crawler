// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./AccessToken.sol";
import "./Config.sol";
import "./EthUsdOracle.sol";

contract TradingCard is ERC721A, Ownable, ReentrancyGuard, Pausable {
    string private _name;
    string private _symbol;
    string private _metadataRoot;
    string private _contractMetadata;
    bool private _supplyLocked = false;

    Config private _config;

    mapping(bytes32 => bool) private _usedLeaves;

    address private _ethUsdOracle;
    address payable private _mintPayableAddress;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory metadataRoot_,
        string memory contractMetadata_
    ) ERC721A(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        _metadataRoot = metadataRoot_;
        _contractMetadata = contractMetadata_;
    }

    function updateTokenInfo(
        string memory name_,
        string memory symbol_,
        string memory metadataRoot_,
        string memory contractMetadata_
    ) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
        _metadataRoot = metadataRoot_;
        _contractMetadata = contractMetadata_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataRoot;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _metadataRoot = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadata;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractMetadata = uri;
    }

    function mintEnabled() public view returns (bool) {
        return _config.enabled;
    }

    function setMintPayableAddress(address payable addr) public onlyOwner {
        _mintPayableAddress = addr;
    }

    function walletLimit() public view returns (uint256) {
        return _config.walletLimit;
    }

    function pause(bool pause_) public onlyOwner {
        if (pause_) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setConfig(Config memory cfg) public onlyOwner {
        _config = cfg;
    }

    function config() public view returns (Config memory) {
        return _config;
    }

    function setEthUsdOracle(address addr) public onlyOwner {
        _ethUsdOracle = addr;
    }

    function lockSupply() public onlyOwner {
        _supplyLocked = true;
        _config.enabled = false;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address wallet) public view returns (uint256) {
        return _numberMinted(wallet);
    }

    function quote(uint64 quantity) public view returns (uint256) {
        if (_config.mintPriceUSD == 0) {
            return 0;
        }

        require(_ethUsdOracle != address(0), "Missing ETH/USD Oracle");
        EthUsdOracle oracle = EthUsdOracle(_ethUsdOracle);
        int256 spotPrice = oracle.latestAnswer();

        if (spotPrice <= 0) {
            revert("Spot price invalid");
        }

        uint256 num = uint256(quantity) *
            uint256(_config.mintPriceUSD) *
            1e6 *
            1 ether;
        uint256 denom = uint256(spotPrice);

        return uint256(num / denom) - (uint256(num / denom) % 1000 gwei);
    }

    function mint(uint64 quantity) public payable nonReentrant {
        require(!_supplyLocked, "Supply is locked");

        require(_config.enabled, "Minting not open");

        require(
            _config.startTime > 0 && _config.startTime <= block.timestamp,
            "Minting hasn't started"
        );

        if (
            _config.accessToken != address(0) &&
            _config.minAccessTokenBalance > 0
        ) {
            AccessToken accessToken = AccessToken(_config.accessToken);
            uint256 balance = accessToken.balanceOf(_msgSender());
            require(
                balance >= uint256(_config.minAccessTokenBalance),
                "Minimum access token threshold not reached"
            );
        }

        require(
            _config.walletLimit == 0 ||
                (_numberMinted(_msgSender()) + quantity) <=
                uint256(_config.walletLimit),
            "Mint limit reached"
        );

        uint256 needed = quote(quantity);
        require(msg.value >= needed, "Insufficient funds");

        require(
            _mintPayableAddress != address(0),
            "No payable destination set"
        );

        (bool sent, ) = _mintPayableAddress.call{value: msg.value}("");
        require(sent, "Failed to send ether");

        _safeMint(_msgSender(), quantity);
    }

    function freeMint(uint64 quantity, bytes32[] memory proof)
        public
        nonReentrant
    {
        require(!_supplyLocked, "Supply is locked");

        require(_config.enabled, "Minting not open");

        require(
            _config.startTime > 0 && _config.startTime <= block.timestamp,
            "Minting hasn't started"
        );

        require(
            MerkleProof.verify(
                proof,
                _config.merkleRoot,
                makeMerkleLeaf(_msgSender(), quantity)
            ),
            "Address/quantity combination not on allowlist"
        );

        require(
            _usedLeaves[makeMerkleLeaf(_msgSender(), quantity)] == false,
            "Proof already used"
        );

        require(_numberMinted(_msgSender()) == 0, "Already minted");

        markLeafUsed(makeMerkleLeaf(_msgSender(), quantity));

        _safeMint(_msgSender(), quantity);
    }

    function adminMint(address[] calldata owners, uint64[] calldata quantities)
        public
        nonReentrant
        onlyOwner
    {
        require(!_supplyLocked, "Supply is locked");

        require(owners.length == quantities.length, "Array mismatch");

        for (uint256 i = 0; i < owners.length; i++) {
            _safeMint(owners[i], quantities[i]);
        }
    }

    function makeMerkleLeaf(address wallet, uint64 quantity)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(wallet, quantity));
    }

    function markLeafUsed(bytes32 leaf) private {
        _usedLeaves[leaf] = true;
    }

    function leafUsed(bytes32 leaf) public view returns (bool) {
        return _usedLeaves[leaf];
    }

    function _beforeTokenTransfers(
        address,
        address,
        uint256,
        uint256
    ) internal view override {
        _requireNotPaused();
    }
}