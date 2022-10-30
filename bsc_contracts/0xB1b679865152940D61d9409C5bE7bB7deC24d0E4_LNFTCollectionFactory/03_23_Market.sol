// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MarketTokenRegistry.sol";

contract Market is MarketTokenRegistry, ReentrancyGuard {
    event UpdatePlatformFee(uint256 pFee);
    event UpdatePlatformFeeRecipient(address pFeeRec);

    address payable internal platformFeeRec;
    address payable internal marketAddress;
    uint256 internal platformFee = 2;
    uint256 private maxRoyalty = 10;

    bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    mapping(address => mapping(uint256 => address)) internal minters;
    mapping(address => mapping(uint256 => uint256)) internal royalties;

    constructor() {
        platformFeeRec = payable(_msgSender());
        marketAddress = payable(address(this));
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function updatePlatformFee(uint256 _pFee) external onlyOwner {
        platformFee = _pFee;
        emit UpdatePlatformFee(_pFee);
    }

    function withdrawMarket(address _token) external onlyOwner {
        if (_token == address(0)) {
            (bool os, ) = payable(platformFeeRec).call{
                value: address(this).balance
            }("");
            require(os);
        } else {
            require(
                ERC20(_token).transferFrom(
                    address(this),
                    platformFeeRec,
                    address(this).balance
                )
            );
        }
    }

    function setMaxMintRoyalty(uint256 _royalty) external onlyOwner {
        maxRoyalty = _royalty;
    }

    function _addNewMinter(
        address _minter,
        address _nft,
        uint256 _tokenId
    ) internal {
        minters[_nft][_tokenId] = _minter;
    }

    function getTokenMinter(address _nft, uint256 _tokenId)
        internal
        view
        returns (address)
    {
        return minters[_nft][_tokenId];
    }

    function _setTokenRoyalty(
        address _nft,
        uint256 _tokenId,
        uint256 _royalty
    ) internal {
        require(_royalty <= maxRoyalty);
        royalties[_nft][_tokenId] = _royalty;
    }

    function _getTokenRoyalty(address _nft, uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        return royalties[_nft][_tokenId];
    }
}