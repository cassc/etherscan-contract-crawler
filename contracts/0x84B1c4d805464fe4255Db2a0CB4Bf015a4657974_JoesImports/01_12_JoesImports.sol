// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Project by @312Labs
// Contract by @AsteriaLabs
// Audited by @SilikaStudio

/// @title Joe's Imports NFT
/// @author Skeith <[email protected]>
contract JoesImports is ERC721, Ownable {
    using MerkleProof for bytes32[];

    uint16 constant public BRONZE_TOKEN_TYPE = 0;
    uint16 constant public SILVER_TOKEN_TYPE = 1;
    uint16 constant public GOLD_TOKEN_TYPE = 2;

    uint8 constant public ALLOW_FREE_MINTS = 1;
    uint8 constant public ALLOW_WHITELIST_MINTS = 1 << 1;
    uint8 constant public ALLOW_PUBLIC_MINTS = 1 << 2;

    string public baseURI;

    uint8 public state;

    uint16[3] public maxMintsPerSlot = [6, 3, 1];
    uint256[3] public prices = [0.066 ether, 0.33 ether, 1.16 ether];

    uint16[4] public startingTokenIds = [1, 1001, 1101, 1111];
    uint16[3] public nextTokenId = [1, 1001, 1101];
    uint16[3] public maxTotalSupplies = [1000, 100, 10];

    bytes32 public merkleRoot;
    bytes32 public freeMintMerkleRoot;

    /// @dev Mint counts per whitelisted address
    mapping(address => uint[3]) public mintCounts;
    mapping(address => bool) public hasFreeMinted;

    constructor() ERC721("Joe's Imports", "WINE") {}

    modifier whenInState(uint8 _state) {
        if (state & _state > 0) {
            _;
        } else {
            revert("Operation not allowed in this state");
        }
    }

    modifier checkTokenType(uint16 tokenType) {
        if (tokenType < 3) {
            _;
        } else {
            revert("Unsupported token type");
        }
    }

    function _mint(address to, uint16 tokenType, uint16 amount) internal {
        uint256 baseTokenId = nextTokenId[tokenType];

        nextTokenId[tokenType] += amount;

        for (uint256 i; i < amount;) {
            _mint(to, baseTokenId + i);
            unchecked { ++i; }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // @dev This does not consider burned tokens
    function _totalSupply(uint16 tokenType) internal view returns (uint256) {
        return nextTokenId[tokenType] - startingTokenIds[tokenType];
    }

    function _checkIfMintExceedsSupply(uint16 tokenType, uint256 amount) internal view returns (bool) {
        return _totalSupply(tokenType) + amount <= maxTotalSupplies[tokenType];
    }

    // === MANAGEMENT ===
    function totalSupplyOfType(uint16 tokenType) external view checkTokenType(tokenType) returns (uint256) {
        return _totalSupply(tokenType);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply(BRONZE_TOKEN_TYPE) + _totalSupply(SILVER_TOKEN_TYPE) + _totalSupply(GOLD_TOKEN_TYPE);
    }

    function setState(uint8 _state) external onlyOwner {
        state = _state;
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTotalSupply(uint16 tokenType, uint16 __totalSupply) external onlyOwner checkTokenType(tokenType) {
        require(__totalSupply <= startingTokenIds[tokenType + 1] - startingTokenIds[tokenType], "Value will overflow to next tier");
        maxTotalSupplies[tokenType] = __totalSupply;
    }

    function setPrice(uint16 tokenType, uint256 price) external onlyOwner checkTokenType(tokenType) {
        prices[tokenType] = price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setFreeMintMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        freeMintMerkleRoot = _merkleRoot;
    }

    function checkWhitelist(bytes32[] calldata _proof, address _address) public view returns (bool) {
        return _proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function checkFreeMintWhitelist(bytes32[] calldata _proof, address _address) public view returns (bool) {
        return _proof.verify(freeMintMerkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function withdrawBalance(address to) external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");

        (bool success, ) = payable(to).call{ value: address(this).balance }("");
        require(success, "Failed to withdraw funds");
    }

    // === INFORMATION ===
    function getPrices() external view returns (uint256[3] memory) {
        return prices;
    }

    function getRemainingMints(address _address) external view returns (uint256[] memory) {
        uint256[] memory remainingMints = new uint256[](3);
        remainingMints[0] = maxMintsPerSlot[0] - mintCounts[_address][0];
        remainingMints[1] = maxMintsPerSlot[1] - mintCounts[_address][1];
        remainingMints[2] = maxMintsPerSlot[2] - mintCounts[_address][2];

        return remainingMints;
    }

    // === MINTING ===
    function freeMint(bytes32[] calldata proof) external whenInState(ALLOW_FREE_MINTS) payable {
        require(checkFreeMintWhitelist(proof, msg.sender), "Not eligible for free mint");
        require(_checkIfMintExceedsSupply(BRONZE_TOKEN_TYPE, 1), "Token already sold out");

        require(!hasFreeMinted[msg.sender], "Free mint already claimed");

        hasFreeMinted[msg.sender] = true;

        _mint(msg.sender, BRONZE_TOKEN_TYPE, 1);
    }

    function whitelistMint(bytes32[] calldata proof, uint16 tokenType, uint16 amount) external whenInState(ALLOW_WHITELIST_MINTS) checkTokenType(tokenType) payable {
        require(amount > 0, "No tokens to mint");
        require(checkWhitelist(proof, msg.sender), "Address is not whitelisted");
        require(mintCounts[msg.sender][tokenType] + amount <= maxMintsPerSlot[tokenType], "Max mints per slot exceeded");
        require(_checkIfMintExceedsSupply(tokenType, amount), "Token already sold out");

        mintCounts[msg.sender][tokenType] += amount;

        require(msg.value == prices[tokenType] * amount, "Invalid payment amount");

        _mint(msg.sender, tokenType, amount);
    }

    function batchWhitelistMint(bytes32[] calldata proof, uint16 bronze, uint16 silver, uint16 gold) external whenInState(ALLOW_WHITELIST_MINTS) payable {
        require(bronze > 0 || silver > 0 || gold > 0, "No tokens to mint");
        require(checkWhitelist(proof, msg.sender), "Address is not whitelisted");
        require(
            msg.value == prices[BRONZE_TOKEN_TYPE] * bronze
                + prices[SILVER_TOKEN_TYPE] * silver
                + prices[GOLD_TOKEN_TYPE] * gold,
            "Invalid payment amount"
        );

        if (bronze > 0) {
            require(mintCounts[msg.sender][BRONZE_TOKEN_TYPE] + bronze <= maxMintsPerSlot[BRONZE_TOKEN_TYPE], "Max bronze mints exceeded");
            require(_checkIfMintExceedsSupply(BRONZE_TOKEN_TYPE, bronze), "Bronze token already sold out");

            mintCounts[msg.sender][BRONZE_TOKEN_TYPE] += bronze;
        }

        if (silver > 0) {
            require(mintCounts[msg.sender][SILVER_TOKEN_TYPE] + silver <= maxMintsPerSlot[SILVER_TOKEN_TYPE], "Max silver mints exceeded");
            require(_checkIfMintExceedsSupply(SILVER_TOKEN_TYPE, silver), "Silver token already sold out");

            mintCounts[msg.sender][SILVER_TOKEN_TYPE] += silver;
        }

        if (gold > 0) {
            require(mintCounts[msg.sender][GOLD_TOKEN_TYPE] + gold <= maxMintsPerSlot[GOLD_TOKEN_TYPE], "Max gold mints exceeded");
            require(_checkIfMintExceedsSupply(GOLD_TOKEN_TYPE, gold), "Gold token already sold out");

            mintCounts[msg.sender][GOLD_TOKEN_TYPE] += gold;
        }

        if (bronze > 0) _mint(msg.sender, BRONZE_TOKEN_TYPE, bronze);
        if (silver > 0) _mint(msg.sender, SILVER_TOKEN_TYPE, silver);
        if (gold > 0) _mint(msg.sender, GOLD_TOKEN_TYPE, gold);
    }

    function publicMint(uint16 tokenType, uint16 amount) external payable whenInState(ALLOW_PUBLIC_MINTS) checkTokenType(tokenType) {
        require(amount > 0, "No tokens to mint");
        require(_checkIfMintExceedsSupply(tokenType, amount), "Token already sold out");

        require(msg.value == prices[tokenType] * amount, "Invalid payment amount");

        _mint(msg.sender, tokenType, amount);
    }

    function batchPublicMint(uint16 bronze, uint16 silver, uint16 gold) external whenInState(ALLOW_PUBLIC_MINTS) payable {
        require(bronze > 0 || silver > 0 || gold > 0, "No tokens to mint");
        require(
            msg.value == prices[BRONZE_TOKEN_TYPE] * bronze
                + prices[SILVER_TOKEN_TYPE] * silver
                + prices[GOLD_TOKEN_TYPE] * gold,
            "Invalid payment amount"
        );

        if (bronze > 0) {
            require(_checkIfMintExceedsSupply(BRONZE_TOKEN_TYPE, bronze), "Bronze token already sold out");
            _mint(msg.sender, BRONZE_TOKEN_TYPE, bronze);
        }

        if (silver > 0) {
            require(_checkIfMintExceedsSupply(SILVER_TOKEN_TYPE, silver), "Silver token already sold out");
            _mint(msg.sender, SILVER_TOKEN_TYPE, silver);
        }

        if (gold > 0) {
            require(_checkIfMintExceedsSupply(GOLD_TOKEN_TYPE, gold), "Gold token already sold out");
            _mint(msg.sender, GOLD_TOKEN_TYPE, gold);
        }
    }
}