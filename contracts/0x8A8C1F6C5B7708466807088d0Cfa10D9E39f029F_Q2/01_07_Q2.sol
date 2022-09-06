// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ITransferController.sol";

contract Q2 is ERC20 {
    /**
     * @dev Emitted when the everyoneAccept status is  changed by owner
     * a call to {changeEveryoneAccept}. `status` is the new status.
     */
    event ChangeEveryoneAccept(bool status);

 /**
     * @dev Emitted when the controller status is  changed by from `oldAddress` to `newAddress`
     * a call to {changeControllerAddress}. `status` is the new status.
     */
    event ChangeControllerAddress(address oldAddress, address newAddress);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        super._mint(msg.sender, 15000000000 * (10**18));
    }

    /**
     * @dev Controller to limit transfer q2 within whitelist address
     */
    ITransferController public transferController =
        ITransferController(0x99f2b1D5350D9Db28F8a7f4aeB08aB76bC7F9942);

    bool public everyoneAccept = false;

    function changeEveryoneAccept(bool everyoneTransfer) public onlyOwner {
        everyoneAccept = everyoneTransfer;

        emit ChangeEveryoneAccept(everyoneAccept);
    }

    function changeControllerAddress(address _contollerAddress)
        public
        onlyOwner
    {
        address oldControllerAddress = address(transferController);
        transferController = ITransferController(_contollerAddress);
        emit ChangeControllerAddress(oldControllerAddress,_contollerAddress);
    }

    /**
     * @dev to check whether given address is wallet address of contract address
     */
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * Transfer tokens
     * Note Q2 can be transfered to only whitelisted address only if everyoneAccept if false
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        require(
            transferController.isWhiteListed(_to) ||
                isContract(_to) ||
                everyoneAccept,
            "Receiver address is not whitelisted, Please whitelist yourself at: https://invest.poq.gg/whitelist/"
        );

        return super.transfer(_to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Note Q2 can be transfered to only whitelisted address only if everyoneAccept if false
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        require(
            transferController.isWhiteListed(_to) ||
                isContract(_to) ||
                everyoneAccept,
            "Receiver address is not whitelisted, Please whitelist yourself at: https://invest.poq.gg/whitelist/"
        );
        return super.transferFrom(_from, _to, _value);
    }
}