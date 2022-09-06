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
 * @title CryptoDadsStake
 * @author @ScottMitchell18
 */
contract CryptoDadsStake is FxBaseRootTunnel, Ownable {
    address public dadAddress;
    address public momAddress;
    bool public stakingPaused;

    /// @dev Users' staked tokens mapped from their address
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public staked;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _dadAddress,
        address _momAddress
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        dadAddress = _dadAddress;
        momAddress = _momAddress;
    }

    /**
     * Stakes the given token ids, provided the contract is approved to move them.
     * @param dadIds - the dad token ids to stake
     * @param momIds - the mom token ids to stake
     */
    function stake(uint256[] calldata dadIds, uint256[] calldata momIds)
        external
    {
        require(!stakingPaused, "Staking paused");
        require(
            dadIds.length > 0 || momIds.length > 0,
            "Staking requires at least 1 token"
        );
        // Dads
        if (dadIds.length > 0) {
            IERC721Enumerable contractInstance = IERC721Enumerable(dadAddress);
            for (uint256 i; i < dadIds.length; i++) {
                contractInstance.transferFrom(
                    msg.sender,
                    address(this),
                    dadIds[i]
                );
                staked[dadAddress][msg.sender][dadIds[i]] = true;
            }
        }
        // Moms
        if (momIds.length > 0) {
            IERC721Enumerable contractInstance = IERC721Enumerable(momAddress);
            for (uint256 j; j < momIds.length; j++) {
                contractInstance.transferFrom(
                    msg.sender,
                    address(this),
                    momIds[j]
                );
                staked[momAddress][msg.sender][momIds[j]] = true;
            }
        }
        // Emit sync to child chain
        _sendChildMessage(msg.sender, dadIds, momIds, true);
    }

    /**
     * Unstakes the given token ids.
     * @param dadIds - the dad token ids to unstake
     * @param momIds - the mom token ids to unstake
     */
    function unstake(uint256[] calldata dadIds, uint256[] calldata momIds)
        external
    {
        require(
            dadIds.length > 0 || momIds.length > 0,
            "Unstaking requires at least 1 token"
        );
        // Dads
        if (dadIds.length > 0) {
            IERC721Enumerable contractInstance = IERC721Enumerable(dadAddress);
            for (uint256 i; i < dadIds.length; i++) {
                require(staked[dadAddress][msg.sender][dadIds[i]], "Not owned");
                contractInstance.transferFrom(
                    address(this),
                    msg.sender,
                    dadIds[i]
                );
                staked[dadAddress][msg.sender][dadIds[i]] = false;
            }
        }

        // Moms
        if (momIds.length > 0) {
            IERC721Enumerable contractInstance = IERC721Enumerable(momAddress);
            for (uint256 i; i < momIds.length; i++) {
                require(staked[momAddress][msg.sender][momIds[i]], "Not owned");
                contractInstance.transferFrom(
                    address(this),
                    msg.sender,
                    momIds[i]
                );
                staked[momAddress][msg.sender][momIds[i]] = false;
            }
        }

        // Emit sync to child chain
        _sendChildMessage(msg.sender, dadIds, momIds, false);
    }

    /**
     * @dev Set active state of staking protocol
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
     * @param dadIds - the dad tokenIds staked/unstaked
     * @param momIds - the mom tokenIds staked/unstaked
     * @param isInbound - true if staking, false if unstaking
     */
    function _sendChildMessage(
        address from,
        uint256[] calldata dadIds,
        uint256[] calldata momIds,
        bool isInbound
    ) internal {
        _sendMessageToChild(abi.encode(from, dadIds, momIds, isInbound));
    }

    function _processMessageFromChild(bytes memory) internal override {}
}