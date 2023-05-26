// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "erc721a/contracts/ERC721A.sol";

contract Owl is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    string private metaURI;

    uint256 public constant MAX_SUPPLY = 0xfffffffffffffffffffffffffffffffffff;
    mapping(address => uint256)[] public addressMinted;

    event Received(address indexed, uint256);
    event StageMintConfigChanged(StageMintConfig config);

    modifier onlyEOA() {
        require(tx.origin == _msgSender(), "only EOA allowed");
        _;
    }

    constructor() ERC721A("Hello Owl", "Hello Owl") {}

    struct StageMintConfig {
        uint64 stageNum;
        uint64 maxPerStage; // Maximum number that can be minted at this stage
        uint64 maxPerAddress;
        bool isWhiteListMintActive;
        bytes32 merkleRoot;
        bool isPublicMintActive;
    }

    StageMintConfig public stageMintConfig;

    function setStageMintConfig(StageMintConfig calldata config_)
        external
        onlyOwner
    {
        require(
            addressMinted.length == config_.stageNum,
            "stageNum should be strongly increasing from zero"
        );
        require(
            config_.maxPerStage <= MAX_SUPPLY,
            "maxPerStage can not exceed MAX_SUPPLY"
        );
        addressMinted.push();
        stageMintConfig = config_;
        emit StageMintConfigChanged(config_);
    }

    function setMaxPerStage(uint64 newMaxPerStage) external onlyOwner {
        require(newMaxPerStage > 0, "maxPerStage can not be zero");
        require(
            newMaxPerStage <= MAX_SUPPLY,
            "maxPerStage can not exceed MAX_SUPPLY"
        );
        stageMintConfig.maxPerStage = newMaxPerStage;
    }

    function setMaxPerAddress(uint64 newMaxPerAddress) external onlyOwner {
        require(newMaxPerAddress > 0, "newMaxPerAddress can not be zero");
        require(
            newMaxPerAddress <= MAX_SUPPLY,
            "newMaxPerAddress can not exceed MAX_SUPPLY"
        );

        stageMintConfig.maxPerAddress = newMaxPerAddress;
    }

    function setWhiteListMintActive(bool mintStarted) external onlyOwner {
        stageMintConfig.isWhiteListMintActive = mintStarted;
    }

    function setPublicMintActive(bool mintStarted) external onlyOwner {
        stageMintConfig.isPublicMintActive = mintStarted;
    }

    function whitelistMint(uint64 quantity, bytes32[] calldata merkleProof)
        external
        onlyEOA
        nonReentrant
    {
        require(
            stageMintConfig.isWhiteListMintActive,
            "whitelist mint has not started"
        );
        require(
            isKYCAddress(_msgSender(), merkleProof),
            "caller is not in whitelist or invalid merkleProof"
        );
        _claim(quantity);
    }

    function publicMint(uint64 quantity) external onlyEOA nonReentrant {
        require(
            stageMintConfig.isPublicMintActive,
            "public mint has not started"
        );
        _claim(quantity);
    }

    function _claim(uint64 quantity) internal {
        require(quantity > 0, "invalid number of tokens");
        require(
            addressMinted[stageMintConfig.stageNum][_msgSender()] + quantity <=
                stageMintConfig.maxPerAddress,
            "exceeded maxPerAddress"
        );
        require(
            totalMinted() + quantity <= stageMintConfig.maxPerStage,
            "exceeded maxPerStage"
        );

        addressMinted[stageMintConfig.stageNum][_msgSender()] += quantity;
        _safeMint(_msgSender(), quantity);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /***************Royalty***************/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "query for nonexistent token");
        return (address(this), (salePrice * 250) / 10000);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    function withdrawTokens(IERC20 token) external onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_msgSender(), balance);
    }

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    /***************TokenURI***************/
    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        metaURI = tokenURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "query for nonexistent token");
        return metaURI;
    }

    /***************Merkle***************/
    function setKycMerkleRoot(bytes32 _kycMerkleRoot) external onlyOwner {
        stageMintConfig.merkleRoot = _kycMerkleRoot;
    }

    function isKYCAddress(address address_, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        if (stageMintConfig.merkleRoot == "") {
            return false;
        }
        return
            MerkleProof.verify(
                merkleProof,
                stageMintConfig.merkleRoot,
                keccak256(abi.encodePacked(address_))
            );
    }
}