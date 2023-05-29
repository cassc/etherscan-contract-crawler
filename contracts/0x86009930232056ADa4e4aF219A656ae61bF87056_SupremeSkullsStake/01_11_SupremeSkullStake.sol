//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./tunnel/FxBaseRootTunnel.sol";

/**
 * Cross-bridge staking contract via fx-portal
 * Ethereum: source chain
 * Polygon: destination chain
 *
 * @title SupremeSkullsStake
 * @author @ScottMitchell18
 */
contract SupremeSkullsStake is FxBaseRootTunnel, Ownable {
    IERC721Enumerable public nftAddress;
    bool public stakingPaused;

    /**
     * Users' staked tokens mapped from their address
     */
    mapping(address => mapping(uint256 => bool)) public staked;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _nftAddress
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        nftAddress = IERC721Enumerable(_nftAddress);
    }

    /**
     * Stakes the given token ids, provided the contract is approved to move them.
     * @param tokenIds - the token ids to stake
     */
    function stake(uint256[] calldata tokenIds) external {
        require(!stakingPaused, "Staking paused");
        for (uint256 i; i < tokenIds.length; i++) {
            nftAddress.transferFrom(msg.sender, address(this), tokenIds[i]);
            staked[msg.sender][tokenIds[i]] = true;
        }
        _sendChildMessage(msg.sender, tokenIds.length, true);
    }

    /**
     * Unstakes the given token ids.
     * @param tokenIds - the token ids to unstake
     */
    function unstake(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            require(staked[msg.sender][tokenIds[i]], "Not owned");
            nftAddress.transferFrom(address(this), msg.sender, tokenIds[i]);
            staked[msg.sender][tokenIds[i]] = false;
        }
        _sendChildMessage(msg.sender, tokenIds.length, false);
    }

    /**
     * Set active state of staking protocol
     * @param paused - the state's new value.
     */
    function setStakingPaused(bool paused) external onlyOwner {
        stakingPaused = paused;
    }

    /**
     * Set FxChildTunnel
     * @param _fxChildTunnel - the fxChildTunnel address
     */
    function setFxChildTunnel(address _fxChildTunnel)
        public
        override
        onlyOwner
    {
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * Sends message the child contract
     * @param from - the user that staked/unstaked
     * @param count - the number staked/unstaked
     * @param isInbound - true if staking, false if unstaking
     */
    function _sendChildMessage(
        address from,
        uint256 count,
        bool isInbound
    ) internal {
        _sendMessageToChild(abi.encode(from, count, isInbound));
    }

    /**
     * A stub that does nothing. We will not anticipate receiving messages from Polygon,
     * we will only send messages to Polygon via FX-Portal.
     */
    function _processMessageFromChild(bytes memory) internal override {}
}