// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";

abstract contract Defii is IDefii {
    address public owner;
    address public factory;

    /// @notice Sets owner and factory addresses. Could run only once, called by factory.
    /// @param owner_ Owner (for ACL and transfers out)
    /// @param factory_ For validation and info about executor
    function init(address owner_, address factory_) external {
        require(owner == address(0), "Already initialized");
        owner = owner_;
        factory = factory_;
    }

    //////
    // owner functions
    //////

    /// @notice Enters to DEFI instrument. Could run only by owner.
    function enter() external onlyOwner {
        _enter();
    }

    /// @notice Runs custom transaction. Could run only by owner.
    /// @param target Address
    /// @param value Transaction value (e.g. 1 AVAX)
    /// @param data Enocded function call
    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) public onlyOwner {
        (bool success, ) = target.call{value: value}(data);
        require(success, "runTx failed");
    }

    /// @notice Runs custom multiple transactions. Could run only by owner.
    /// @param targets List of address
    /// @param values List of transactions value (e.g. 1 AVAX)
    /// @param datas List of enocded function calls
    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external onlyOwner {
        require(
            targets.length == values.length,
            "targets and values length not match"
        );
        require(
            targets.length == datas.length,
            "targets and datas length not match"
        );

        for (uint256 i = 0; i < targets.length; i++) {
            runTx(targets[i], values[i], datas[i]);
        }
    }

    //////
    // owner and executor functions
    //////

    /// @notice Exit from DEFI instrument. Could run by owner or executor. Don't withdraw funds to owner account.
    function exit() external onlyOnwerOrExecutor {
        _exit();
    }

    /// @notice Exit from DEFI instrument. Could run by owner or executor.
    function exitAndWithdraw() public onlyOnwerOrExecutor {
        _exit();
        _withdrawFunds();
    }

    /// @notice Claim rewards and withdraw to owner.
    function harvest() external onlyOnwerOrExecutor {
        _harvest();
    }

    /// @notice Claim rewards, sell it and and withdraw to owner.
    /// @param params Encoded params (use encodeParams function for it)
    function harvestWithParams(bytes memory params)
        external
        onlyOnwerOrExecutor
    {
        _harvestWithParams(params);
    }

    /// @notice Withdraw funds to owner (some hardcoded assets, which uses in instrument).
    function withdrawFunds() external onlyOnwerOrExecutor {
        _withdrawFunds();
    }

    /// @notice Withdraw ERC20 to owner
    /// @param token ERC20 address
    function withdrawERC20(IERC20 token) public onlyOnwerOrExecutor {
        _withdrawERC20(token);
    }

    /// @notice Withdraw native token to owner (e.g ETH, AVAX, ...)
    function withdrawETH() public onlyOnwerOrExecutor {
        _withdrawETH();
    }

    receive() external payable {}

    //////
    // internal functions - common logic
    //////

    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.transfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    //////
    // internal functions - defii specific logic
    //////

    function _enter() internal virtual;

    function _exit() internal virtual;

    function _harvest() internal virtual {
        revert("Use harvestWithParams");
    }

    function _withdrawFunds() internal virtual;

    function _harvestWithParams(bytes memory params) internal virtual {
        revert("Run harvest");
    }

    //////
    // modifiers
    //////

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOnwerOrExecutor() {
        require(
            msg.sender == owner ||
                msg.sender == IDefiiFactory(factory).executor(),
            "Only owner or executor"
        );
        _;
    }
}