// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../../../base/BaseOfferSale.sol";
import "../../../LiqiBRLToken.sol";

contract InputBRLT is BaseOfferSale {
    // A reference to the BRLToken contract
    LiqiBRLToken private brlToken;
    // A reference to the emitter of the offer
    address private aEmitter;

    /**
     * @dev Investment with ERC20 token
     */
    constructor(address _emitter, address _brlTokenContract)
        public
        BaseOfferSale()
    {
        aEmitter = _emitter;
        brlToken = LiqiBRLToken(_brlTokenContract);
    }

    /*
     * @dev Cashouts BRLTs paid to the offer to the emitter
     */
    function cashoutBRLT() public {
        // no unsuccessful sale
        require(bSuccess, "Sale is not successful");

        // check the balance of tokens of this contract
        uint256 nBalance = brlToken.balanceOf(address(this));

        // nothing to execute if the balance is 0
        require(nBalance != 0, "Balance to cashout is 0");

        // transfer all tokens to the emitter account
        brlToken.transfer(aEmitter, nBalance);
    }

    function _finishSale() internal virtual override {
        if (!getSuccess()) {
            // notify the BRLT 
            brlToken.failedSale();
        }
    }

    function _investInput(address _investor, uint256 _amount)
        internal
        virtual
        override
    {
        // call with same args
        brlToken.invest(_investor, _amount);
    }

    /*
     * @dev Returns the address of the input token
     */
    function getTokenAddress() public view returns (address) {
        return address(brlToken);
    }
}