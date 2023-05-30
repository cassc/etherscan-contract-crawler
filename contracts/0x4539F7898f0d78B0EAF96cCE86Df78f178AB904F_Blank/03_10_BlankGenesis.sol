// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./BlankBase.sol";

contract BlankGenesis is BlankBase {

    /// @notice Free Mint for the devs
    ///         - Only Role Admin (deployer)
    ///         - Can't exceed the genesis supply
    ///         - Can't devMint more than DEV_SUPPLY
    function devMint()
    public
    onlyOwner
    hasSubgroupSupply(DEV_SUPPLY, devMints)
    {
        devMints++;
        _mint(msg.sender);
    }

    /// @notice Free Mint for the project owners
    ///         - After mint has started
    ///         - One mint per address
    ///         - Can't exceed the freeMints supply
    ///         - Caller address must be signed by the Free Mint Approver
    function freeMint(bytes calldata signature)
    public
    mintHasStarted
    canStillMint
    isMintApproved(freeMintApprover, signature)
    hasSubgroupSupply(FREE_SUPPLY, freeMints)
    {
        freeMints++;
        _mint(msg.sender);
    }

    /// @notice Regular Mint for the blanklisted addresses
    ///         - After mint has started
    ///         - One mint per address
    ///         - Can't exceed the Genesis supply minus reserved tokens (free and dev mints)
    ///         - Caller address must be signed by the Blank List Approver
    function blankListMint(bytes calldata signature)
    public
    payable
    mintHasStarted
    canStillMint
    isMintApproved(blankApprover, signature)
    hasTokenSupply(GENESIS_SUPPLY - DEV_SUPPLY - FREE_SUPPLY + devMints + freeMints)
    hasTheRightAmount
    {
        _mint(msg.sender);
    }

    /// @notice Regular Mint for the blanklisted addresses
    ///         - After mint has started
    ///         - One mint per address
    ///         - Can't exceed the Genesis supply minus reserved tokens (free and dev mints)
    ///         - Caller address must be signed by the Reserve List Approver
    function reserveListMint(bytes calldata signature)
    public
    payable
    reserveHasStarted
    canStillMint
    isMintApproved(reserveApprover, signature)
    hasTokenSupply(GENESIS_SUPPLY - DEV_SUPPLY - FREE_SUPPLY + devMints + freeMints)
    hasTheRightAmount
    {
        _mint(msg.sender);
    }

    /// @notice This function will be called by the Gen2 contract to burn 4 32x32 canvases into one 64x64
    ///         All the validation will be made in there (checking that the 4 tokens are in the right spot mainly)
    ///         It will burn the 4 tokens on the Gen2 and mint one here allowing their owner to ascend into genesis
    function burnIntoGenesis(address ascendant)
    public
    onlyGen2Contract
    hasSubgroupSupply(GEN2_SUPPLY, gen2Mints)
    {
        gen2Mints++;
        _mint(ascendant);
    }
}