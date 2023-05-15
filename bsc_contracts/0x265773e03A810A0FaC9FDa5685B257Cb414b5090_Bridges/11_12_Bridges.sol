// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interface/IERC20Burnable.sol";

contract Bridges is Ownable2StepUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private tokens; // tokens which enable cross chain
    EnumerableSet.UintSet private chains; // chain ids which can cross to
    address public minter;

    event MintTo(address token, address to, uint amount, uint sourceChainId, string sourceTxHash);
    event Bridge(address token, address from, address to, uint amount, uint destinationChainId);
    event EnableToken(address token);
    event DisableToken(address token);
    event AddSupportedChain(uint chainId);
    event RemoveSupportedChain(uint chainId);
    event SetMinter(address oldMinter, address newMinter);

    modifier onlyEnabledToken(address token) {
        require(tokens.contains(token), "token was not enable");
        _;
    }

    modifier onlySupportedChain(uint chianId) {
        require(chains.contains(chianId), "chain not support");
        _;
    }

    function initialize(address _minter) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        _setMinter(_minter);
    }

    function getEnabledTokens() public view returns (address[] memory) {
        return tokens.values();
    }

    function getSupportedChains() public view returns (uint[] memory) {
        return chains.values();
    }

    function setMinter(address newMinter) external onlyOwner {
        _setMinter(newMinter);
    }

    function _setMinter(address _minter) private {
        emit SetMinter(minter, _minter);
        minter = _minter;
    }

    function addSupportedChain(uint chainId) external onlyOwner {
        require(!chains.contains(chainId), "chian already supported");
        chains.add(chainId);
        emit AddSupportedChain(chainId);
    }

    function removeSupportedChain(uint chainId) external onlyOwner {
        require(chains.contains(chainId), "chain not supported yet");
        chains.remove(chainId);
        emit RemoveSupportedChain(chainId);
    }

    function enableToken(address token) external onlyOwner {
        require(!tokens.contains(token), "token already was enable");
        tokens.add(token);
        emit EnableToken(token);
    }

    function disableToken(address token) external onlyOwner {
        require(tokens.contains(token), "token was not enable yet");
        tokens.remove(token);
        emit DisableToken(token);
    }

    function bridge(IERC20Burnable token, address recipient, uint amount, uint destinationChainId) external 
        onlySupportedChain(destinationChainId) 
        onlyEnabledToken(address(token)) 
    {
        require(token.allowance(address(msg.sender), address(this)) >= amount, "bridge: approve not enough");
        require(token.balanceOf(address(msg.sender)) >= amount, "bridge: sender token balance not enough");
        token.transferFrom(address(msg.sender), address(this), amount);
        token.burn(amount);
        emit Bridge(address(token), address(msg.sender), recipient, amount, destinationChainId);
    }

    function mintTo(IERC20Burnable token, address to, uint amount, uint sourceChainId, string calldata sourceTxHash) external
         onlyEnabledToken(address(token)) 
    {
        require(address(msg.sender) == minter, "Bridge::mintTo: only minter can call");
        token.mint(to, amount);
        emit MintTo(address(token), to, amount, sourceChainId, sourceTxHash);
    }
}