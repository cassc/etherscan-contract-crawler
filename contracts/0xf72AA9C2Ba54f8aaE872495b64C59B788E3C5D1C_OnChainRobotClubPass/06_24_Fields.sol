pragma solidity 0.8.15;
// SPDX-License-Identifier: MIT

import "./IORCPassRender.sol";

error IdNotValid();
error ETHTransferFailed();
error PASSTransferPaused();

contract Fields {
    /**
        @dev Emitted when somebody mints a PASS to a given address
    */
    event Minted(
        address indexed minter,
        address indexed to,
        uint256 passID // TODO add more things here
    );
    /**
        @dev Emitted when metadata renderer contract change is blocked
    */
    event RendererChangeBlockedForever(address indexed sender);
    /**
        @dev Emitted when the minting has been started
    */
    event MintingStarted(uint256 mintingStartingTime);
    /**
        @dev Emitted the renderer contract changes
    */
    event RendererContractChanged(
        address oldRendererContract,
        address newRendererContract,
        uint256 changeTime
    );

    IORCPassRender public render;

    bool public canChangeRenderer = true;

    // the current number of minted tokens
    uint256 public totalSupply;

    uint256 internal MAX_TOKENS_PER_TRANSACTION = 3;

    uint256 internal _mintPrice = 0.02 ether;

    uint256 internal mintStartTime;
}