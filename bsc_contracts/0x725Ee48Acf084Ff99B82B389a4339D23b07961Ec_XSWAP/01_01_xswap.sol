// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract XSWAP {
    address public owner;
    address public constant tokenAddress =
        0x971ae2E700ba405EfFe7e055e0853955aBb1C621;

    address public constant depositToken =
        0xC81F26C1aa51E75c9Def1A9FA951245A9cD7ad66;

    uint256 public baseTokenUint = 1 ether;
    uint256 public swapPrice = 1 ether;
    uint256 public withdrawDuration = 24 days;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public withdrawAt;
    mapping(address => uint256) public withdrawAmount;

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setWithdrawDuration(uint256 duration) external onlyOwner {
        withdrawDuration = duration;
    }

    function withdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        TransferHelper.safeTransfer(token_, to_, amount_);
    }

    function deposit(uint256 amount_) external {
        TransferHelper.safeTransferFrom(
            depositToken,
            msg.sender,
            address(this),
            amount_
        );

        uint256 tokenAmount = (amount_ * baseTokenUint) / swapPrice;
        balances[msg.sender] += tokenAmount;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, tokenAmount);
    }

    function withdraw(uint256 amount_) external {
        require(balances[msg.sender] >= amount_, "insufficient balance");
        balances[msg.sender] -= amount_;
        withdrawAt[msg.sender] = block.timestamp;
        TransferHelper.safeTransferFrom(
            tokenAddress,
            msg.sender,
            address(this),
            amount_
        );
        withdrawAmount[msg.sender] += amount_;
    }

    function cancelWithdraw(uint256 amount_) external {
        require(withdrawAmount[msg.sender] >= amount_, "insufficient balance");
        withdrawAmount[msg.sender] -= amount_;
        balances[msg.sender] += amount_;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, amount_);
    }

    function confirmWithdraw() external {
        require(withdrawAmount[msg.sender] > 0, "insufficient balance");
        require(
            withdrawAt[msg.sender] + withdrawDuration < block.timestamp,
            "too early"
        );

        uint256 amount_ = withdrawAmount[msg.sender];
        withdrawAmount[msg.sender] = 0;
        uint256 swapAmount = (amount_ * swapPrice) / baseTokenUint;
        TransferHelper.safeTransfer(depositToken, msg.sender, swapAmount);
    }
}