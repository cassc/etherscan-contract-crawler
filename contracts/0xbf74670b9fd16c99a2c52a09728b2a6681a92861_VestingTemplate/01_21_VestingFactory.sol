// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";

contract VestingTemplate is VestingWalletUpgradeable, Multicall
{
    VestingFactory public immutable registry = VestingFactory(msg.sender);
    uint64         private          _cliff;

    constructor() initializer() {}

    function initialize(uint64 startTimestamp, uint64 cliffDuration, uint64 vestingDuration)
        external
        initializer()
    {
        __VestingWallet_init(address(1), startTimestamp, vestingDuration);
        _cliff = startTimestamp + cliffDuration;
    }

    // Mimick ownable interface
    modifier onlyOwner() {
        require(owner() == msg.sender, "RegistryOwnable: caller is not the owner");
        _;
    }

    function owner()
        public
        view
        virtual
        returns (address)
    {
        return registry.ownerOf(uint256(uint160((address(this)))));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        registry.transferFrom(owner(), newOwner, uint256(uint160(address(this))));
    }

    // Vesting beneficiary
    function beneficiary()
        public
        view
        virtual
        override
        returns (address)
    {
        return owner();
    }

    function cliff()
        public
        view
        virtual
        returns (uint256)
    {
        return _cliff;
    }

    function releaseable()
        public
        view
        virtual
        returns (uint256)
    {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    function releaseable(address token)
        public
        view
        virtual
        returns (uint256)
    {
        return vestedAmount(token, uint64(block.timestamp)) - released(token);
    }

    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return timestamp < _cliff ? 0 : super._vestingSchedule(totalAllocation, timestamp);
    }

    // Allow delegation of votes
    function delegate(IVotes token, address delegatee)
        public
        virtual
        onlyOwner()
    {
        token.delegate(delegatee);
    }
}

contract VestingFactory is ERC721("Vestings", "Vestings"), Multicall
{
    address public immutable template = address(new VestingTemplate());

    function newVesting(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 cliffDuration,
        uint64 vestingDuration
    )
        external
        returns (address)
    {
        address instance = Clones.clone(template);
        VestingTemplate(payable(instance)).initialize(startTimestamp, cliffDuration, vestingDuration);
        _mint(beneficiaryAddress, uint256(uint160((instance))));
        return instance;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        return uint256(uint160((spender))) == tokenId || super._isApprovedOrOwner(spender, tokenId);
    }
}