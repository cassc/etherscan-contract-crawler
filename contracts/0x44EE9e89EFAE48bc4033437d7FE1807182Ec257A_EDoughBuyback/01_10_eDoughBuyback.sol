// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./Buyback.sol";

/**
 * @title Buyback contract specifically callable by the eDOUGH contract
 * @author jordaniza
 */
contract EDoughBuyback is Buyback {
    /* ========== Variables ========== */

    /** @notice the address of the eDOUGH escrow contract */
    address public rewardEscrowContract;

    /* ========== Constructor ========== */

    /**
     * @param _dough address of the DOUGH v2 token
     * @param _tokenOut address of the token dough will be bought with (USDC)
     * @param _tokenOutDecimals decimals for the tokenOut
     * @param _rewardEscrowContract address that will be set above
     */
    constructor(
        IERC20 _dough,
        IERC20 _tokenOut,
        uint8 _tokenOutDecimals,
        address _rewardEscrowContract
    ) Buyback(_dough, _tokenOut, _tokenOutDecimals) {
        rewardEscrowContract = _rewardEscrowContract;
    }

    /* ========== Mutative Functions ========== */

    /**
     * @notice sets or unsets address of the escrow contract
     */
    function setEscrow(address _escrowContractAddress)
        external
        onlyOwner
        whenNotPaused
    {
        rewardEscrowContract = _escrowContractAddress;
        emit SetEscrow(_escrowContractAddress);
    }

    /**
     * @notice overrides the buyback method to prevent calling if not the escrow
     */
    function buyback(uint256 _tokenInQty, address _receiver)
        external
        override
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(rewardEscrowContract != address(0), "Escrow not set");
        require(msg.sender == rewardEscrowContract, "Only escrow");
        return _buyback(_tokenInQty, _receiver);
    }

    /* ========== Events ========== */

    /** @notice emitted when the escrow contract is changed by the owner */
    event SetEscrow(address indexed escrowContract);
}