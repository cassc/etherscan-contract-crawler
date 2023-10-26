/**
 *Submitted for verification at Etherscan.io on 2023-10-12
*/

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: ManualForwarder/ERC20Interface.sol


pragma solidity ^0.8.0;

/**
 * Contract that exposes the needed erc20 token functions
 */

abstract contract ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value)
    public
    virtual
    returns (bool success);

  // Get the account balance of another account with address _owner
  function balanceOf(address _owner)
    public
    virtual
    view
    returns (uint256 balance);
}

// File: ManualForwarder/Forwarder.sol



 pragma solidity ^0.8.19;



 contract Forwarder {
    address private parentAddress;
    address private owner;

    event ForwarderDeposited(address from, uint256 value, bytes data);

    function initialize(address _owner, address initAddress) public onlyUninitialized {
        require(initAddress != address(0), "Invalid parent address");
        require(_owner != address(0), "Invalid owner address");
        owner = _owner;
        parentAddress = initAddress;
    }

    modifier onlyUninitialized {
        require(parentAddress == address(0x0), "Already initialized");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    function getParentAddress() public view onlyOwner returns (address) {
        return parentAddress;
    }

    function getOwner() public view onlyOwner returns (address) {
        return owner;
    }

    fallback() external payable {
        flush();
    }

    receive() external payable {
        flush();
    }

    function setParentAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Invalid parent address");
        parentAddress = newAddress;
    }

    function flush() private {
        uint256 value = payable(address(this)).balance;

        if (value == 0) {
            return;
        }

        (bool success, ) = parentAddress.call{ value: value }("");
        require(success, "Flush failed");
        emit ForwarderDeposited(msg.sender, value, msg.data);
    }

    function getERC20Balance(
        address tokenContractAddress
    ) public view returns (uint256) {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        address forwarderAddress = address(this);
        uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
        if (forwarderBalance == 0) {
            return 0;
        }
        return forwarderBalance;
    }

    function flushTokens(address tokenContractAddress) external onlyOwner {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        address forwarderAddress = address(this);
        uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
        if (forwarderBalance == 0) {
            return;
        }

        TransferHelper.safeTransfer(
            tokenContractAddress,
            parentAddress,
            forwarderBalance
        );
    }
}