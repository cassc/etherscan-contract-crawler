// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// This is interface for NichoNFT Marketplace contract
interface INichoNFTMarketplace {
    // List an NFT/NFTs on marketplace as same price with fixed price sale
    function listItemToMarketFromMint(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 askingPrice,
        address _creator,
        string memory _id
    ) external;

    /**
     * @dev when auction is created, cancel fixed sale
     */
    function cancelListFromAuctionCreation(
        address tokenAddress, uint256 tokenId
    ) external;

    /**
     * @dev emit whenever token owner created auction
     */
    function emitListedNFTFromAuctionContract(
        address _tokenAddress, 
        uint256 _tokenId, 
        address _creator, 
        uint256 _startPrice,
        uint256 _expireTs, 
        uint80  _nextAuctionId
    ) external;

    /**
     * @dev when accept auction bid, need to emit TradeActivity
     */
    function emitTradeActivityFromAuctionContract(
        address _tokenAddress, 
        uint256 _tokenId, 
        address _prevOwner, 
        address _newOwner, 
        uint256 _price
    ) external;

    /**
     * @dev set direct listable contract
     */
    function setDirectListable(address _target) external;
}