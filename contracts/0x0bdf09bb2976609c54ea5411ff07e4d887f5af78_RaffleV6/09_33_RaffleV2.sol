//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Raffle.sol";

contract RaffleV2 is Raffle, ReentrancyGuardUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;

    bool public claimLive;
    bool public stakeLive;
    bool public unstakeLive;

    event WinnerChosen(uint256 tokenId, address owner, uint256 prizeNumber);
    event NftSet(address oldNFT, address newNFT);
    event Staked(address owner, uint256 id);
    event UnStaked(address owner, uint256 id);

    function initializeV2() public reinitializer(2) {
        __ReentrancyGuard_init();
    }

    function setStakeLive(bool _stakeLive) external onlyOwner {
        stakeLive = _stakeLive;
    }

    function setUnStakeLive(bool _unstakeLive) external onlyOwner {
        unstakeLive = _unstakeLive;
    }

    function setClaimLive(bool _claimLive) external onlyOwner {
        claimLive = _claimLive;
    }

    function stake(uint256[] calldata ids)
        external
        nonReentrant
        whenNotPaused
    {
        require(!claimLive, "Claim is live");
        require(stakeLive, "Stake is not live");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 current = ids[i];
            _tokenToOwner[current] = msg.sender;
            _tokens.add(current);
            nft.safeTransferFrom(msg.sender, address(this), current);
            emit Staked(msg.sender, current);
        }
        totalSupply += ids.length;
    }

    function unstake(uint256[] calldata ids)
        external
        nonReentrant
        whenNotPaused
    {
        require(!claimLive, "Claim is live");
        require(unstakeLive, "UnStake is not live");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 current = ids[i];
            require(_tokenToOwner[current] == msg.sender, "Not Owner");
            delete _tokenToOwner[current];
            _tokens.remove(current);
            nft.safeTransferFrom(address(this), msg.sender, current);
            emit UnStaked(msg.sender, current);
        }
        totalSupply -= ids.length;
    }

    function raffleSamePrize(uint256 numberOfWinners) external onlyOwner {
        for (uint256 i = 0; i < numberOfWinners; i++) {
            uint256 index = _random(i);
            uint256 id = _tokens.at(index);
            address winner = _tokenToOwner[id];
            emit WinnerChosen(id, winner, currentPrizeNumber);
        }
        currentPrizeNumber++;
    }

    function raffleDifferentPrizes(uint256 numberOfWinners) external onlyOwner {
        for (uint256 i = 0; i < numberOfWinners; i++) {
            uint256 index = _random(i);
            uint256 id = _tokens.at(index);
            address winner = _tokenToOwner[id];
            emit WinnerChosen(id, winner, currentPrizeNumber);
            currentPrizeNumber++;
        }
    }

    function _random(uint256 salt) internal view returns (uint256) {
        return randomizer.random(salt, _tokens.length());
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function tokenToOwner(uint256 id) public view returns (address) {
        return _tokenToOwner[id];
    }

    function released(uint256 id) public view returns (uint256) {
        return _released[id];
    }

    function _pendingPayment(uint256 totalReceived, uint256 alreadyReleased)
        internal
        view
        returns (uint256)
    {
        uint256 share = totalReceived / totalSupply;
        if (alreadyReleased >= share) return 0;
        return share - alreadyReleased;
    }

    function _release(uint256[] calldata ids, bool doRevert) internal {
        uint256 total;
        uint256 totalReceived = address(this).balance + totalReleased();

        for (uint256 i; i < ids.length; i++) {
            uint256 current = ids[i];
            require(tokenToOwner(current) == msg.sender, "Not owner");
            uint256 payment = _pendingPayment(totalReceived, released(current));

            _released[current] += payment;
            _totalReleased += payment;
            total += payment;
        }
        if (doRevert) {
            require(total > 0, "tokens do not have enough for payment");
            payable(msg.sender).transfer(total);
        } else {
            if (total > 0) payable(msg.sender).transfer(total);
        }
    }

    function release(uint256[] calldata ids)
        external
        virtual
        whenNotPaused
        nonReentrant
    {
        require(claimLive, "Claim not live");
        _release(ids, true);
    }

    function expectedRelease(uint256[] calldata ids)
        public
        view
        returns (uint256)
    {
        uint256 total;
        uint256 totalReceived = address(this).balance + totalReleased();

        for (uint256 i; i < ids.length; i++) {
            uint256 current = ids[i];
            total += _pendingPayment(totalReceived, released(current));
        }

        return total;
    }

    function setNFT(IERC721 _nft) external onlyOwner {
        IERC721 oldNFT = nft;
        nft = _nft;
        emit NftSet(address(oldNFT), address(_nft));
    }

    function setRandomizer(IRandom _randomizer) external onlyOwner {
        randomizer = _randomizer;
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        totalSupply = _totalSupply;
    }

    receive() external payable virtual {}
}