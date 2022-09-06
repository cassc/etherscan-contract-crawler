// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./NftSwapper.sol";

contract NftSwapperFactory is Ownable {
    address public immutable nftSwapperContract;
    bool public swapPaused;
    uint256 public swapFee = 0.01 ether;
    address constant nftSwapperSafe = payable(0x32d15a580F87D5dabCDF759cfdC4A6401e4488bc);

    using Clones for address;

    event OfferCreated(
        address indexed nftCollection,
        uint256 indexed nftId,
        address pair
    );

    constructor(address _nftSwapperImplementation) {
        nftSwapperContract = _nftSwapperImplementation;
    }

    function setFee(uint256 _swapFee) public onlyOwner {
        swapFee = _swapFee;
    }

    function pauseSwap() public onlyOwner {
        swapPaused = true;
    }

    function resumeSwap() public onlyOwner {
        swapPaused = false;
    }

    function withdrawBalance() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Something went wrong with fee withdrawal");
    }

    receive() external payable {}

    function clone(
        address _nft1,
        uint256 _nft1Id,
        address _nft2,
        uint256 _nft2Id
    ) public payable {
        require(swapPaused == false, "Creating offers is paused at the moment");
        require(msg.value >= swapFee, "Fee too low.");
        NftSwapper cloned = NftSwapper(nftSwapperContract.clone());
        cloned.create(_nft1, _nft1Id, _nft2, _nft2Id, swapFee);
        (bool sent, ) = nftSwapperSafe.call{value: msg.value}("");
        require(sent, "Something went wrong with transferring fee");
        emit OfferCreated(_nft1, _nft1Id, address(cloned));
        emit OfferCreated(_nft2, _nft2Id, address(cloned));
    }
}