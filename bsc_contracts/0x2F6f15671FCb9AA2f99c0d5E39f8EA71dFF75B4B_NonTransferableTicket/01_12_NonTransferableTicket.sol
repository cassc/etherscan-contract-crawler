// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ticket.sol";

contract NonTransferableTicket is Ticket {

    /// @notice Initializes the Controlled Token with Token Details and the Controller
    /// @param _name The name of the Token
    /// @param _symbol The symbol for the Token
    /// @param _controller Address of the Controller contract for minting & burning
    constructor(string memory _name, string memory _symbol, ITokenController _controller)
        Ticket(_name, _symbol, _controller) 
    {
        
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(from == address(0) || to == address(0), "Ticke not transferable");
    }
}