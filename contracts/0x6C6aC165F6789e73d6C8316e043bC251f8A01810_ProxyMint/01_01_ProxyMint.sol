// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ProxyMint {
    address public constant owner = 0x8085647A0770cCdF414976fB3B6EA168A5C8169a;
    address public constant marketplace = 0xcDA72070E455bb31C7690a170224Ce43623d0B6f;
    address public constant nftContract = 0xd97487ca29ADE95Dad1D0C1c91FE98AD45B637d6;
    function mintNFTs(uint amount, string[] calldata tokenCID) public {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        uint256 Id;
        while ( Id < amount ) {
            (bool success, bytes memory data) = nftContract.delegatecall(
                abi.encodeWithSignature("mintAndApprove(string, address)", tokenCID[Id], marketplace)
            );
            Id++;
        }
    }
}