// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "../interface/ITengoku.sol";

struct Conf {
    uint256 wlPrice; //0.068
    uint256 mintMax; //maximum amount to mint
    uint256 publicBegin; //public begin mint time
    uint256 publicDuration; //public duration mint time
    uint256 insureDuration; //insure duration time
    uint256 publicPrice; //0.1
    address refundAddress; //address which refunded erc721 will be sent to
    address payable withdrawTo; //withdraw to this address
}

contract Tengoku is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    IERC721Tengoku
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    bytes32 public wlMerkleRoot;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public wlCount; //wl already mint

    uint256 private _entered;
    modifier nonReentrant() {
        require(_entered == 0, "Tengoku: reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }
    CountersUpgradeable.Counter private _tokenIdCounter;
    string public _baseTokenURI;
    uint256 public constant collectionSize = 5555;
    Conf public conf;
    mapping(address => bool) public whitelistClaimed; //address =>isClaimed
    mapping(uint256 => bool) public hasRefunded; // users can search if the NFT has been refunded
    mapping(address => uint256) public publicClaimNum; //address =>claim num

    mapping(address => mapping(uint256 => bool)) private enableRefund; //address =>tokenId => enable refund
    mapping(uint256 => bool) private isWl;
    bool public isWithdrawed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("TENGOKU SPACE", "Tengoku");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        conf.wlPrice = 0.068 ether;
        conf.publicBegin = 1666436400;
        conf.publicDuration = 1 days;
        conf.insureDuration = 30 days;
        conf.publicPrice = 0.1 ether;
        conf.refundAddress = 0x1e593471a9F82c8a098acF41c262fFdf803536B4;
        conf.withdrawTo = payable(0x1e593471a9F82c8a098acF41c262fFdf803536B4);
        conf.mintMax = 10;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setBaseURI(string calldata baseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseURI;
    }

    function setConf(Conf calldata conf_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        conf = conf_;
    }

    function setWlMerkleRoot(bytes32 root)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        wlMerkleRoot = root;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + 1 <= collectionSize, "Tengoku: reached max");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function publicMintBatch(uint256 vol, bytes32[] calldata _merkleProof)
        public
        payable
        whenNotPaused
    {
        require(vol > 0, "Tengoku: Vol should be greater than 0");
        uint256 claimed = publicClaimNum[msg.sender];
        require(
            (claimed + vol) <= conf.mintMax,
            "Tengoku: Address claim max <= publicMax"
        );
        require(
            totalSupply() + vol <= collectionSize,
            "Tengoku: reached max supply"
        );
        uint256 refundAmount = conf.publicPrice;
        uint256 tokenId = _tokenIdCounter.current();

        //white list claim
        if (_merkleProof.length > 0) {
            require(
                !whitelistClaimed[msg.sender],
                "Tengoku: White list claim max <= 1"
            );
            isWl[tokenId] = true;
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProofUpgradeable.verify(_merkleProof, wlMerkleRoot, leaf),
                "Tengoku: Invalid Proof."
            );
            whitelistClaimed[msg.sender] = true;
            wlCount++;
            refundAmount = conf.wlPrice;
        }
        publicClaimNum[msg.sender] = claimed + vol;
        __batchMint(msg.sender, vol);
        for (uint256 i = 0; i < vol; i++) {
            enableRefund[msg.sender][tokenId + i] = true;
        }
        refundIfOver(conf.publicPrice * (vol - 1) + refundAmount);
        require(conf.publicBegin <= block.timestamp, "Tengoku: Not begin");
        require(block.timestamp <= getPublicEndTime(), "Tengoku: Expired");
    }

    function __batchMint(address to, uint256 vol) internal {
        uint256 tokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < vol; i++) {
            _safeMint(to, tokenId);
            tokenId++;
            _tokenIdCounter.increment();
        }
    }

    function batchMints(address[] calldata tos, uint256[] calldata vols)
        public
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        require(tos.length == vols.length, "Tengoku: length do not match");
        uint256 tokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < tos.length; i++) {
            for (uint256 j = 0; j < vols[i]; j++) {
                _safeMint(tos[i], tokenId);
                tokenId++;
                _tokenIdCounter.increment();
            }
        }
        require(tokenId <= collectionSize, "Tengoku: over max supply");
    }

    function batchMint(address to, uint256 vol)
        public
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        require(
            totalSupply() + vol <= collectionSize,
            "Tengoku: reached max supply"
        );
        __batchMint(to, vol);
    }

    function refundIfOver(uint256 price_) private nonReentrant {
        require(msg.value >= price_, "Tengoku: Need to send more ETH.");
        if (msg.value > price_) {
            payable(msg.sender).transfer(msg.value - price_);
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(block.timestamp > getRefundEndTime(),"Tengoku: Withdraw not begin");
        (bool success, ) = conf.withdrawTo.call{value: address(this).balance}(
            ""
        );
        isWithdrawed = true;
        require(success, "Tengoku: Transfer failed.");
    }

    // Minter spawns new 3D PFP after destroying 2D PFP. 
    function batchBurn(uint256[] calldata tokenIds) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(block.timestamp > getRefundEndTime(), "Tengoku: Burn not begin");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        string memory prefixUrl = super.tokenURI(tokenId);
        return string(abi.encodePacked(prefixUrl, ".json"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
        if (!isWithdrawed && from != address(0) && enableRefund[from][tokenId]) {
            require(!hasRefunded[tokenId], "Tengoku: Refunded");
            hasRefunded[tokenId] = true;
            enableRefund[from][tokenId] = false;
            uint256 refundPrice = conf.publicPrice;
            if (isWl[tokenId]) {
                refundPrice = conf.wlPrice;
            }
            payable(conf.withdrawTo).transfer(refundPrice);
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function refund(uint256[] calldata tokenIds) external override {
        require(isRefundGuaranteeActive(), "Tengoku: Not actived");
        uint256 refundAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Tengoku: Not owner");
            require(!hasRefunded[tokenId], "Tengoku: Refunded");
            require(
                enableRefund[msg.sender][tokenId],
                "Tengoku: Not init holder"
            );
            hasRefunded[tokenId] = true;
            enableRefund[msg.sender][tokenId] = false;
            transferFrom(msg.sender, conf.refundAddress, tokenId);
            uint256 refundPrice = conf.publicPrice;
            if (isWl[tokenId]) {
                refundPrice = conf.wlPrice;
            }
            refundAmount += refundPrice;
            emit Refund(msg.sender, tokenId, refundPrice);
        }
        payable(msg.sender).transfer(refundAmount);
    }

    function getPublicEndTime() public view returns (uint256) {
        return conf.publicBegin + conf.publicDuration;
    }

    function getRefundPrice(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        if (isWl[tokenId]) {
            return conf.wlPrice;
        } else if (tokenId < totalSupply()) {
            return conf.publicPrice;
        }
        return 0;
    }

    function canBeRefunded(address refunder, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return enableRefund[refunder][tokenId];
    }

    function getRefundGuaranteeBeginTime()
        public
        view
        override
        returns (uint256)
    {
        return conf.publicBegin + conf.insureDuration;
    }

    function isRefundGuaranteeActive() public view override returns (bool) {
        return (block.timestamp >= getRefundGuaranteeBeginTime() &&
            block.timestamp <= getRefundEndTime());
    }

    function getRefundEndTime() public view returns (uint256) {
        return getRefundGuaranteeBeginTime() + 1 days;
    }
}