// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./BankBase.sol";
import "../interfaces/IPositionsManager.sol";
import "hardhat/console.sol";

contract ERC20Bank is ERC1155("ERC20Bank"), BankBase {
    using SaferERC20 for IERC20;

    struct PoolInfo {
        mapping(address => uint256) userShares;
    }

    mapping(uint256 => PoolInfo) poolInfo;
    mapping(address => uint256) balances;

    constructor(address _positionsManager) BankBase(_positionsManager) {}

    function encodeId(address tokenAddress) public pure returns (uint256) {
        return uint256(uint160(tokenAddress));
    }

    function decodeId(uint256 id) public pure override returns (address, address, uint256) {
        return (address(uint160(id)), address(0), 0);
    }

    function getLPToken(uint256 id) public pure override returns (address tokenAddress) {
        (tokenAddress, , ) = decodeId(id);
    }

    function getIdFromLpToken(address lpToken) external view override returns (bool, uint256) {
        if (lpToken == address(0) || lpToken == IPositionsManager(positionsManager).networkToken())
            return (true, encodeId(lpToken));
        try ERC20(lpToken).name() {} catch {
            return (false, 0);
        }
        try ERC20(lpToken).totalSupply() {} catch {
            return (false, 0);
        }
        try ERC20(lpToken).balanceOf(address(0)) {} catch {
            return (false, 0);
        }
        try ERC20(lpToken).decimals() {} catch {
            return (false, 0);
        }
        return (true, encodeId(lpToken));
    }

    function name() public pure override returns (string memory) {
        return "ERC20 Bank";
    }

    function getPositionTokens(
        uint256 tokenId,
        address userAddress
    ) external view override returns (address[] memory outTokens, uint256[] memory tokenAmounts) {
        (address lpToken, , ) = decodeId(tokenId);
        uint256 amount = balanceOf(userAddress, tokenId);
        outTokens = new address[](1);
        tokenAmounts = new uint256[](1);
        outTokens[0] = lpToken;
        tokenAmounts[0] = amount;
    }

    function mint(
        uint256 tokenId,
        address userAddress,
        address[] memory suppliedTokens,
        uint256[] memory suppliedAmounts
    ) public override onlyAuthorized returns (uint256) {
        PoolInfo storage pool = poolInfo[tokenId];
        pool.userShares[userAddress] += suppliedAmounts[0];
        _mint(userAddress, tokenId, suppliedAmounts[0], "");

        // Sanity check
        if (suppliedTokens[0] != address(0)) {
            require(
                balances[suppliedTokens[0]] + suppliedAmounts[0] <= IERC20(suppliedTokens[0]).balanceOf(address(this)),
                "8"
            );
        } else {
            require(balances[suppliedTokens[0]] + suppliedAmounts[0] <= address(this).balance, "8");
        }
        balances[suppliedTokens[0]] += suppliedAmounts[0];
        return suppliedAmounts[0];
    }

    function burn(
        uint256 tokenId,
        address userAddress,
        uint256 amount,
        address receiver
    ) external override onlyAuthorized returns (address[] memory outTokens, uint256[] memory tokenAmounts) {
        (address lpToken, , ) = decodeId(tokenId);
        PoolInfo storage pool = poolInfo[tokenId];
        pool.userShares[userAddress] -= amount;
        if (lpToken != address(0)) {
            IERC20(lpToken).safeTransfer(receiver, amount);
        } else {
            payable(receiver).transfer(amount);
        }
        _burn(userAddress, tokenId, amount);
        outTokens = new address[](1);
        tokenAmounts = new uint256[](1);
        outTokens[0] = lpToken;
        tokenAmounts[0] = amount;

        // Sanity check
        if (lpToken != address(0)) {
            require(balances[lpToken] - amount <= IERC20(lpToken).balanceOf(address(this)), "8");
        } else {
            require(balances[lpToken] - amount <= address(this).balance, "8");
        }
        balances[lpToken] -= amount;
    }
}