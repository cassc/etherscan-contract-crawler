// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'erc721a/contracts/interfaces/IERC721A.sol';

contract GRAVE is IERC721Receiver, AccessControl {

    bytes32 TLE_ROLE = keccak256('TLE_ROLE');

    constructor(address _baseNft) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TLE_ROLE, DEFAULT_ADMIN_ROLE);
        allowedNFTAddress = _baseNft;
    }
    address allowedNFTAddress;

    mapping(address => uint256) receivedNFTValue;
    mapping(address => uint256) mintedNFTValue;
    uint256 totalReceivedAmount;
    uint256 totalMintedNFTAmount;

    address burnAddress = 0x000000000000000000000000000000000000dEaD;

    function onERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override returns(bytes4) {
        require(msg.sender == allowedNFTAddress);
        receivedNFTValue[from]++;
        totalReceivedAmount++;
        IERC721A token = IERC721A(msg.sender);
        token.safeTransferFrom(address(this), burnAddress, tokenId);
        return this.onERC721Received.selector;
    }

    function changeMintedValue(address _holder) public onlyRole(TLE_ROLE) {
        mintedNFTValue[_holder]++;
        totalMintedNFTAmount++;
    }

    function checkTotalReceivedAmount() public view returns(uint256) {
        return totalReceivedAmount;
    }

    function checkTotalMintedNFTAmount() public view returns(uint256) {
        return totalMintedNFTAmount;
    }

    function checkRecievedNFTValue(address _holder) public view returns(uint256) {
        return receivedNFTValue[_holder];
    }

    function checkMintedNFTValue(address _holder) public view returns(uint256) {
        return mintedNFTValue[_holder];
    }
}