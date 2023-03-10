// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMintable.sol";
import "./utils/Minting.sol";

abstract contract Mintable is Ownable, IMintable {
    // address of the IMX contract
    address public imx;

    /**
     * @param owner_ owner of the contract
     * @param imx_ address of the IMX contract
     */
    constructor(address owner_, address imx_) {
        imx = imx_;
        require(owner_ != address(0), "Owner must not be empty");
        transferOwnership(owner_);
    }

    /**
     * @dev Function to mint the token by the owner or IMX.
     *
     * @param to an address to mint token to
     * @param quantity should always equal to one (hard requirement)
     * @param mintingBlob blob containing the ID of the NFT and its blueprint as `{tokenId}:{blueprint}` string
     */
    function mintFor(
        address to,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override {
        require(msg.sender == imx || msg.sender == owner(), "Mintable: caller not owner or IMX");
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id,) = Minting.split(mintingBlob);
        _mintFor(to, id, " ");
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory blueprint
    ) internal virtual;
}