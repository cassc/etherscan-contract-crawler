// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SaleDrop.sol";
import "../minter/VRFMinter.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract BatchSale is SaleDrop, AccessControlUpgradeable, UUPSUpgradeable {
    struct BatchInfo {
        uint price;
        uint sizeLeft;
        uint expiration;
    }

    event BatchChange(uint indexed newBatch);
    event Sale(
        address indexed buyer,
        uint currentBatch,
        uint price,
        uint requestId
    );

    mapping(uint => BatchInfo) public batchInfo;

    uint public totalBatches;
    uint public totalSize;

    uint constant MAX_INT = type(uint).max;

    uint public currentBatch;
    uint private nftsSold;

    address public feeRecipient;
    VRFMinter public minter;

    function initialize(address _minter, address _feeRecipient) public virtual onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        minter = VRFMinter(_minter);
        feeRecipient = _feeRecipient;
    }

    function _setupBatch(uint _size, uint _expiration, uint _price) internal {
        uint batch = totalBatches++;
        batchInfo[batch] = BatchInfo({
            price: _price,
            expiration: _expiration,
            sizeLeft: _size
        });
        totalSize += _size;
    }

    function checkForBatchChange() internal {
        BatchInfo storage batch = batchInfo[currentBatch];
        if (batch.sizeLeft == 0 || block.timestamp > batch.expiration) {
            changeBatch();
        }
    }

    function changeBatch() internal {
        currentBatch++;
        emit BatchChange(currentBatch);
    }

    // ADMIN FUNCTIONS
    function updateBatch(
        uint _batch,
        uint _price,
        uint _size,
        uint _expiration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _batch >= currentBatch && _batch < totalBatches,
            "Must be a current or future batch index"
        );
        require(_size > 0, "Size must be positive");
        uint oldSize = batchInfo[_batch].sizeLeft;
        batchInfo[_batch] = BatchInfo({
            price: _price,
            expiration: _expiration,
            sizeLeft: _size
        });
        totalSize = totalSize + _size - oldSize;
    }

    function updateFeeRecipient(
        address _feeRecipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRecipient = _feeRecipient;
    }

    function updateMinter(
        address _minter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minter = VRFMinter(_minter);
    }

    // BUY FUNCTION
    function buy() external payable override returns (uint) {
        // checks
        require(!isSoldOut(), "Is sold out");
        uint price = getPrice();
        require(msg.value >= price, "Not enough token sent");
        (bool succeed, ) = feeRecipient.call{value: msg.value}("");
        require(succeed, "Failed to transfer");

        // effects
        uint batch = currentBatch;
        batchInfo[batch].sizeLeft--;
        nftsSold++;
        checkForBatchChange();

        // interactions
        uint requestId = minter.mint(_msgSender());
        emit Sale(_msgSender(), batch, price, requestId);
        return requestId;
    }

    function expireCurrentBatch() external {
        BatchInfo storage batch = batchInfo[currentBatch];
        require(block.timestamp > batch.expiration, "Batch did not expire");
        changeBatch();
    }

    // VIEW FUNCTIONS

    function isSoldOut() public view override returns (bool) {
        return nftsSold >= totalSize || minter.tokensLeft() == 0;
    }

    function getPrice() public view override returns (uint) {
        if (currentBatch < totalBatches) {
            return batchInfo[currentBatch].price;
        } else {
            return MAX_INT;
        }
    }

    function getTotalSold() external view override returns (uint) {
        return nftsSold;
    }

    function getTotalLeft() external view override returns (uint) {
        return totalSize - nftsSold;
    }

    // FALLBACK FUNCTIONS

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool succeed, ) = feeRecipient.call{value: address(this).balance}("");
        require(succeed, "Failed to transfer");
    }

    function withdrawERC20(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 erc20 = IERC20(addr);
        erc20.transfer(feeRecipient, erc20.balanceOf(address(this)));
    }

    // UPGRADE

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}