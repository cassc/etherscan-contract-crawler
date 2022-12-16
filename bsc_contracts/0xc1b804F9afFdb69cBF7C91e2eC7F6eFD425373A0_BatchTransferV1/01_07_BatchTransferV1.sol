// SPDX-License-Identifier: Unidentified
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BatchTransferV1 is Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    enum BatchType {TOKEN, NATIVE}

    Counters.Counter public batchIdCounter;

    uint256 public arrayLimit = 250;

    event BatchTokenTransfer(
        uint256 indexed batchId,
        address indexed to,
        uint256 amount
    );
    event BatchNativeTransfer(
        uint256 indexed batchId,
        address indexed to,
        uint256 amount
    );

    event BatchProcessed(
        uint256 indexed batchID,
        BatchType batchType,
        uint256 totalSent,
        address initiator
    );

    function setArrayLimit(uint256 _newArrayLimit) public onlyOwner {
        require(_newArrayLimit > 0, "INVALID_ARRAY_LIMIT");
        arrayLimit = _newArrayLimit;
    }

    function multisendToken(
        IERC20 token,
        address[] memory _contributors,
        uint256[] memory _amounts
    ) external whenNotPaused nonReentrant {
        require(_contributors.length > 0, "RECIPIENT_LIST_EMPTY");
        require(_contributors.length == _amounts.length, "MUST_MATCH_LENGTH");
        require(_contributors.length <= arrayLimit, "EXCEEDS_MAX_BATCH_SIZE");

        uint256 batchID = _generateBatchID();
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            token.transferFrom(msg.sender, _contributors[i], _amounts[i]);
            emit BatchTokenTransfer(batchID, _contributors[i], _amounts[i]);
        }

        emit BatchProcessed(
            batchID,
            BatchType.TOKEN,
            _contributors.length,
            msg.sender
        );
    }

    function multisendNative(
        address[] memory _contributors,
        uint256[] memory _amounts
    ) external payable whenNotPaused nonReentrant {
        uint256 total = msg.value;

        require(_contributors.length > 0, "RECIPIENT_LIST_EMPTY");
        require(_contributors.length == _amounts.length, "MUST_MATCH_LENGTH");
        require(_contributors.length <= arrayLimit, "EXCEEDS_MAX_BATCH_SIZE");

        require(
            total >= _totalAmountToSend(_amounts),
            "INSUFFICIENT_AMOUNT_RECEIVED"
        );

        uint256 batchID = _generateBatchID();
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _amounts[i], "INSUFFICIENT_BALANCE");
            total = total - _amounts[i];
            (bool success, ) = payable(_contributors[i]).call{
                value: _amounts[i]
            }("");
            require(success, "Transfer failed.");

            emit BatchNativeTransfer(batchID, _contributors[i], _amounts[i]);
        }

        emit BatchProcessed(
            batchID,
            BatchType.NATIVE,
            _contributors.length,
            msg.sender
        );
    }

    function _totalAmountToSend(uint256[] memory _amounts)
        private
        pure
        returns (uint256)
    {
        uint256 i = 0;
        uint256 totalAmount = 0;

        for (i; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        return totalAmount;
    }

    function _generateBatchID() private returns (uint256) {
        batchIdCounter.increment();
        return batchIdCounter.current();
    }

    function withdrawAllNative() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function withdrawAllTokens(IERC20 _token) public onlyOwner nonReentrant {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        _token.transfer(owner(), balance);
    }
}