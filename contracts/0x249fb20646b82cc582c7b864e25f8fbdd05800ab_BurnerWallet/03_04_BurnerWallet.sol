// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.13;

import "src/SampleERC721ConsecutiveTransfer.sol";

contract BurnerWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function mintTestNFT() external {
        // 0x5996Fcd62C7fE41c338d503C42D12a2D71968310 is an existing ERC721ConsecutiveMock contract.
        ERC721ConsecutiveMock nft_contract = ERC721ConsecutiveMock(0x5996Fcd62C7fE41c338d503C42D12a2D71968310);

        // To simulate the above line when testing locally:
        // ERC721ConsecutiveMock nft_contract = new ERC721ConsecutiveMock();
        // ERC721ConsecutiveMock nft_contract2 = ERC721ConsecutiveMock(address(nft_contract));
        // nft_contract2.mint(1);

        nft_contract.mint(1);
    }
}