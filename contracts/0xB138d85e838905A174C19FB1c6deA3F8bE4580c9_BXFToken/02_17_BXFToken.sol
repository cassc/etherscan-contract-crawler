// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Company.sol";
import "./Staking.sol";
import "./Founder.sol";
import "./Sale.sol";
import "./DirectBonus.sol";
import "./Emergency.sol";


contract BXFToken is Staking, Company, Sale, DirectBonus, Emergency {

    using SafeMath for uint256;

    event BXFBuy(address indexed account, uint256 ethereumInvested, uint256 taxedEthereum, uint256 tokensMinted);
    event BXFSell(address indexed account, uint256 tokenBurned, uint256 ethereumGot);
    event BXFReinvestment(address indexed account, uint256 ethereumReinvested, uint256 tokensMinted);
    event Withdraw(address indexed account, uint256 ethereumWithdrawn);
    event Transfer(address indexed from, address indexed to, uint256 value);


    constructor(string memory name, string memory symbol) StandardToken(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    fallback() external payable {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BXFToken: you're not allowed to do this");
    }


    function buy() public payable isRegistered(msg.sender) {
        (uint256 taxedEthereum, uint256 amountOfTokens) = purchaseTokens(msg.sender, msg.value);

        emit Transfer(address(0), msg.sender, amountOfTokens);
        emit BXFBuy(msg.sender, msg.value, taxedEthereum, amountOfTokens);
    }


    function sell(uint256 amountOfTokens) public isRegistered(msg.sender) hasEnoughBalance(amountOfTokens) {
        address account = msg.sender;

        decreaseTotalSupply(amountOfTokens);
        decreaseBalanceOf(account, amountOfTokens);

        if (isFounder(account)) dropFounderOnSell(account);

        uint256 taxedEthereum = processStakingOnSell(account, amountOfTokens);

        msg.sender.transfer(taxedEthereum);

        emit Transfer(account, address(0), amountOfTokens);
        emit BXFSell(account, amountOfTokens, taxedEthereum);
    }


    function withdraw(uint256 amountToWithdraw) public isRegistered(msg.sender) hasEnoughAvailableEther(amountToWithdraw) {
        require(amountToWithdraw <= address(this).balance, "BXFToken: insufficient contract balance");

        address account = msg.sender;
        addWithdrawnAmountTo(account, amountToWithdraw);
        msg.sender.transfer(amountToWithdraw);

        emit Withdraw(account, amountToWithdraw);
    }


    function reinvest(uint256 amountToReinvest) public isRegistered(msg.sender) hasEnoughAvailableEther(amountToReinvest) {
        address account = msg.sender;

        addReinvestedAmountTo(account, amountToReinvest);
        (uint256 taxedEthereum, uint256 amountOfTokens) = purchaseTokens(account, amountToReinvest);

        emit Transfer(address(0), account, amountOfTokens);
        emit BXFReinvestment(account, amountToReinvest, amountOfTokens);
    }


    function exit() public isRegistered(msg.sender) {
        address account = msg.sender;
        if (balanceOf(account) > 0) {
            sell(balanceOf(account));
        }
        if (totalBonusOf(account) > 0) {
            withdraw(totalBonusOf(account));
        }
    }


    function transfer(address recipient, uint256 amount) public override hasEnoughBalance(amount) returns(bool) {
        address sender = msg.sender;

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 stakingFee = calculateStakingFee(amount);
        uint256 taxedTokens = SafeMath.sub(amount, stakingFee);

        decreaseTotalSupply(stakingFee);

        decreaseBalanceOf(sender, amount);
        increaseBalanceOf(recipient, taxedTokens);

        processDistributionOnTransfer(sender, amount, recipient, taxedTokens);

        emit Transfer(sender, address(0), stakingFee);
        emit Transfer(sender, recipient, taxedTokens);
        return true;
    }


    function purchaseTokens(address senderAccount, uint256 amountOfEthereum) internal canInvest(amountOfEthereum) returns(uint256, uint256) {
        uint256 taxedEthereum = amountOfEthereum;

        uint256 companyFee = calculateCompanyFee(amountOfEthereum);
        uint256 directBonus = calculateDirectBonus(amountOfEthereum);
        uint256 stakingFee = calculateStakingFee(amountOfEthereum);

        taxedEthereum = taxedEthereum.sub(companyFee);
        increaseCompanyBalance(companyFee);

        address account = senderAccount;
        address sponsor = sponsorOf(account);
        increaseSelfBuyOf(account, amountOfEthereum);


        if (sponsor == address(this)) {
            increaseCompanyBalance(directBonus);
            taxedEthereum = taxedEthereum.sub(directBonus);
        } else if (isEligibleForDirectBonus(sponsor)) {
            addDirectBonusTo(sponsor, directBonus);
            taxedEthereum = taxedEthereum.sub(directBonus);
        }

        taxedEthereum = taxedEthereum.sub(stakingFee);

        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);

        processStakingOnBuy(senderAccount, amountOfTokens, stakingFee);
        increaseBalanceOf(senderAccount, amountOfTokens);

        return (taxedEthereum, amountOfTokens);
    }
}