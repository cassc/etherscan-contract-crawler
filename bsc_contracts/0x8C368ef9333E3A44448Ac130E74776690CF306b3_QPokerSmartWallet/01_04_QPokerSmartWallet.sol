// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ISafeERC20.sol";
import "./Strings.sol";

contract QPokerSmartWallet {
    /**
     * @dev {ERC20Transfers} will be emitted whenever {transferERC20Shares} called.
     */
    event ERC20Transfers(
        address ERC20ContractAddress,
        uint256 totalAmount,
        uint256 masterAccountShare,
        uint256 primaryAccountShare
    );

    /**
     * @dev {EthLog} will be emitted whenever {fallback} or {receive} called.
     */
    event EthLog(uint256 time, uint256 amount);
    //================= Base Immutable Settings ==================
    /**
     * @dev this settings are immutable which means this variables cannot be changed after deployment.
     * @dev https://docs.soliditylang.org/en/v0.8.17/contracts.html?highlight=immutable#immutable
     */
    address public immutable masterAccount;
    address public immutable primaryAccount;
    uint256 public immutable primaryAccountShare;
    uint256 public immutable totalSharePart;

    //================= Base Immutable Settings ==================

    /**
     * @dev Initializes the contract settings(owner and affiliate address).
     */
    constructor(
        address _masterAccount,
        address _primaryAccount,
        uint256 _primaryAccountShare,
        uint256 _totalSharePart
    ) {
        require(_totalSharePart > _primaryAccountShare);
        masterAccount = _masterAccount;
        primaryAccount = _primaryAccount;
        primaryAccountShare = _primaryAccountShare;
        totalSharePart = _totalSharePart;
    }

    fallback() external payable {
        emit EthLog(block.timestamp, msg.value);
    }

    receive() external payable {
        emit EthLog(block.timestamp, msg.value);
    }

    /**
     * @notice returns the share in part of {totalPart},
     *         and the result is for the {primaryAccount} address.
     */
    function checkPrimaryAccountShare() public view returns (string memory) {
        return
            string.concat(
                "Primary account share is (",
                Strings.toString(primaryAccountShare),
                "/",
                Strings.toString(totalSharePart),
                ") of total received tokens."
            );
    }

    /**
     * @notice returns the share in part of {totalPart},
     *         and the result is for the {masterAccount} address.
     */
    function checkMasterAccountShare() public view returns (string memory) {
        return
            string.concat(
                "Master account share is (",
                Strings.toString(totalSharePart - primaryAccountShare),
                "/",
                Strings.toString(totalSharePart),
                ") of total received tokens."
            );
    }

    /**
     * @notice this function handles the safeTransfer specified amount of token
     *  between {this contract} and {to} wallet address.
     * @dev Returns the ERC20 {transfer} function status, if it was 'True'
     *  it means that the transaction succeeded otherwise it will thrown an exception.
     * @param erc20ContractAddress is the address of the ERC20 token.
     * @param to                   is the address of the receiver wallet.
     * @param amount               is the amount of tokens in order to transfer
     *                                from this contract to 'to' wallet.
     */
    function safeERC20TransferFrom(
        address erc20ContractAddress,
        address to,
        uint256 amount
    ) internal {
        (bool success, ) = erc20ContractAddress.call(
            abi.encodeWithSelector(ISafeERC20.transfer.selector, to, amount)
        );

        require(success, "safeERC20Transfer failed.");
    }

    /**
     * @notice ERC20 token balance of an Ethereum account from an ERC20 smart contract.
     * @param contractAddress The address of the ERC20 token smart contract.
     * @return balanceOfAccount is the ERC20 token balance of the account.
     */
    function safeERC20BalanceOf(
        address contractAddress
    ) internal view returns (uint256 balanceOfAccount) {
        // calling the 'balanceOf' function of the ERC20 token contract using the staticcall method.
        (bool success, bytes memory data) = contractAddress.staticcall(
            abi.encodeWithSelector(ISafeERC20.balanceOf.selector, address(this))
        );
        // If the ERC20 contract call is successful, then return the decoded balance value.
        require(success, "erc20 {balanceOf} error.");
        balanceOfAccount = abi.decode(data, (uint256));
    }

    function shareCalculator(
        uint256 totalBalance
    )
        internal
        view
        returns (
            uint256 primaryAccountShareTokens,
            uint256 masterAccountShareTokens
        )
    {
        require(totalBalance > 0, "balance is 0");
        primaryAccountShareTokens =
            (totalBalance * primaryAccountShare) /
            totalSharePart;
        masterAccountShareTokens = totalBalance - primaryAccountShareTokens;
    }

    /**
     * @dev divides the available balance of {erc20ContractAddress} ERC20 Token in the smart contract between {masterAccount} and {primaryAccount}
     */
    function transferERC20Shares(address erc20ContractAddress) public {
        uint256 totalBalance = safeERC20BalanceOf(erc20ContractAddress);
        (
            uint256 primaryAccountShareTokens,
            uint256 masterAccountShareTokens
        ) = shareCalculator(totalBalance);
        safeERC20TransferFrom(
            erc20ContractAddress,
            masterAccount,
            masterAccountShareTokens
        );
        safeERC20TransferFrom(
            erc20ContractAddress,
            primaryAccount,
            primaryAccountShareTokens
        );
        emit ERC20Transfers(
            erc20ContractAddress,
            totalBalance,
            masterAccountShareTokens,
            primaryAccountShareTokens
        );
    }

    /**
     * @notice eth means the main currency of the deployed chain (e.g if this contract deployed on polygon mainnet eth means $Matic token).
     * @dev transfers {amount} of eth to {receiver}
     */
    function transferEth(address receiver, uint256 amount) internal {
        (bool sent, ) = payable(receiver).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev divides the available balance of Eth in the smart contract between {masterAccount} and {primaryAccount}
     */
    function transferEthShares() public payable {
        uint256 totalBalance = payable(address(this)).balance;
        (
            uint256 primaryAccountShareTokens,
            uint256 masterAccountShareTokens
        ) = shareCalculator(totalBalance);
        transferEth(masterAccount, masterAccountShareTokens);
        transferEth(primaryAccount, primaryAccountShareTokens);
        emit ERC20Transfers(
            address(0),
            totalBalance,
            masterAccountShareTokens,
            primaryAccountShareTokens
        );
    }
}
