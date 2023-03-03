// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../tokens/TsubasaSBT.sol";
import "../tokens/TsubasaNFT.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract SBTClaim is Context {
    error OnlyOwner();

    TsubasaNFT public immutable nftContract;
    TsubasaSBT public immutable sbtContract;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(address _nftAddress, address _sbtAddress) {
        sbtContract = TsubasaSBT(_sbtAddress);
        nftContract = TsubasaNFT(_nftAddress);
    }

    /**
     * mintSbt
     * @param _tokenId of owned NFT is to be burnt.
     */
    function mintSbt(uint256 _tokenId) public {
        if (nftContract.ownerOf(_tokenId) != _msgSender()) revert OnlyOwner();

        nftContract.burn(_tokenId);
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        sbtContract.mint(_msgSender(), newTokenId);
    }
}