// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";

abstract contract Defii is IDefii {
    using SafeERC20 for IERC20;

    address public owner;
    address public incentiveVault;
    address public factory;

    constructor() {
        // prevent usage implementation as defii
        owner = msg.sender;
    }

    // Current version of Defii contract. Each version have some new features.
    // After adding new features to Defii contract, add new version to this comment
    // and increase returned version

    // version 1: just Defii with enter, harvest, exit
    // version 2: Added DefiiFactory.getAllWallets, DefiiFactory.getAllDefiis,
    //            DefiiFactory.getAllAllocations, DefiiFactory.getAllInfos
    // version 3: Added incentiveVault
    // version 4: Added Defii.getBalance and DefiiFactory.getAllBalances
    function version() external pure returns (uint16) {
        return 4;
    }

    /// @notice Sets owner and factory addresses. Could run only once, called by factory.
    /// @param owner_ Owner (for ACL and transfers out)
    /// @param factory_ For validation and info about executor
    /// @param incentiveVault_ Address, that collect all incentive tokens
    function init(
        address owner_,
        address factory_,
        address incentiveVault_
    ) external {
        require(owner == address(0), "Already initialized");
        owner = owner_;
        factory = factory_;
        incentiveVault = incentiveVault_;
        _postInit();
    }

    /// @notice Calculates balances of given tokens. Returns difference of token amount before exit and after exit.
    /// @dev Should marked as view in ABI
    /// @param tokens Owner (for ACL and transfers out)
    /// @return balances Info about token balances
    function getBalance(address[] calldata tokens)
        external
        returns (BalanceItem[] memory balances)
    {
        (, bytes memory result) = address(this).call(
            abi.encodeWithSelector(this.getBalanceAndRevert.selector, tokens)
        );
        balances = abi.decode(result, (BalanceItem[]));
    }

    /// @notice Use getBalance. This function always reverts.
    function getBalanceAndRevert(address[] calldata tokens) external {
        BalanceItem[] memory balances = new BalanceItem[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = BalanceItem({
                token: tokens[i],
                decimals: IERC20Metadata(tokens[i]).decimals(),
                balance: IERC20(tokens[i]).balanceOf(address(this)),
                incentiveVaultBalance: IERC20(tokens[i]).balanceOf(
                    incentiveVault
                )
            });
        }

        if (hasAllocation()) {
            _exit();
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balanceAfter = IERC20(tokens[i]).balanceOf(address(this));
            uint256 incentiveVaultBalanceAfter = IERC20(tokens[i]).balanceOf(
                incentiveVault
            );
            if (balanceAfter > balances[i].balance) {
                balances[i].balance = balanceAfter - balances[i].balance;
            } else {
                balances[i].balance = 0;
            }
            if (
                incentiveVaultBalanceAfter > balances[i].incentiveVaultBalance
            ) {
                balances[i].incentiveVaultBalance =
                    incentiveVaultBalanceAfter -
                    balances[i].incentiveVaultBalance;
            } else {
                balances[i].incentiveVaultBalance = 0;
            }
        }

        bytes memory returnData = abi.encode(balances);
        uint256 returnDataLength = returnData.length;
        assembly {
            revert(add(returnData, 0x20), returnDataLength)
        }
    }

    //////
    // owner functions
    //////

    /// @notice Change address of incentive vault.
    /// @param incentiveVault_ New incentive vault address
    function changeIncentiveVault(address incentiveVault_) external onlyOwner {
        incentiveVault = incentiveVault_;
    }

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
    function exitAndWithdraw() external onlyOnwerOrExecutor {
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

    function hasAllocation() public view virtual returns (bool);

    //////
    // internal functions - common logic
    //////

    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.safeTransfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    function _claimIncentive(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.safeTransfer(incentiveVault, tokenAmount);
        }
    }

    //////
    // internal functions - defii specific logic
    //////

    function _postInit() internal virtual {}

    function _enter() internal virtual;

    function _exit() internal virtual;

    function _harvest() internal virtual {
        revert("Use harvestWithParams");
    }

    function _withdrawFunds() internal virtual;

    function _harvestWithParams(bytes memory) internal virtual {
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