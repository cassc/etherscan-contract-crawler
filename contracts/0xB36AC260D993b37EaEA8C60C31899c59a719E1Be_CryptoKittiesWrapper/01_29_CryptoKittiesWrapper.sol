// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/INftWrapper.sol";
import "../interfaces/ICryptoKitties.sol";
import "../airdrop/AirdropAcceptor.sol";

contract CryptoKittiesWrapper is INftWrapper {
    function transferNFT(
        address _sender,
        address _recipient,
        address _nftContract,
        uint256 _nftId
    ) external override returns (bool) {
        if (_sender == address(this)) {
            ICryptoKitties(_nftContract).transfer(_recipient, _nftId);
        } else {
            ICryptoKitties(_nftContract).transferFrom(_sender, _recipient, _nftId);
        }

        return true;
    }

    function isOwner(
        address _owner,
        address _nftContract,
        uint256 _tokenId
    ) external view override returns (bool) {
        return ICryptoKitties(_nftContract).ownerOf(_tokenId) == _owner;
    }

    function wrapAirdropAcceptor(
        address _recipient,
        address _nftContract,
        uint256 _nftId,
        address _beneficiary
    ) external override returns (bool) {
        ICryptoKitties(_nftContract).approve(_recipient, _nftId);

        AirdropAcceptor(_recipient).wrap(address(this), _beneficiary, _nftContract, _nftId);

        return true;
    }
}