// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./BaseRfiTokenUpgradeable.sol";
import "./LiquifierUpgradeable.sol";

contract WineConnectToken is Initializable, BaseRfiTokenUpgradeable, LiquifierUpgradeable, UUPSUpgradeable, PausableUpgradeable {

    using SafeMathUpgradeable for uint256;

    mapping (address => bool) private blacklist;

    function initialize(string memory name_, string memory symbol_, address marketingAdr_, address eventAddr_) public initializer {
        __BaseRfiToken_init(name_, symbol_, marketingAdr_, eventAddr_);
        __Liquifier_init(TOTAL_SUPPLY, NUMBER_OF_TOKENS_TO_SWAP_TO_LIQUIDITY);
        __UUPSUpgradeable_init();
        __Pausable_init();

        _exclude(_pair);
        _exclude(BURN_ADDRESS);
    }

    function _isV2Pair(address account) internal view override returns(bool){
        return (account == _pair);
    }

    function _beforeTokenTransfer(address sender, address recipient, bool takeFee) internal override {
        require(!paused(), "Token is paused");
        require(!isBlacklisted(sender), "Sender is blacklisted");
        require(!isBlacklisted(tx.origin), "Sender is blacklisted");
        require(!isBlacklisted(recipient), "Recipient is blacklisted");

        if (takeFee && !_isV2Pair(sender))
            liquify(sender);
    }

    function _takeTransactionFees(bool isBuy, uint256 amount, uint256 currentRate) internal override {
        uint256 feesCount = isBuy ? _getBuyFeesCount() : _getSellFeesCount();
    
        for (uint256 index = 0; index < feesCount; index++ ) {
            (FeeType name, uint256 value,) = isBuy ? _getBuyFee(index) : _getSellFee(index);

            if ( value == 0 )
                continue;

            if (name == FeeType.Rfi)
                _redistribute(amount, currentRate, value);
            else 
            {
                uint256 tAmount = _takeFee(amount, currentRate, value, address(this));

                if ( name == FeeType.Marketing )
                    marketingTokens += tAmount;
                else if ( name == FeeType.Event )
                    eventTokens += tAmount;
                else 
                    liquidityTokens += tAmount;
            }
        }
    }

    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient) private returns(uint256) {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);

        if (_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        return tAmount;
    }

    function _approveDelegate(address owner, address spender, uint256 amount) internal override {
        _approve(owner, spender, amount);
    }

    function _transferLiquifiedEventETH(uint256 amount) internal override {
        eventWallet.call{value: amount}("");
    }

    function _transferLiquifiedMarketingETH(uint256 amount) internal override {
        marketingWallet.call{value: amount}("");
    }

    function _transferRemainingLiquifiedTokens(uint256 tAmount) internal override {
        _transfer(address(this), marketingWallet, tAmount);
    }

    function pause() public onlyOwner {
        require(!paused(), "Contract is already paused");
        _pause();
    }

    function enableBlacklist(address account) public onlyOwner {
        require(!isBlacklisted(account), "Account is already blacklisted");
        blacklist[account] = true;
    }

    function disableBlacklist(address account) public onlyOwner {
        require(isBlacklisted(account), "Account is not blacklisted");
        blacklist[account] = false;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }

    function unpause() public onlyOwner {
        require(paused(), "Contract is not paused");
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}