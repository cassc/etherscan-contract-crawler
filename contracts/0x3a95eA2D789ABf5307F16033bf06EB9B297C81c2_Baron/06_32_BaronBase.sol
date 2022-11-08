// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ENSAware.sol";

abstract contract BaronBase is ENSAware, Pausable, Ownable {
    // This is the address that is payed payments etc.
    // default = owner() (see setTreasury)
    address payable public treasury;

    // This is the address that can perform select admin methods on the contract.
    // default = owner() (see setOperator)
    address public operator;

    // Throws if called by any account other than the operator.
    modifier onlyOperator() {
        require(operator == _msgSender(), "caller is not the operator");
        _;
    }

    constructor() {
        // The owner / creator of the contract is the default treasury.
        treasury = payable(_msgSender());
        // The owner / creator of the contract is the default operator.
        operator = _msgSender();
    }

    // This lets the operator control the canonical reverse ENS name of this contract.
    function claimReverseENS() external onlyOperator {
        _claimReverseENS(operator);
    }

    // This allows the operator to withdraw any received ERC20 tokens to the treasury.
    function withdrawTokens(IERC20 token) external onlyOperator {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(treasury, balance);
    }

    // This allows the operator to withdraw any received ERC721 tokens to the treasury.
    function withdrawNFTs(IERC721 token, uint256 tokenId)
        external
        onlyOperator
    {
        token.transferFrom(address(this), treasury, tokenId);
    }

    // This allows the operator to pause the contract.
    function pause() external onlyOperator {
        _pause();
    }

    // This allows the operator to resume the contract.
    function resume() external onlyOperator {
        _unpause();
    }

    // This allows the owner to change the treasury.
    function setTreasury(address payable newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    // This allows the owner to change the operator.
    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
    }

    // Visible for testing (ENS has a fixed location on public networks).
    function setEns(address ens) external onlyOwner {
        _setENS(ens);
    }
}