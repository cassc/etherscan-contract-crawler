// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CosmosSwap is Ownable {
    using SafeERC20 for IERC20;

    event TokenWhitelisted(
        string indexed destinationChain,
        address indexed token,
        bool indexed whitelist
    );
    event OperatorUpdated(address indexed operator);
    event SwapInitialized(
        uint256 indexed id,
        SourceInfo srcInfo,
        DestInfo destInfo
    );
    event SwapStatusUpdated(uint256 indexed id, Status status);

    enum Status {
        Initialized,
        Pending,
        Completed
    }

    struct SourceInfo {
        address token;
        uint256 amount;
    }

    struct DestInfo {
        string chain;
        string token;
    }

    struct SwapInfo {
        SourceInfo srcInfo;
        DestInfo destInfo;
        Status status;
    }

    mapping(string => mapping(address => bool)) public whitelistedTokens;

    SwapInfo[] public swapInfos;

    address public operator;

    modifier onlyOperator() {
        require(msg.sender == operator, "not operator");
        _;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;

        emit OperatorUpdated(_operator);
    }

    function whitelistToken(
        string memory destChain,
        address token,
        bool whitelist
    ) external onlyOwner {
        whitelistedTokens[destChain][token] = whitelist;

        emit TokenWhitelisted(destChain, token, whitelist);
    }

    function swap(SourceInfo calldata srcInfo, DestInfo calldata destInfo)
        external
    {
        require(
            whitelistedTokens[destInfo.chain][srcInfo.token],
            "not available"
        );
        // TODO: set minimum amount for bridge fee
        require(srcInfo.amount != 0, "invalid amount");

        IERC20(srcInfo.token).safeTransferFrom(
            msg.sender,
            address(this),
            srcInfo.amount
        );

        uint256 id = swapInfos.length;

        swapInfos.push(
            SwapInfo({
                srcInfo: srcInfo,
                destInfo: destInfo,
                status: Status.Initialized
            })
        );

        emit SwapInitialized(id, srcInfo, destInfo);
    }

    function withdrawToDepositor(uint256 id, address axelarDepositor)
        external
        onlyOperator
    {
        require(id < swapInfos.length, "invalid id");
        require(axelarDepositor != address(0), "invalid depositor");

        SwapInfo memory info = swapInfos[id];

        require(info.status == Status.Initialized, "invalid status");

        IERC20(info.srcInfo.token).safeTransfer(
            axelarDepositor,
            info.srcInfo.amount
        );

        _updateStatus(id, Status.Pending);
    }

    function completeSwap(uint256 id) external onlyOperator {
        require(swapInfos[id].status == Status.Pending, "invalid status");
        _updateStatus(id, Status.Completed);
    }

    function _updateStatus(uint256 id, Status status) internal {
        swapInfos[id].status = status;
        emit SwapStatusUpdated(id, status);
    }
}