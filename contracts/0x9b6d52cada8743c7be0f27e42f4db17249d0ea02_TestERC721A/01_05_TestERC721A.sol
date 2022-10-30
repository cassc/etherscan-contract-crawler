// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestERC721A is ERC721A, Ownable {
    SaleState saleState = SaleState.CLOSED;
    
    enum SaleState {
        CLOSED,
        OPEN,
        PRESALE
    }

    constructor() ERC721A("TestERC721A", "TESTERC721") {}

    function mint(uint256 quantity) external payable {
        require(saleState == SaleState.OPEN);
        _mint(msg.sender, quantity);
    }

    function open() external onlyOwner {
        saleState = SaleState.OPEN;
    }

    function setSaleState(uint8 _state) external onlyOwner {
        saleState = SaleState(_state);
    }

}