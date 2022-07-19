// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EIP712, IVotes, Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";

import {IGaugeVoterV2} from "./interfaces/IGaugeVoterV2.sol";
import {INFTLocker} from "./interfaces/INFTLocker.sol";
import {IRegistry, INFTStaker} from "./interfaces/INFTStaker.sol";

/**
 * This contract stakes an NFT and captures it's voting power. It is an extension
 * of openzepplin's Votes contract that also allows delegration.
 *
 * All benefits such as voting, protocol fees, rewards, special access etc.. accure
 * to NFT stakers.
 *
 * When you stake your NFT, your voting power is locked in and stops decreasing over time.
 *
 * TODO: Ensure we limit the amount of delegation power a wallet can have.
 *
 * @author Steven Enamakel <[email protected]>
 */
contract MAHAXStaker is ReentrancyGuard, Ownable, Votes, INFTStaker {
    IRegistry public immutable override registry;

    uint256 public totalWeight; // total voting weight
    bool public disableAttachmentCheck; // check attachments when unstaking

    mapping(uint256 => uint256) public stakedBalancesNFT; // nft => pool => votes
    mapping(address => uint256) public stakedBalances; // nft => pool => votes

    constructor(address _registry) EIP712("MAHAXStaker", "1") {
        registry = IRegistry(_registry);
    }

    function stake(uint256 _tokenId) external override {
        INFTLocker locker = INFTLocker(registry.locker());
        require(
            locker.isApprovedOrOwner(msg.sender, _tokenId),
            "not token owner"
        );
        _stake(_tokenId);
    }

    function unstake(uint256 _tokenId) external override {
        INFTLocker locker = INFTLocker(registry.locker());

        // check if the nfts have been used in a gauge
        if (!disableAttachmentCheck) {
            IGaugeVoterV2 gaugeVoter = IGaugeVoterV2(registry.gaugeVoter());
            require(
                gaugeVoter.attachments(locker.ownerOf(_tokenId)) == 0,
                "attached"
            );
        }

        require(
            locker.isApprovedOrOwner(msg.sender, _tokenId),
            "not token owner"
        );
        _unstake(_tokenId);
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account)
        public
        view
        virtual
        override(IVotes, Votes)
        returns (address)
    {
        if (super.delegates(account) == address(0)) return account;
        return super.delegates(account);
    }

    function _stakeFromLock(uint256 _tokenId) external override {
        require(msg.sender == registry.locker(), "not locker");
        _stake(_tokenId);
    }

    function _stake(uint256 _tokenId) internal {
        registry.ensureNotPaused();

        INFTLocker locker = INFTLocker(registry.locker());
        require(stakedBalancesNFT[_tokenId] == 0, "already staked");

        address _owner = locker.ownerOf(_tokenId);

        uint256 _weight = locker.balanceOfNFT(_tokenId);
        _transferVotingUnits(address(0), _owner, _weight);

        stakedBalancesNFT[_tokenId] = _weight;
        stakedBalances[_owner] += _weight;
        totalWeight += _weight;

        emit StakeNFT(msg.sender, _owner, _tokenId, _weight);
    }

    function _unstake(uint256 _tokenId) internal {
        INFTLocker locker = INFTLocker(registry.locker());
        address _owner = locker.ownerOf(_tokenId);

        require(stakedBalancesNFT[_tokenId] > 0, "not staked");
        IGaugeVoterV2(registry.gaugeVoter()).resetFor(_owner);

        uint256 _weight = stakedBalancesNFT[_tokenId];
        _transferVotingUnits(_owner, address(0), _weight);

        stakedBalancesNFT[_tokenId] = 0;
        stakedBalances[_owner] -= _weight;
        totalWeight -= _weight;

        emit UnstakeNFT(msg.sender, _owner, _tokenId, _weight);
    }

    function updateStake(uint256 _tokenId) external override {
        registry.ensureNotPaused();

        INFTLocker locker = INFTLocker(registry.locker());
        address _owner = locker.ownerOf(_tokenId);
        require(
            locker.isApprovedOrOwner(msg.sender, _tokenId),
            "not token owner"
        );

        // reset gauge votes
        IGaugeVoterV2(registry.gaugeVoter()).resetFor(_owner);

        uint256 _oldWeight = stakedBalancesNFT[_tokenId];
        uint256 _newWeight = locker.balanceOfNFT(_tokenId);

        stakedBalancesNFT[_tokenId] = _newWeight;
        stakedBalances[_owner] =
            (stakedBalances[_owner] + _newWeight) -
            _oldWeight;
        totalWeight = (totalWeight + _newWeight) - _oldWeight;

        _transferVotingUnits(_owner, address(0), _oldWeight);
        _transferVotingUnits(address(0), _owner, _newWeight);

        emit RestakeNFT(msg.sender, _owner, _tokenId, _oldWeight, _newWeight);
    }

    function banFromStake(uint256 _tokenId) external onlyOwner {
        _unstake(_tokenId);
    }

    function toggleAttachmentCheck() external onlyOwner {
        disableAttachmentCheck = !disableAttachmentCheck;
    }

    function _getVotingUnits(address who)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return stakedBalances[who];
    }

    function getStakedBalance(address who)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return stakedBalances[who];
    }

    function isStaked(uint256 tokenId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return stakedBalancesNFT[tokenId] > 0;
    }
}