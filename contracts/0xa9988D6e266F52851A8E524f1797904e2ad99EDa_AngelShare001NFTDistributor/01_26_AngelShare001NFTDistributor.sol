// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../util/WhiteListV2.sol";
import "../registry/RegistryClient.sol";
import "./INFTCoreWithTransferHistory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@1001-digital/erc721-extensions/contracts/RandomlyAssigned.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AngelShare001NFTDistributor is
    RegistryClient,
    ReentrancyGuard,
    WhiteListV2,
    RandomlyAssigned
{
    event MetaDataHashSet(bytes32 hash, uint256 timestamp);
    event DistributorMintedToken(address indexed to, uint256 indexed startTokId, uint256 quantity);

    address public primaryUser;
    using ECDSA for bytes32;

    struct distributorState {
        bytes32 metadataHash;
        bool paused;
        mapping(uint256 => uint256) mixer;
        mapping(address => uint256) qtyMintedPerAddress;
    }

    struct distributorConf {
        string wlistID;
        string nftCoreID;
        uint256 maxSupply;
    }

    distributorState private distState;
    distributorConf public distConf;

    constructor(
        string memory _wlistID,
        string memory _nftCoreID,
        uint256 _maxSupply,
        address _regAddr
    ) RandomlyAssigned(_maxSupply, 1) {
        distConf = distributorConf(_wlistID, _nftCoreID, _maxSupply);
        // Set registry contract address
        setAddr(_regAddr);
    }

    modifier onlyPrimaryUser() {
        require(primaryUser == msg.sender, "Ownable: caller is not the primary User");
        _;
    }

    function setPrimaryUser(address _newPrimaryUser) external onlySU {
        require(_newPrimaryUser != address(0), "Ownable: new owner is the zero address");
        primaryUser = _newPrimaryUser;
    }

    function setMetadataHash(bytes32 _hash) external onlySU {
        distState.metadataHash = _hash;
        emit MetaDataHashSet(_hash, block.timestamp);
    }

    function getMetadataHash() public view returns (bytes32) {
        return distState.metadataHash;
    }

    function getNFTCoreContract() private view returns (INFTCoreWithTransferHistory) {
        address nftCoreContractAddress = lookupContractAddr(distConf.nftCoreID);
        require(nftCoreContractAddress != address(0), "nftcore contract addr can't be 0");

        return INFTCoreWithTransferHistory(nftCoreContractAddress);
    }

    function _remainingInventory() private view returns (uint256) {
        INFTCoreWithTransferHistory nft = getNFTCoreContract();
        uint256 nextTokenId = nft.getNextTokenId();
        if (distConf.maxSupply >= nextTokenId) {
            return (distConf.maxSupply - nextTokenId) + 1;
        } else {
            return 0;
        }
    }

    function remainingInventory() external view returns (uint256) {
        return _remainingInventory();
    }

    function mintedQty(address _targetAddress) external view returns (uint256) {
        return distState.qtyMintedPerAddress[_targetAddress];
    }

    function setWhiteListID(string memory _whiteListID) external onlySU {
        distConf.wlistID = _whiteListID;
    }

    function mintNft(
        bytes32[] memory _proof,
        string memory _leafSource
    ) external nonReentrant onlyPrimaryUser returns (uint256 tokID) {
        bool authorized;
        address targetAddress;
        uint256 allocatedQty;

        require(!isPaused(), "contract paused");
        require(tx.origin == msg.sender, "caller not allowed");
        require(_remainingInventory() > 0, "out of inventory");

        (authorized, targetAddress, allocatedQty) = verifyAndReturnTargetAddress(distConf.wlistID, _proof, _leafSource);
        require(authorized, "addr not on the whitelist");
        require(targetAddress != address(0), "target addr cannot be 0");
        require(targetAddress.code.length == 0, "cant mint to contract");

        uint256 remainingQty = allocatedQty - distState.qtyMintedPerAddress[targetAddress];

        require(remainingQty > 0, "no qty remains");

        INFTCoreWithTransferHistory nft = getNFTCoreContract();
        uint256 id = nft.mint(targetAddress);
        distState.qtyMintedPerAddress[targetAddress]++;
        distState.mixer[id] = nextToken();

        emit DistributorMintedToken(targetAddress, tokID, 1);
    }

    function getMaxSupply() public view returns (uint256) {
        return distConf.maxSupply;
    }

    /**
     * Puases the mint proccess.
     */
    function pause() external onlySU {
        distState.paused = true;
    }

    /**
     * Unpauses the mint proccess.
     */
    function unpause() external onlySU {
        distState.paused = false;
    }

    /**
     * Returns true if mint is paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return distState.paused;
    }

    function getAssignedIndex(uint256 _tokenId) external view returns (uint256) {
        INFTCoreWithTransferHistory nft = getNFTCoreContract();
        // tokenID expected to start at 1 and consecutively go up to getNextTokenId - 1
        require(_tokenId > 0 && _tokenId < nft.getNextTokenId(), "tokenId out of bounds");
        return distState.mixer[_tokenId];
    }

    function redeem(
        uint256 _tokenId,
        string memory _message,
        uint256 _nonce,
        bytes memory _signature
    ) external onlyPrimaryUser {
        INFTCoreWithTransferHistory nft = getNFTCoreContract();
        address nftOwner = nft.ownerOf(_tokenId);
        bool isNftOwner = verify(nftOwner, _message, _nonce, _signature);
        require(isNftOwner, "validation fail: invalid signature");
        nft.burnToken(_tokenId);
    }

    function _getMessageHash(
        string memory _message,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message, _nonce));
    }

    function getMessageHash(
        string memory _message,
        uint256 _nonce
    ) external pure returns (bytes32) {
        return _getMessageHash(_message, _nonce);
    }

    function verify(
        address _signer,
        string memory _message,
        uint256 _nonce,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 messageHash = _getMessageHash(_message, _nonce);
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        return ethSignedMessageHash.recover(_signature) == _signer;
    }
}