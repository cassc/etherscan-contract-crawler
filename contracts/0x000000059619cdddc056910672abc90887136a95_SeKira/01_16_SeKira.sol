// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract SeKira is ERC721A, EIP712, IERC2981, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 private constant PRICE_MULTIPLIER = 0.0001 ether;
    uint256 private constant FEE_DENOMINATOR = 10000;
    bytes32 private constant PRESALE_HASH = keccak256("presaleMint(address receiver)");
    bytes32 private constant RAFFLE_SALE_HASH = keccak256("raffleMint(address receiver)");
    string private constant SIGN_PREFIX = "\x19Ethereum Signed Message:\n32";

    uint8 public constant PRESALE_RAFFLE_MAX_MINT = 2;
    uint8 public constant RAFFLE_SALE_MAX_MINT = 2;
    uint8 public constant PUBLIC_SALE_MAX_MINT = 3;

    struct Config {
        // Immutable config
        uint16 maxSupply;
        uint16 devReservedSupply;
        // Mutable config
        uint16 presalePrice;
        uint16 raffleSalePrice;
        uint16 publicSalePrice;
        uint16 royaltyRate;
        // Mutable state
        uint16 devMinted;
        bool isPresaleActive;
        bool isRaffleSaleActive;
        bool isPublicSaleActive;
    }

    Config public _config;
    string public _uriPrefix;

    constructor(Config memory config, string memory uriPrefix) ERC721A("SeKira", "SKRA") EIP712("SeKira", "1") {
        require(
            config.maxSupply >= config.devReservedSupply,
            "SeKira: maxSupply must not be smaller then supply reserved for devs"
        );

        require(config.royaltyRate <= FEE_DENOMINATOR, "SeKira: invalid royalty fee rate");
        config.devMinted = 0;

        _config = config;
        _uriPrefix = uriPrefix;
    }

    modifier verifySig(
        bytes32 mintMethodHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) {
        bytes32 funcCallDigest = keccak256(abi.encode(mintMethodHash, msg.sender));
        bytes32 typedDataDigest = _domainSeparatorV4().toTypedDataHash(funcCallDigest);
        bytes32 digest = keccak256(abi.encodePacked(SIGN_PREFIX, typedDataDigest));

        require(ecrecover(digest, v, r, s) == address(owner()), "SeKira: invalid signature");
        _;
    }

    modifier botDefender() {
        require(tx.origin == msg.sender, "SeKira: bots, get out");
        _;
    }

    function ensureSupply(Config memory config, uint8 mintAmount) internal view {
        uint256 publicSupply = uint256(config.maxSupply - config.devReservedSupply);
        require(_currentIndex + mintAmount <= publicSupply, "SeKira: exceed max supply");
    }

    function ensureSufficientValue(uint16 unitPrice, uint8 mintAmount) internal view {
        require(uint256(unitPrice) * PRICE_MULTIPLIER * mintAmount == msg.value, "SeKira: incorrect value");
    }

    function sekiraPresaleMint(
        uint8 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable botDefender verifySig(PRESALE_HASH, r, s, v) {
        Config memory config = _config;
        require(config.isPresaleActive, "SeKira: presale is not started");

        ensureSupply(config, amount);
        ensureSufficientValue(config.presalePrice, amount);
        require(incrementPresaleMinted(amount) <= PRESALE_RAFFLE_MAX_MINT, "SeKira: exceed presale mint limit");

        _safeMint(msg.sender, amount);
    }

    function sekiraRaffleSaleMint(
        uint8 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable botDefender verifySig(RAFFLE_SALE_HASH, r, s, v) {
        Config memory config = _config;
        require(config.isRaffleSaleActive, "SeKira: raffle sale mint is not started");

        ensureSupply(config, amount);
        ensureSufficientValue(config.raffleSalePrice, amount);
        require(incrementRaffleMinted(amount) <= RAFFLE_SALE_MAX_MINT, "SeKira: exceed raffle sale mint limit");

        _safeMint(msg.sender, amount);
    }

    function sekiraPublicMint(uint8 amount) external payable botDefender {
        Config memory config = _config;
        require(config.isPublicSaleActive, "SeKira: public sale is not started");

        ensureSupply(config, amount);
        ensureSufficientValue(config.publicSalePrice, amount);
        require(incrementPublicMinted(amount) <= PUBLIC_SALE_MAX_MINT, "SeKira: exceed public sale mint limit");

        _safeMint(msg.sender, amount);
    }

    // ::
    // :: Aux operation
    // ::
    // :: Memory layout (64-bits space):
    // ::     | High bits...| PresaleMinted(8bit) | RaffleMinted(8bit) | PublicMinted(8bit) |
    // ::

    function _aux(address minter) public view returns (uint64) {
        return _getAux(minter);
    }

    function incrementMintedNumberInAux(
        uint64 mask,
        uint8 offset,
        uint8 amount
    ) internal returns (uint8) {
        uint64 aux = _getAux(msg.sender);
        uint8 newMintedAmount = uint8((aux >> offset) & 0xFF) + amount;
        _setAux(msg.sender, (aux & mask) | (uint64(newMintedAmount) << offset));
        return newMintedAmount;
    }

    function _presaleMinted(address minter) public view returns (uint8) {
        return uint8((_getAux(minter) >> 16) & 0xFF);
    }

    function incrementPresaleMinted(uint8 amount) internal returns (uint8) {
        return incrementMintedNumberInAux(0x00FFFF, 16, amount);
    }

    function _raffleSaleMinted(address minter) public view returns (uint8) {
        return uint8((_getAux(minter) >> 8) & 0xFF);
    }

    function incrementRaffleMinted(uint8 amount) internal returns (uint8) {
        return incrementMintedNumberInAux(0xFF00FF, 8, amount);
    }

    function _publicSaleMinted(address minter) public view returns (uint8) {
        return uint8(_getAux(minter) & 0xFF);
    }

    function incrementPublicMinted(uint8 amount) internal returns (uint8) {
        return incrementMintedNumberInAux(0xFFFF00, 0, amount);
    }

    // ::
    // :: Admin operation
    // ::

    function sekiraDevMint(address to, uint16 amount) external onlyOwner {
        Config memory config = _config;

        require(amount + config.devMinted <= config.devReservedSupply, "SeKira: exceed dev reserved supply");
        _config.devMinted += amount;

        _safeMint(to, amount);
    }

    function setURIPrefix(string calldata uriPrefix) external onlyOwner {
        _uriPrefix = uriPrefix;
    }

    function setPrices(
        uint16 presalePrice,
        uint16 raffleSalePrice,
        uint16 publicSalePrice
    ) external onlyOwner {
        Config memory config = _config;

        config.presalePrice = presalePrice;
        config.raffleSalePrice = raffleSalePrice;
        config.publicSalePrice = publicSalePrice;

        _config = config;
    }

    function setRoyaltyRate(uint16 royaltyRate) external onlyOwner {
        require(royaltyRate <= FEE_DENOMINATOR, "SeKira: invalid royalty fee rate");
        _config.royaltyRate = royaltyRate;
    }

    function setPresaleState(bool newState) external onlyOwner {
        if (newState) {
            require(!_config.isPublicSaleActive, "SeKira: public sale is started");
        }

        _config.isPresaleActive = newState;
    }

    function setRaffleSaleState(bool newState) external onlyOwner {
        if (newState) {
            require(!_config.isPublicSaleActive, "SeKira: public sale is started");
        }

        _config.isRaffleSaleActive = newState;
    }

    function setPublicSaleState(bool newState) external onlyOwner {
        if (newState) {
            require(!_config.isPresaleActive, "SeKira: presale is started");
            require(!_config.isRaffleSaleActive, "SeKira: raffle sale is started");
        }

        _config.isPublicSaleActive = newState;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    // ::
    // :: EIP Implementations
    // ::

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(_uriPrefix, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || ERC721A.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "SeKira: query nonexistent token");
        return (owner(), (salePrice * _config.royaltyRate) / FEE_DENOMINATOR);
    }
}