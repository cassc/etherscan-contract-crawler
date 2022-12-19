//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./permission/ContractRestricted.sol";
import "./interfaces/IEarlyMintersRoyalties.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./permission/Reciver.sol";

contract EarlyMintersRoyalties is ContractRestricted, Reciver, ReentrancyGuard, IEarlyMintersRoyalties {
    using Counters for Counters.Counter;

    mapping(address => uint256[]) private adopterTokens;
    mapping(uint256 => address) private tokenAdopter;
    mapping(uint256 => uint256) private periodRoyalty;
    mapping(uint256 => uint256) private periodUnaryAmount;
    mapping(address => Counters.Counter) private lastWithrawPeriod;
    mapping(address => History[]) private historyWithdrawForPeriod;
    mapping(address => mapping(uint256 => Counters.Counter)) private numMintsForAddressAndPeriod;
    mapping(address => uint256) private numMintsInlastWithrawPeriod;
    uint256 private depositSinceLastClose;

    Counters.Counter private currentTotalMinters;

    Counters.Counter private currentPeriod;
    bool private suspended = false;

    constructor(address accessContract, address reciver) ContractRestricted(accessContract) Reciver(reciver) {}

    function setEarlyMinter(address minter, uint256 tokenId)
        public override
        onlyContract
    {
        if(adopterTokens[minter].length == 0){
            lastWithrawPeriod[minter] = Counters.Counter(currentPeriod.current());
        }
        adopterTokens[minter].push(tokenId);
        tokenAdopter[tokenId] = minter;
        currentTotalMinters.increment();
        numMintsForAddressAndPeriod[minter][currentPeriod.current()].increment();

        emit EarlyMinterSet(minter, tokenId);
    }

    function getEarlyMinter(uint256 tokenId) public override view returns (address) {
        return tokenAdopter[tokenId];
    }

    function getNumMintsByMinter(address minter)
        public
        override
        view
        returns (uint256)
    {
        return adopterTokens[minter].length;
    }

    function getNumMintsForWithrawPeriod(address minter) private returns (uint256) {
        uint256 numMintForPeriod = 0;

        if(numMintsForAddressAndPeriod[minter][lastWithrawPeriod[minter].current()].current() > 0){
            numMintForPeriod = numMintsForAddressAndPeriod[minter][lastWithrawPeriod[minter].current()].current();
            numMintsInlastWithrawPeriod[minter] += numMintForPeriod;
        }else{
            numMintForPeriod = numMintsInlastWithrawPeriod[minter];
        }
        return numMintForPeriod;
    }

    function getBalance() public override view returns (uint256) {
        return address(this).balance;
    }

    function getCurrentPeriod() public override view returns (uint256) {
        return currentPeriod.current();
    }

    function getCurrentPeriodBalance() public override view returns (uint256) {
        return depositSinceLastClose;
    }

    function getPeriodBalance(uint256 period) public override view returns (uint256) {
        return periodRoyalty[period];
    }

    function getLastPeriodBalanceUnitaryAmount() public override view returns (uint256) {
        return periodUnaryAmount[currentPeriod.current() - 1];
    }

    function getHistoryWithdrawForPeriod(address minter) public override view returns (History[] memory) {
        return historyWithdrawForPeriod[minter];
    }

    function getPeriodBalanceUnitaryAmount(uint256 period)
        public
        override
        view
        returns (uint256)
    {
        return periodUnaryAmount[period];
    }

    function closePeriod() public override onlyOwner {
        periodRoyalty[currentPeriod.current()] = depositSinceLastClose;
        periodUnaryAmount[currentPeriod.current()] =
            ((depositSinceLastClose * 5000) / 10000) /
            currentTotalMinters.current();

        emit PeriodClosed(
            msg.sender,
            depositSinceLastClose,
            currentTotalMinters.current(),
            periodUnaryAmount[currentPeriod.current()],
            currentPeriod.current()
        );
        depositSinceLastClose = 0;
        currentPeriod.increment();
    }

    function isSuspended() public override view returns (bool) {
        return suspended;
    }

    function suspend() public override onlyOwner {
        suspended = true;
    }

    function activate() public override onlyOwner {
        suspended = false;
    }

    function withdraw() public override{
        require(!isSuspended(), "Payments are suspended by now");
        require(adopterTokens[msg.sender].length > 0, "This address is not a minter");
        require(
            lastWithrawPeriod[msg.sender].current() < currentPeriod.current(),
            "Withdraw is up to date"
        );
        uint32 index = currentPeriod.current() - lastWithrawPeriod[msg.sender].current() > 12 ? 12 : uint32(currentPeriod.current() - lastWithrawPeriod[msg.sender].current());
        uint256 totalRoyaltyAmount = 0;
        for (uint256 i = 0; i < index; i++) {
            if(lastWithrawPeriod[msg.sender].current() == currentPeriod.current()){
                break;
            }
            uint256 numMintForPeriod = getNumMintsForWithrawPeriod(msg.sender);

            uint256 royaltyAmount = getPeriodBalanceUnitaryAmount(
                lastWithrawPeriod[msg.sender].current()
            ) * numMintForPeriod;

            emit MinterWithdraw(msg.sender, royaltyAmount, lastWithrawPeriod[msg.sender].current());

            historyWithdrawForPeriod[msg.sender].push(History(lastWithrawPeriod[msg.sender].current(), royaltyAmount));
            lastWithrawPeriod[msg.sender].increment();
            totalRoyaltyAmount += royaltyAmount;
        }

        (bool hs, ) = payable(msg.sender).call{value: totalRoyaltyAmount}("");
        require(hs);
    }

    function safeOwnerWithdraw() public override nonReentrant onlyReciver{
        require(
            lastWithrawPeriod[msg.sender].current() < currentPeriod.current(),
            "Withdraw is up to date"
        );
        uint256 amount = (periodRoyalty[
            lastWithrawPeriod[msg.sender].current()
        ] * 5000) / 10000;
        historyWithdrawForPeriod[msg.sender].push(History(lastWithrawPeriod[msg.sender].current(), amount));
        lastWithrawPeriod[msg.sender].increment();
        (bool hs, ) = payable(reciver()).call{value: amount}("");
        require(hs);
    }

    receive() external override payable {
        depositSinceLastClose += msg.value;
    }
}