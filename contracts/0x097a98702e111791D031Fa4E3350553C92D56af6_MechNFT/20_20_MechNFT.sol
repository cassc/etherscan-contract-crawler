// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721psi/contracts/ERC721Psi.sol";

contract MechNFT is ERC721Psi, ERC2981, Ownable {
    enum MintStage {
        Whitelist,
        Public
    }

    using ECDSA for bytes32;
    using Strings for uint256;

    string public tokenBaseURI;
    uint256 public collectionSize;
    address public signerAddress;
    address public payoutAddress;

    mapping(uint256 => string) ipfsMetadataMapping;

    struct MintRoundConfig {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint64 roundLimit;
        uint64 mintLimitAmount;
        MintStage stage;
        mapping(address => uint256) mintAmount;
    }
    mapping(uint256 => MintRoundConfig) public mintConfigs;
    uint256 public mintConfigCount = 0;
    uint8 public currentRoundIndex;

    constructor(
        string memory _tokenBaseURI,
        uint256 _collectionSize,
        address _signerAddress,
        address _payoutAddress,
        address _feeAddress,
        uint96 _feeNumerator
    ) ERC721Psi("Mech NFT", "MECH") {
        tokenBaseURI = _tokenBaseURI;
        collectionSize = _collectionSize;
        signerAddress = _signerAddress;
        payoutAddress = _payoutAddress;
        currentRoundIndex = 0;

        _setDefaultRoyalty(_feeAddress, _feeNumerator);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory ipfsMetadataURI = ipfsMetadataMapping[tokenId];
        return
            bytes(ipfsMetadataURI).length != 0
                ? ipfsMetadataURI
                : string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    modifier checkMintConstraint(MintStage stage, uint256 quantity) {
        proceedMintRound();

        require(tx.origin == msg.sender, "Non human user");

        MintRoundConfig storage mintRound = mintConfigs[currentRoundIndex];
        require(mintRound.stage == stage, "Incorrect mint stage");

        uint256 currentMintAmount = mintRound.mintAmount[msg.sender];
        require(
            currentMintAmount + quantity <= mintRound.mintLimitAmount,
            "Exceed mint amount"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Exceed total supply"
        );
        require(
            totalSupply() + quantity <= mintRound.roundLimit,
            "Exceed round limit"
        );
        require(msg.value >= mintRound.price * quantity, "price not enough");
        require(
            block.timestamp >= mintRound.startTime &&
                block.timestamp <= mintRound.endTime,
            "Mint stage is not started"
        );

        _;
    }

    function whitelistMint(
        uint8 quantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable checkMintConstraint(MintStage.Whitelist, quantity) {
        require(isAuthorized(msg.sender, v, r, s), "Invalid signature");

        mintCallback(quantity, currentRoundIndex);
        _safeMint(msg.sender, quantity);

        if (msg.value > 0) {
            payable(payoutAddress).transfer(msg.value);
        }
    }

    function mint(uint8 quantity)
        external
        payable
        checkMintConstraint(MintStage.Public, quantity)
    {
        mintCallback(quantity, currentRoundIndex);
        _safeMint(msg.sender, quantity);

        if (msg.value > 0) {
            payable(payoutAddress).transfer(msg.value);
        }
    }

    function mintForAirdrop(address[] memory addresses, uint256 quantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantity);
        }
    }

    function getCurrentRoundIndex(uint256 currentTime)
        public
        view
        returns (uint8)
    {
        uint8 roundIndex = currentRoundIndex;
        while (mintConfigCount > roundIndex + 1) {
            uint256 endTime = mintConfigs[roundIndex].endTime;
            uint256 nextStageEndTime = endTime;

            if (currentTime >= nextStageEndTime) {
                roundIndex += 1;
            } else {
                return roundIndex;
            }
        }

        return roundIndex;
    }

    function proceedMintRound() private {
        uint8 roundIndex = getCurrentRoundIndex(block.timestamp);
        if (currentRoundIndex != roundIndex) {
            currentRoundIndex = roundIndex;
        }
    }

    function setCurrentRoundIndex(uint8 _currentRoundIndex) external onlyOwner {
        currentRoundIndex = _currentRoundIndex;
    }

    function setMintConfig(
        uint256 roundIndex,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        uint64 roundLimit,
        uint64 mintLimitAmount,
        MintStage stage
    ) external onlyOwner {
        if (roundIndex >= mintConfigCount) {
            mintConfigCount++;
        }

        MintRoundConfig storage config = mintConfigs[roundIndex];
        config.startTime = startTime;
        config.endTime = endTime;
        config.price = price;
        config.roundLimit = roundLimit;
        config.mintLimitAmount = mintLimitAmount;
        config.stage = stage;
    }

    function mintCallback(uint256 quantity, uint256 roundIndex) private {
        MintRoundConfig storage config = mintConfigs[roundIndex];
        config.mintAmount[msg.sender] += quantity;
    }

    function setIpfsMetadata(uint256 tokenId, string memory ipfsURI)
        external
        onlyOwner
    {
        ipfsMetadataMapping[tokenId] = ipfsURI;
    }

    function getCurrentMintAmount(uint256 timestamp)
        external
        view
        returns (uint256)
    {
        uint256 _currentRoundIndex = getCurrentRoundIndex(timestamp);
        MintRoundConfig storage mintRound = mintConfigs[_currentRoundIndex];

        return mintRound.mintAmount[msg.sender];
    }

    function isAuthorized(
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender));
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return signerAddress == ecrecover(signedHash, v, r, s);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Psi, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}