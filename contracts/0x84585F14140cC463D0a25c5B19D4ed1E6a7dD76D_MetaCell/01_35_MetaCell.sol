// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../erc721-tradable-upgradeable/ERC721TradableUpgradeable.sol";
import "./abstracts/ACellRepository.sol";
import "./interfaces/IMetaCellCreator.sol";

contract MetaCell is
    IMetaCellCreator,
    ERC721TradableUpgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable,
    ACellRepository,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using Counters for Counters.Counter;

    Counters.Counter private tokenIdCount;
    string public baseTokenURI;
    string public contractURI;
    bytes32 public giftMerkleRoot;
    uint256 public price;
    uint256 public maxClaimed;
    uint256 public mintableAmount;
    uint256 public remainingAmount;
    uint96 public feeNumerator;
    address private proxyRegistryAddress;
    mapping(bytes32 => uint256) public claimedTimes;
    bool public isCanTransfer;

    event SetNewTranche(
        bytes32 merkleRoot,
        uint256 newPrice,
        uint256 newAmount,
        uint256 newMaxClaimed,
        uint256 timestamp
    );

    event MintForGift(
        address caller,
        address to,
        uint256 tokenId,
        uint256 timestamp
    );

    event SetBaseTokenURI(string uri, uint256 timestamp);
    event SetContractURI(string uri, uint256 timestamp);
    event SetProxyRegistry(address proxy, uint256 timestamp);

    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        bytes32 validateData = getKeccakMetaCell(msg.sender);
        bytes32 leaf = keccak256(abi.encodePacked(validateData));
        bytes32 hashProof = keccak256(abi.encodePacked(merkleProof));
        require(
            claimedTimes[hashProof] < maxClaimed,
            "This wallet reached claimed times to mint MetaCell"
        );
        claimedTimes[hashProof]++;
        require(
            MerkleProof.verify(merkleProof, root, leaf),
            "Address does not exist in list"
        );
        _;
    }

    /**
     * @notice Keccak256 account to a bytes32 data
     */
    function getKeccakMetaCell(address account)
        public
        pure
        returns (bytes32 validateData)
    {
        validateData = keccak256(abi.encodePacked(account));
    }

    function claimable(bytes32[] calldata merkleProof, address account)
        external
        view
        returns (bool)
    {
        bytes32 validateData = getKeccakMetaCell(account);
        bytes32 leaf = keccak256(abi.encodePacked(validateData));
        bytes32 hashProof = keccak256(abi.encodePacked(merkleProof));
        return
            MerkleProof.verify(merkleProof, giftMerkleRoot, leaf) &&
            claimedTimes[hashProof] < maxClaimed;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        address _timelock
    ) external initializer {
        require(_proxyRegistryAddress != address(0), "Empty address");
        proxyRegistryAddress = _proxyRegistryAddress;
        timelock = _timelock;
        __ERC721_init(_name, _symbol);
        _initializeEIP712(_name);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        baseTokenURI = "";
        contractURI = "";
        maxClaimed = 1;
    }

    function getProxyRegistryAddress()
        public
        view
        virtual
        override
        returns (address)
    {
        return proxyRegistryAddress;
    }

    function setProxyRegistryAddress(address newProxyRegistryAddress)
        external
        onlyTimelock
    {
        require(newProxyRegistryAddress != address(0), "Empty address");
        proxyRegistryAddress = newProxyRegistryAddress;
        emit SetProxyRegistry(newProxyRegistryAddress, block.timestamp);
    }

    function setPrice(uint256 value) external onlyTimelock {
        price = value;
    }

    function setNewTranche(
        bytes32 merkleRoot,
        uint256 newPrice,
        uint256 newAmount,
        uint256 newMaxClaimed
    ) external onlyTimelock {
        require(newMaxClaimed > 0, "Invalid value");
        maxClaimed = newMaxClaimed;
        giftMerkleRoot = merkleRoot;
        price = newPrice;
        remainingAmount = mintableAmount = newAmount;
        emit SetNewTranche(merkleRoot, newPrice, newAmount, newMaxClaimed, block.timestamp);
    }

    function _create(address _to) internal returns (uint256 _tokenId) {
        tokenIdCount.increment();
        _tokenId = tokenIdCount.current();
        _mint(_to, _tokenId);

        CellData.Cell memory _newCell = CellData.Cell({
            tokenId: _tokenId,
            user: _to,
            class: CellData.Class.INIT,
            stage: 0,
            nextEvolutionBlock: 0,
            variant: 0,
            onSale: false,
            price: 0
        });
        _addMetaCell(_newCell);
        _setTokenRoyalty(_tokenId, msg.sender, feeNumerator);
    }

    function create(address to)
        external
        override
        isOperator
        returns (uint256 tokenId)
    {
        return _create(to);
    }

    function createMultiple(address to, uint256 amount) external isOperator {
        for (uint i = 0; i < amount; i++) {
            _create(to);
        }
    }

    function mint(address to)
        external
        payable
        isOperator
        returns (uint256 tokenId)
    {
        require(msg.value == price, "Invalid price");
        return _create(to);
    }

    function mintForGift(
        address to,
        bytes32[] calldata merkleProof
    )
        external
        payable
        isValidMerkleProof(merkleProof, giftMerkleRoot)
        nonReentrant
        whenNotPaused
    {
        require(msg.value == price, "Invalid price");
        require(remainingAmount >= 1, "Sold out");
        remainingAmount--;
        _create(to);
        uint256 tokenId = tokenIdCount.current();
        emit MintForGift(msg.sender, to, tokenId, block.timestamp);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(isCanTransfer == true, "Can not transfer at this time");
        CellData.Cell memory cell = _getMetaCell(tokenId);
        _removeMetaCell(from, tokenId);
        super._transfer(from, to, tokenId);
        cell.user = to;
        _addMetaCell(cell);
    }

    function _burn(uint256 tokenId) internal override {
        CellData.Cell memory cell = _getMetaCell(tokenId);
        require(cell.onSale == false, "MetaCell is on sale");
        _removeMetaCell(msg.sender, tokenId);
        super._burn(tokenId);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ACellRepository)
        returns (address)
    {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function addMetaCell(CellData.Cell memory _cell)
        external
        override
        isOperator
    {
        _addMetaCell(_cell);
    }

    function removeMetaCell(uint256 _tokenId, address _owner)
        external
        override
        isOperator
    {
        _removeMetaCell(_owner, _tokenId);
    }

    function updateMetaCell(CellData.Cell memory _cell, address _owner)
        external
        override
        isOperator
    {
        _updateMetaCell(_cell, _owner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setBaseTokenURI(string memory uri) external onlyTimelock {
        baseTokenURI = uri;
        emit SetBaseTokenURI(uri, block.timestamp);
    }

    function setContractURI(string memory uri) external onlyTimelock {
        contractURI = uri;
        emit SetContractURI(uri, block.timestamp);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function withdrawETH(address payable to) external onlyTimelock {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }

    function setFeeNumerator(uint96 value) external onlyTimelock {
        feeNumerator = value;
    }

    function setIsCanTransfer(bool value) external onlyTimelock {
        isCanTransfer = value;
    }
}