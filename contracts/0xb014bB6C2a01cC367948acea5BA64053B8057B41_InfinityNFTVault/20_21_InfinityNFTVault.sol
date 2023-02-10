// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./Withdrawable.sol";

contract InfinityNFTVault is Withdrawable, Ownable {
    struct Deposit {
        address owner;
        address collection;
        uint256 tokenId;
        uint256 createdAt;
        uint256 unlockedAt;
        bool withdrawn;
    }

    uint256 public depositSerialId;

    uint256 public minDepositTime = 1 days;

    mapping(address => bool) public collections;

    mapping(uint256 => Deposit) public deposits;

    mapping(address => mapping(uint256 => uint256)) public depositByCollectionAndTokenId;

    event Deposited(uint256 id, address indexed owner, address collection, uint256 indexed tokenId, uint256 timestamp, uint256 unlockTimestamp);

    event Withdrawal(uint256 id, address indexed to, address collection, uint256 indexed tokenId, uint256 timestamp);

    modifier protectedWithdrawal() override {
        _checkOwner();
        _;
    }

    modifier isSupportedCollection(address collection) {
        require(collections[collection], "InfinityNFTVault: collection is not supported");
        _;
    }

    /* Configuration
     ****************************************************************/

    function setMinDepositTime(uint256 period) external onlyOwner {
        minDepositTime = period;
    }

    function enableCollection(address collection) external onlyOwner {
        collections[collection] = true;
    }

    function disableCollection(address collection) external onlyOwner {
        collections[collection] = false;
    }

    /* Domain
     ****************************************************************/

    function deposit(uint256 tokenId, address collection) external isSupportedCollection(collection) {
        uint256 _depositSerialId = depositByCollectionAndTokenId[collection][tokenId];

        require(_depositSerialId == 0 || deposits[_depositSerialId].withdrawn, "InfinityNFTVault: token is already deposited");

        uint256 _unlockTimestamp = block.timestamp + minDepositTime;

        deposits[++depositSerialId] = Deposit({
            owner: _msgSender(),
            collection: collection,
            tokenId: tokenId,
            createdAt: block.timestamp,
            unlockedAt: _unlockTimestamp,
            withdrawn: false
        });

        depositByCollectionAndTokenId[collection][tokenId] = depositSerialId;

        IERC721(collection).safeTransferFrom(_msgSender(), address(this), tokenId);

        emit Deposited(depositSerialId, _msgSender(), collection, tokenId, block.timestamp, _unlockTimestamp);
    }

    function withdraw(uint256 tokenId, address collection) external isSupportedCollection(collection) {
        address _sender = _msgSender();
        uint256 _depositSerialId = depositByCollectionAndTokenId[collection][tokenId];
        Deposit memory _currentDeposit = deposits[_depositSerialId];

        require(_currentDeposit.owner == _sender, "InfinityNFTVault: deposit owner mismatch");

        require(_currentDeposit.unlockedAt < block.timestamp, "InfinityNFTVault: deposit is locked");

        require(_currentDeposit.withdrawn == false, "InfinityNFTVault: deposit already withdrawn");

        deposits[_depositSerialId].withdrawn = true;

        IERC721(collection).safeTransferFrom(address(this), _sender, tokenId);

        emit Withdrawal(_depositSerialId, _sender, collection, tokenId, block.timestamp);
    }

    function getDeposit(address collection, uint256 tokenId) public view returns (Deposit memory) {
        return deposits[depositByCollectionAndTokenId[collection][tokenId]];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}