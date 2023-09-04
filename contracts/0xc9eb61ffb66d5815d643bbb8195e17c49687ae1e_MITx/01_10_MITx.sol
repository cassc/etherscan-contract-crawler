// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeERC20, IERC20, Address} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Capped, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MITx is ERC20Capped, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public immutable MAX_SUPPLY;

    constructor(
        uint256 maxSupply,
        address tokenOwner,
        address[] memory accounts,
        uint256[] memory amounts,
        string memory name,
        string memory symbol
    ) ERC20Capped(maxSupply) ERC20(name, symbol) {
        //  Only need to check `tokenOwner` must be NOT 0x00
        //  ERC20Capped already check `maxSupply` must be non-zero
        require(tokenOwner != address(0), "Set 0x00 as Owner");

        //  set a max number of MITx-V2 Token
        MAX_SUPPLY = maxSupply;

        //  check `accounts` and `amounts` length are matched before minting initialized amounts
        //  Wouldn't check sum of `amounts` and MAX_SUPPLY. It could be checked off-chain instead
        uint256 len = accounts.length;
        require(amounts.length == len, "Length mismatch");
        for (uint256 i; i < len; i++) _mint(accounts[i], amounts[i]);

        //  Ownable() set `msg.sender` as Owner by default
        //  Setting non-sender as `owner` is available in the version v5
        //  Thus, must call _transferOwnership() again at this point
        _transferOwnership(tokenOwner);
    }

    /**
        @notice Mint `amount` of MITx-V2 Token to `account`
        @dev  Caller must be Owner

        @param	account            Beneficiary account to receive tokens
        @param	amount             Amount of MITx-V2 Token being minted
        Note: It reverts likely if totalSupply() + amount exceeds MAX_SUPPLY
    */
    function mint(address account, uint256 amount) external onlyOwner {
        //  ERC20.sol checks `account` must be not 0x00
        //  MAX_SUPPLY constraint will be checked by ERC20Capped
        _mint(account, amount);
    }

    /**
        @notice Burn `amount` of MITx-V2 Token from `msg.sender`
        @dev  Caller can be ANY

        @param	amount             Amount of MITx-V2 Token being burnt
        Note: 
        - `msg.sender` burns only his/her current owned balance
    */
    function burn(uint256 amount) external {
        //  ERC20.sol checks `account` must be not 0x00
        //  and `amount` must be less or equal the balance
        _burn(_msgSender(), amount);
    }

    /**
        @notice Emergency transfer `token` to `owner`
        @dev  Caller can be ANY

        @param	token              Address of token contract (Native Coin = 0x00)
        @param	amount             Amount of MITx-V2 Token being burnt
        Note: 
        - This function allows `owner` to withdraw any tokens that mistakenly sent to this contract
        - Two types of token can be withdrawed: Native Coin, and ERC-20
    */
    function emergency(address token, uint256 amount) external {
        address receiver = owner();
        if (token == address(0)) Address.sendValue(payable(receiver), amount);
        else IERC20(token).safeTransfer(receiver, amount);
    }
}