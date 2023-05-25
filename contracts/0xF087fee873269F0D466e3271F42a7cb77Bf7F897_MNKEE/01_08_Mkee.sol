// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MNKEE is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => bool) private pair;
    mapping(address => bool) isBlacklisted;
    mapping(address => bool) private whitelistedContracts;

    bool private starting;
    bool private disableContractWhitelist;

    uint256 public maxWalletTimer;
    uint256 public maxWallet;
    uint256 public start;

    constructor(uint256 _maxWalletTimer, address _mkeeCEXWallet) ERC20("MNKEE", "MNKEE") {

        uint256 _totalSupply = 42069 * (10 ** 10) * (10 ** decimals());

        starting = true;
        maxWallet = _totalSupply;
        maxWalletTimer = block.timestamp.add(_maxWalletTimer);

        _mint(msg.sender, ((_totalSupply * 8669) / 10000));
        _mint(_mkeeCEXWallet, ((_totalSupply * 1331) / 10000));

        whitelistedContracts[address(this)] = true;
        whitelistedContracts[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true;
        whitelistedContracts[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
        whitelistedContracts[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true;
        whitelistedContracts[0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B] = true;
    }

    function isContract(address account) public view returns (bool) {
        return account.isContract();
    }

    function setWhitelistedContract(address contractAddress, bool whitelisted) external onlyOwner {
        whitelistedContracts[contractAddress] = whitelisted;
    }

    function _disableContractWhitelist(bool disable) external onlyOwner {
        disableContractWhitelist = disable;
    }

    function addPair(address toPair) public onlyOwner {
        require(!pair[toPair], "This pair is already excluded");

        pair[toPair] = true;
        starting = false;
        maxWallet = ((totalSupply() * 96) / 10000);
        start = block.timestamp;
    }

    function addToBlacklist(address toBlacklist) external onlyOwner {
        require(!isBlacklisted[toBlacklist]);

        isBlacklisted[toBlacklist] = true;
    }

    function addToBlacklistBulk(address[] calldata toBlacklist) external onlyOwner {
        require(toBlacklist.length <= 100, "Max list size 100 addresses");
        for(uint256 i = 0; i < toBlacklist.length; i++) {
            if(isBlacklisted[toBlacklist[i]]){
                return;
            } else {
                isBlacklisted[toBlacklist[i]] = true;
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0),"ERC20: transfer to the zero address");
        require(!isBlacklisted[to] && !isBlacklisted[from], "FORBIDDEN");

        if (disableContractWhitelist && block.timestamp < maxWalletTimer && isContract(from) && !whitelistedContracts[from]) {
            revert("Contract not whitelisted");
        }

        if (starting) {
            require(to == owner() || from == owner(), "Trading is not yet active");
        }

        if (block.timestamp < maxWalletTimer && from != owner() && to != owner() && pair[from]) {
            uint256 balance = balanceOf(to);
            require(balance.add(amount) <= maxWallet, "Transfer amount exceeds maximum wallet");

            super._transfer(from, to, amount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function burn(uint256 amount) public {
        uint256 scaledAmount = amount * (10 ** decimals());
        _burn(msg.sender, scaledAmount);
    }
}