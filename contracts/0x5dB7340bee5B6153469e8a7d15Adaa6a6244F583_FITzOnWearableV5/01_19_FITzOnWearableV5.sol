// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract FITzOnWearableV5 is Initializable,
        OwnableUpgradeable,
        ERC721EnumerableUpgradeable,
        ERC721BurnableUpgradeable,
        ERC721RoyaltyUpgradeable {
    bytes32 public devMintMerkleRoot;
    bytes32 public fastPassMerkleRoot;
    bytes32 public preSaleMerkleRoot;
    uint256 private _preSaleTokenId;
    string private _name;
    string private _symbol;
    string private _baseTokenURI;

    struct DevMintConfig {
        uint32 startTime;
        uint16 quantity;
        uint64 price;
    }

    struct PreSaleConfig {
        uint32 fpStartTime;
        uint16 fpQuantity;
        uint32 startTime;
        uint16 quantity;
        uint64 price;
    }

    struct PreSaleVVIPConfig {
        uint32 startTime;
        uint32 endTime;
        uint64 price;
    }

    DevMintConfig public devMintConfig;
    PreSaleConfig public preSaleEBConfig;
    PreSaleConfig public preSalePVConfig;
    PreSaleConfig public preSaleCMConfig;
    mapping(address => uint256) private _devMintAmounts;
    mapping(address => uint256) private _preSaleMintAmounts;
    uint256 public maxSupply;
    uint8 public devMintLimit;
    uint8 public preSaleMintLimit;
    bytes32 public discountMerkleRoot;
    bytes32 public vvipMerkleRoot;
    bytes32 public vvipDiscountMerkleRoot;
    PreSaleVVIPConfig public preSaleVVIPConfig;
    uint256 public preSaleSoldQuantity;
    uint32 public publicMintStartTime;
    uint64 public publicMintPrice;
    uint16 public publicMintSupply;

    function initialize(string memory __name, string memory __symbol) public initializer {
        __Ownable_init();
        __ERC721_init(__name, __symbol);
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __ERC721Royalty_init();

        _name = __name;
        _symbol = __symbol;
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        require(totalSupply() < maxSupply, "Reached max supply");
        _safeMint(to, tokenId);
    }

    function devMint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(devMintConfig.startTime != 0, "Dev mint is not started");
        require(block.timestamp >= devMintConfig.startTime, "Dev mint is not started");
        require(totalSupply() + quantity <= devMintConfig.quantity, "Reached max supply");
        require(totalSupply() + quantity <= maxSupply, "Reached max supply");
        require(_verify(proof, devMintMerkleRoot, _leaf(to)), "Invalid merkle proof");
        require(devMintConfig.price * quantity <= msg.value, "Not enough tokens");
        require(_devMintAmounts[to] + quantity <= devMintLimit, "Reached limit of mints");

        _devMintAmounts[to] += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _preSaleTokenId);
            _preSaleTokenId ++;
        }
    }

    function preSaleMint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(isPublicSaleStarted(), "Public mint is not started");
        require(preSaleSoldQuantity + quantity <= preSaleSupply(), "Reached max supply");
        require(totalSupply() + quantity <= maxSupply, "Reached max supply");
        require(_verify(proof, preSaleMerkleRoot, _leaf(to)), "Invalid merkle proof");
        require(preSalePrice() * quantity <= msg.value, "Not enough tokens");
        require(_preSaleMintAmounts[to] + quantity <= preSaleMintLimit, "Reached limit of mints");

        _preSaleMintAmounts[to] += quantity;
        preSaleSoldQuantity += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _preSaleTokenId);
            _preSaleTokenId ++;
        }
    }

    function preSaleDiscountMint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(isPublicSaleStarted(), "Public mint is not started");
        require(preSaleSoldQuantity + quantity <= preSaleSupply(), "Reached max supply");
        require(totalSupply() + quantity <= maxSupply, "Reached max supply");
        require(_verify(proof, discountMerkleRoot, _leaf(to)), "Invalid merkle proof");
        require(preSalePrice() *  quantity * 9 / 10 <= msg.value, "Not enough tokens");
        require(_preSaleMintAmounts[to] + quantity <= preSaleMintLimit, "Reached limit of mints");

        _preSaleMintAmounts[to] += quantity;
        preSaleSoldQuantity += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _preSaleTokenId);
            _preSaleTokenId ++;
        }
    }

    function preSaleVVIPMint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(isVVIPMintTime(), "VVIP mint is closed");
        require(totalSupply() + quantity <= maxSupply, "Reached max supply");
        require(_verify(proof, vvipMerkleRoot, _leaf(to)), "Invalid merkle proof");
        require(preSaleVVIPConfig.price * quantity <= msg.value, "Not enough tokens");
        require(_preSaleMintAmounts[to] + quantity <= preSaleMintLimit, "Reached limit of mints");

        _preSaleMintAmounts[to] += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _preSaleTokenId);
            _preSaleTokenId ++;
        }
    }

    function preSaleVVIPDiscountMint(address to, uint256 quantity, bytes32[] calldata proof) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(isVVIPMintTime(), "VVIP mint is closed");
        require(totalSupply() + quantity <= maxSupply, "Reached max supply");
        require(_verify(proof, vvipDiscountMerkleRoot, _leaf(to)), "Invalid merkle proof");
        require(preSaleVVIPConfig.price *  quantity * 9 / 10 <= msg.value, "Not enough tokens");
        require(_preSaleMintAmounts[to] + quantity <= preSaleMintLimit, "Reached limit of mints");

        _preSaleMintAmounts[to] += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _preSaleTokenId);
            _preSaleTokenId ++;
        }
    }

    function publicMint(address to, uint256 quantity) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(block.timestamp >= publicMintStartTime, "Public mint is not started");
        require(totalSupply() + quantity <= publicMintSupply, "Reached max supply");
        require(totalSupply() + quantity <= maxSupply, "Reached max supply");
        require(publicMintPrice * quantity <= msg.value, "Not enough tokens");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _preSaleTokenId);
            _preSaleTokenId ++;
        }
    }

    function isPublicSaleStarted() public view returns (bool) {
        uint256 startTime = uint256(preSaleEBConfig.startTime);
        return startTime != 0 && block.timestamp >= startTime;
    }

    function isVVIPMintTime() public view returns (bool) {
        uint256 startTime = uint256(preSaleVVIPConfig.startTime);
        uint256 endTime = uint256(preSaleVVIPConfig.endTime);
        return startTime != 0 && block.timestamp >= startTime && block.timestamp < endTime;
    }

    function preSaleSupply() public view returns (uint16) {
        if (preSaleEBConfig.startTime == 0 ||
            block.timestamp < uint256(preSaleEBConfig.startTime)) {
            return 0;
        } else if (block.timestamp < uint256(preSalePVConfig.startTime)) {
            return preSaleEBConfig.quantity;
        } else if (block.timestamp < uint256(preSaleCMConfig.startTime)) {
            return preSalePVConfig.quantity;
        } else {
            return preSaleCMConfig.quantity;
        }
    }

    function preSalePrice() public view returns (uint64) {
        if (block.timestamp >= uint256(preSaleCMConfig.startTime)) {
            return preSaleCMConfig.price;
        } else if (block.timestamp >= uint256(preSalePVConfig.startTime)) {
            return preSalePVConfig.price;
        } else {
            return preSaleEBConfig.price;
        }
    }

    function devMintAmount(address addr) external view returns (uint256) {
        return _devMintAmounts[addr];
    }

    function preSaleMintAmount(address addr) external view returns (uint256) {
        return _preSaleMintAmounts[addr];
    }

    function setDevMintConfig(
      uint32 devStartTime,
      uint16 devQuantity,
      uint64 devPrice
    ) external onlyOwner {
        devMintConfig = DevMintConfig(
            devStartTime,
            devQuantity,
            devPrice
        );
    }

    function setPreSaleEBConfig(
      uint32 startTime,
      uint16 quantity,
      uint64 price
    ) external onlyOwner {
        require(quantity > 0, "Bad quantity");
        require(startTime > 0, "Bad start time");

        preSaleEBConfig = PreSaleConfig(
            0,
            0,
            startTime,
            quantity,
            price
        );
    }

    function setPreSalePVConfig(
      uint32 startTime,
      uint16 quantity,
      uint64 price
    ) external onlyOwner {
        require(quantity > preSaleEBConfig.quantity, "Bad quantity");
        require(startTime > preSaleEBConfig.startTime, "Start time should later than early bird");

        preSalePVConfig = PreSaleConfig(
            0,
            0,
            startTime,
            quantity,
            price
        );
    }

    function setPreSaleCMConfig(
      uint32 startTime,
      uint16 quantity,
      uint64 price
    ) external onlyOwner {
        require(quantity > preSalePVConfig.quantity, "Bad quantity");
        require(startTime > preSalePVConfig.startTime, "Start time should later than private");

        preSaleCMConfig = PreSaleConfig(
            0,
            0,
            startTime,
            quantity,
            price
        );
    }

    function setPreSaleVVIPConfig(
      uint32 startTime,
      uint32 endTime,
      uint64 price
    ) external onlyOwner {
        require(startTime > 0, "Bad start time");
        require(endTime > startTime, "Bad end time");

        preSaleVVIPConfig = PreSaleVVIPConfig(
            startTime,
            endTime,
            price
        );
    }

    function setPublicMintConfig(
      uint32 startTime,
      uint16 quantity,
      uint64 price
    ) external onlyOwner {
        require(startTime > 0, "Bad start time");

        publicMintStartTime = startTime;
        publicMintSupply = quantity;
        publicMintPrice = price;
    }

    function setPreSaleTokenId(uint256 startTokenId) external onlyOwner {
        _preSaleTokenId = startTokenId;
    }

    function setDevMintMerkleRoot(bytes32 root) external onlyOwner {
        devMintMerkleRoot = root;
    }

    function setFastPassMerkleRoot(bytes32 root) external onlyOwner {
        fastPassMerkleRoot = root;
    }

    function setPreSaleMerkleRoot(bytes32 root) external onlyOwner {
        preSaleMerkleRoot = root;
    }

    function setDiscountMerkleRoot(bytes32 root) external onlyOwner {
        discountMerkleRoot = root;
    }

    function setVVIPMerkleRoot(bytes32 root) external onlyOwner {
        vvipMerkleRoot = root;
    }

    function setVVIPDiscountMerkleRoot(bytes32 root) external onlyOwner {
        vvipDiscountMerkleRoot = root;
    }

    function _leaf(address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32[] memory proof, bytes32 merkleRoot, bytes32 leaf) private pure returns (bool) {
        return MerkleProofUpgradeable.verify(proof, merkleRoot, leaf);
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setDevMintLimit(uint8 limit) external onlyOwner {
        devMintLimit = limit;
    }

    function setPreSaleMintLimit(uint8 limit) external onlyOwner {
        preSaleMintLimit = limit;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function withdraw(uint256 amount) external onlyOwner {
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to send native token");
    }

    function setNameAndSymbol(string memory __name, string memory __symbol) external onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return ERC721Upgradeable.tokenURI(tokenId);
    }

    function tokensOfOwner(address owner, uint256 startIndex, uint256 count) external view returns (uint256[] memory) {
        uint256[] memory tokens;
        if (startIndex >= ERC721Upgradeable.balanceOf(owner)) {
            return tokens;
        } else if (startIndex + count >= ERC721Upgradeable.balanceOf(owner)) {
            count = ERC721Upgradeable.balanceOf(owner) - startIndex;
        }

        uint256 index = 0;
        tokens = new uint256[](count);
        for (index; index < count; index++) {
            tokens[index] = ERC721EnumerableUpgradeable.tokenOfOwnerByIndex(owner, startIndex + index);
        }
        return tokens;
    }

    function _burn(uint256 tokenId)
            internal virtual
            override(ERC721Upgradeable,
                     ERC721RoyaltyUpgradeable) {
        return super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
            internal virtual
            override(ERC721Upgradeable,
                     ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
            public view virtual
            override(ERC721Upgradeable,
                     ERC721EnumerableUpgradeable,
                     ERC721RoyaltyUpgradeable)
            returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}