// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract BBots is ERC721AQueryable, ERC2981, Ownable {
    uint256 public constant MAX_SUPPLY = 999;

    uint256 public maxMintWL = 2;

    string public tokenBaseURI;

    using SafeMath for uint256;

    struct SaleConfig {
        uint256 startTime; //ftb sale start timestamp
        bool ended; //true when ended
        uint256 ftbWindow;
        uint256 wlWindow;
    }

    SaleConfig mintConfig;

    bytes32 whitelistRoot;
    bytes32 ftbHolderRoot;

    uint256 public mintPrice = 0.039 ether;
    address immutable treasury;

    mapping(address => uint256) public wlMints;
    mapping(address => uint256) public ftbMints;

    modifier MintValidation(uint256 quantity) {
        require(_saleStarted(), "SALE_NOT_STARTED");
        require(totalSupply() + quantity <= MAX_SUPPLY, "EXCEEDS_SUPPLY");
        require(msg.value >= mintPrice * quantity, "INSUFFICIENT_AMOUNT");
        _;
    }

    event NewMinter(address indexed minter, uint256 qty);

    constructor(
        address _royaltyReceiver,
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        _setDefaultRoyalty(_royaltyReceiver, 250);
        treasury = _royaltyReceiver;

        mintConfig.wlWindow = 60 * 60 * 24; //a day
        mintConfig.ftbWindow = 60 * 60; //an hour

        tokenBaseURI = "https://bubbebot.s3.us-west-2.amazonaws.com/metadata/bubble-bot/";
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _saleStarted() internal view returns (bool) {
        if (mintConfig.ended) {
            return false;
        }

        return mintConfig.startTime > 0 && block.timestamp >= mintConfig.startTime;
    }

    function _isFtbSale() internal view returns (bool) {
        uint256 ftbSaleEndTime = mintConfig.startTime.add(mintConfig.ftbWindow);

        return block.timestamp <= ftbSaleEndTime;
    }

    function _isWhiteListSale() internal view returns (bool) {
        uint256 ftbSaleEndTime = mintConfig.startTime.add(mintConfig.ftbWindow);

        uint256 wlSaleEndTime = ftbSaleEndTime.add(mintConfig.wlWindow);

        return block.timestamp <= wlSaleEndTime && block.timestamp >= ftbSaleEndTime;
    }

    function _isPublicSale() internal view returns (bool) {
        uint256 ftbSaleEndTime = mintConfig.startTime.add(mintConfig.ftbWindow);

        uint256 wlSaleEndTime = ftbSaleEndTime.add(mintConfig.wlWindow);

        return block.timestamp >= wlSaleEndTime;
    }

    function _mintRobot(address _minter, uint256 _qty) internal {
        _safeMint(_minter, _qty);
        emit NewMinter(_minter, _qty);
    }

    function mintBBots(
        uint256 quantity,
        bytes32[] calldata merkleProof,
        uint256 approvedQt
    ) external payable MintValidation(quantity) {
        if (_isFtbSale()) {
            require(verifyFtbWhiteList(msg.sender, merkleProof, approvedQt), "NOT_WHITELISTED");

            uint256 totalMints = ftbMints[msg.sender];

            require(totalMints.add(quantity) <= approvedQt, "EXCEEDS_MAX");

            ftbMints[msg.sender] = totalMints + quantity;

            _mintRobot(msg.sender, quantity);
        }

        if (_isWhiteListSale()) {
            require(verifyNormalWhiteList(msg.sender, merkleProof), "NOT_WHITELISTED");

            uint256 totalWhitelistMints = wlMints[msg.sender];

            require(totalWhitelistMints.add(quantity) <= maxMintWL, "EXCEEDS_MAX");

            wlMints[msg.sender] = totalWhitelistMints + quantity;

            _mintRobot(msg.sender, quantity);
        }

        if (_isPublicSale()) {
            _mintRobot(msg.sender, quantity);
        }

        _withdrawEth();
    }

    function verifyFtbWhiteList(
        address _user,
        bytes32[] calldata _merkleProof,
        uint256 quantity
    ) public view returns (bool) {
        bytes32 merkleLeaf = keccak256(abi.encodePacked(_user, quantity));

        return _verifyIfWhiteListed(ftbHolderRoot, _merkleProof, merkleLeaf);
    }

    function verifyNormalWhiteList(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 merkleLeaf = keccak256(abi.encodePacked(_user));

        return _verifyIfWhiteListed(whitelistRoot, _merkleProof, merkleLeaf);
    }

    function _verifyIfWhiteListed(
        bytes32 _root,
        bytes32[] calldata _merkleProof,
        bytes32 leaf
    ) internal pure returns (bool) {
        return MerkleProof.verify(_merkleProof, _root, leaf);
    }

    function updateBaseUri(string memory baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    function updateMaxMintWL(uint256 _maxMintWL) external onlyOwner {
        maxMintWL = _maxMintWL;
    }

    function startedTime() external view returns (uint256) {
        return mintConfig.startTime;
    }

    function getSaleStatus() external view returns (uint8) {
        if (_saleStarted()) {
            if (_isPublicSale()) {
                return 3;
            }

            if (_isWhiteListSale()) {
                return 2;
            }

            if (_isFtbSale()) {
                return 1;
            }
        }

        return 0;
    }

    function updateMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setWhitelistRoots(bytes32 _whiteListRoot, bytes32 _ftbHolderRoot) external onlyOwner {
        whitelistRoot = _whiteListRoot;
        ftbHolderRoot = _ftbHolderRoot;
    }

    function startSale() external onlyOwner {
        require(!_saleStarted(), "ALREADY_STARTED");
        mintConfig.startTime = block.timestamp;
    }

    function endSale() external onlyOwner {
        mintConfig.ended = true;
    }

    function switchSalePhase(uint256 _ftbWindow, uint256 _wlWindow) external onlyOwner {
        mintConfig.startTime = block.timestamp;
        mintConfig.ftbWindow = _ftbWindow;
        mintConfig.wlWindow = _wlWindow;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function _withdrawEth() internal {
        (bool os, ) = payable(treasury).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for non existent token");
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}