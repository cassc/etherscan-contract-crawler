//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./IA3SWalletFactory.sol";

import "hardhat/console.sol";

contract A3SWallet is ERC721Holder, ERC1155Holder {
    // Factory Address
    address public immutable factory;

    /**
     * @dev Emitted when succeed use low level call to `contractAddress` with precalculated `payload`
     */
    event GeneralCall(address indexed contractAddress, bytes indexed payload);

    /**
     * @dev Throws if called by any account other than the owner recorded in the factory.
     */
    modifier onlyOwner() {
        require(msg.sender == ownerOf(), "Caller is not owner");
        _;
    }

    constructor(address factoryAddress) {
        factory = factoryAddress;
    }

    receive() external payable {}

    /**
     * @dev Returns the output bytes data from low level call to `contractAddress` with precalculated `payload`
     */
    function generalCall(
        address contractAddress,
        bytes calldata payload,
        uint256 amount
    ) external onlyOwner returns (bytes memory) {
        (bool success, bytes memory returnData) = payable(
            address(contractAddress)
        ).call{value: amount}(payload);

        require(success, "A3SProtocol: General call query failed.");
        return returnData;
    }

    /**
     * @dev Returns the owner of the wallet from WalletFactory.
     */
    function ownerOf() public view returns (address) {
        return IA3SWalletFactory(factory).walletOwnerOf(address(this));
    }
}