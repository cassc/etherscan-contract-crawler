// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IAuctionHouse.sol";
import "./ISplitMain.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

/// @dev Pass this contract as the curator of an auction
contract JPGAuctionProxy {
    /// @dev Eth mainnet deployment of Zora's auction house
    IAuctionHouse constant auctionHouse =
        IAuctionHouse(0xE468cE99444174Bd3bBBEd09209577d25D1ad673);

    address immutable splitter;

    address public owner;

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    /// @dev Splitter is the already deployed split contract for
    /// the two parties that are splitting the commission
    constructor(address _splitter) {
        splitter = _splitter;

        owner = msg.sender;
    }

    /// @dev Allows the owner to start an auction of which this contract is the curator
    function setAuctionApproval(uint256 auctionId, bool approved)
        public
        onlyOwner
    {
        auctionHouse.setAuctionApproval(auctionId, approved);
    }

    /// @dev Forwards ETH directly to the splitter contract. The Zora contract will unwrap the eth for us and send
    /// it here. If for whatever reason that failed, we will have WETH in this contract (unfailable), so we add
    /// an emergency function to deal with that.
    receive() external payable {
        SafeTransferLib.safeTransferETH(splitter, address(this).balance);
    }

    /// @dev If zora's `endAuction` failed to send ETH here (or the splits contract rejected it and we failed to forward it), it winds up
    /// as WETH in this contract. If this happened, let the owner transfer it at their will. As well as if for whatever reason this contract
    /// received other ERC20 tokens.
    function emergencyERC20Withdraw(address token, address recipient)
        public
        onlyOwner
    {
        SafeTransferLib.safeTransfer(
            ERC20(token), recipient, ERC20(token).balanceOf(address(this))
        );
    }
}