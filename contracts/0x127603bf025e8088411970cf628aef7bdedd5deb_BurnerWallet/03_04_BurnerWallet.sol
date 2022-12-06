// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.13;

import "src/SampleERC721ConsecutiveTransfer.sol";

contract BurnerWallet {
    address payable public owner;
    address public nft_address;

    constructor() {
        nft_address = 0x5996Fcd62C7fE41c338d503C42D12a2D71968310;

        // Uncomment this when testing.
        // ERC721ConsecutiveMock nft_contract = new ERC721ConsecutiveMock();
        // nft_address = address(nft_contract);

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
        ERC721ConsecutiveMock nft_contract = ERC721ConsecutiveMock(nft_address);

        nft_contract.mint(1);
    }

    function transferTestNFT(uint256 _tokenId) external {
        ERC721ConsecutiveMock nft_contract = ERC721ConsecutiveMock(nft_address);
        // Question: why does the etherscan signature of this have an eth field?
        nft_contract.transferFrom(address(this), owner, _tokenId);
    }

    // Todo: the wallet will need to implement this (and use the IERC721Receiver interface just like blockchain/lib/openzeppelin-contracts/contracts/mocks/ERC721ReceiverMock.sol) because of 
    // https://ethereum.stackexchange.com/questions/48796/whats-the-point-of-erc721receiver-sol-and-erc721holder-sol-in-openzeppelins-im
    // And potentially need to implement other things too?
    // function onERC721Received(
    //     address operator,
    //     address from,
    //     uint256 tokenId,
    //     bytes memory data
    // ) public override returns (bytes4) {
    // }
}