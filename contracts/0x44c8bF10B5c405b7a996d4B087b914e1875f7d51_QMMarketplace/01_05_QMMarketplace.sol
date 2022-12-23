/*                                                                                                             
      # ###                                                       #####   ##    ##                ##            
    /  /###                                                    ######  /#### #####                 ##           
   /  /  ###                                                  /#   /  /  ##### #####               ##           
  /  ##   ###                                                /    /  /   # ##  # ##                ##           
 /  ###    ###                                                   /  /    #     #                   ##           
##   ##     ## ##   ####      /##       /##  ###  /###          ## ##    #     #      /###     ### ##    /##    
##   ##     ##  ##    ###  / / ###     / ###  ###/ #### /       ## ##    #     #     / ###  / ######### / ###   
##   ##     ##  ##     ###/ /   ###   /   ###  ##   ###/        ## ##    #     #    /   ###/ ##   #### /   ###  
##   ##     ##  ##      ## ##    ### ##    ### ##    ##         ## ##    #     #   ##    ##  ##    ## ##    ### 
##   ##     ##  ##      ## ########  ########  ##    ##         ## ##    #     ##  ##    ##  ##    ## ########  
 ##  ## ### ##  ##      ## #######   #######   ##    ##         #  ##    #     ##  ##    ##  ##    ## #######   
  ## #   ####   ##      ## ##        ##        ##    ##            /     #      ## ##    ##  ##    ## ##        
   ###     /##  ##      /# ####    / ####    / ##    ##        /##/      #      ## ##    ##  ##    /# ####    / 
    ######/ ##   ######/ ## ######/   ######/  ###   ###      /  #####           ## ######    ####/    ######/  
      ###   ##    #####   ## #####     #####    ###   ###    /     ##                ####      ###      #####   
            ##                                               #                                                  
            /                                                 ##                                                                                                                                                
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract QMMarketplace {
  mapping(bytes32 => Offer) public offers;
  uint256 public deltaInWei;
  AggregatorV3Interface internal priceFeedContract;

  struct Offer {
    IERC721 collection;
    uint256 tokenId;
    uint96 priceInUsd;
    uint96 discountedPriceForHoldersInUsd;
  }

  event NftBought(address _collection, uint256 _tokenId, address _seller, address _buyer, uint256 _price);
  event NftOnSale(bytes32 _offerHash, address _collection, uint256 _tokenId, uint96 _priceInUsd);

  /**
   * Constructs the instance of a contract.
   * @param _priceFeedContract is the oracle to convert USD to ETH.
   */
  constructor(address _priceFeedContract, uint256 _deltaInWei) {
    priceFeedContract = AggregatorV3Interface(_priceFeedContract);
    deltaInWei = _deltaInWei;
  }

  function putOnSale(IERC721 _collection, uint256[] memory _tokenIds, uint96[] memory _pricesInUsd, uint96[] memory _discountedPricesForHoldersInUsd) external {
    require(_tokenIds.length == _pricesInUsd.length && _pricesInUsd.length == _discountedPricesForHoldersInUsd.length, 'The sizes do not match');
    for (uint i = 0; i < _tokenIds.length; i++) {
      putOnSale(_collection, _tokenIds[i], _pricesInUsd[i], _discountedPricesForHoldersInUsd[i]);
    }
  }

  /**
   * Puts a @param _tokenId from @param _collection on sale with defined @param _priceInUsd.
   * It is required to approve usage of a token to this contract before this function is called.
   * Emits NftOnSale event when successful.
   */
  function putOnSale(IERC721 _collection, uint256 _tokenId, uint96 _priceInUsd, uint96 _discountedPriceForHoldersInUsd) public {
    require(_collection.ownerOf(_tokenId) == msg.sender, 'You do not own this NFT');
    require(isApproved(msg.sender, _collection, _tokenId), 'It is required to approve for selling');

    bytes32 offerHash = getOfferHash(_collection, _tokenId);
    offers[offerHash] = Offer({
        collection: _collection,
        tokenId: _tokenId,
        priceInUsd: _priceInUsd,
        discountedPriceForHoldersInUsd: _discountedPriceForHoldersInUsd
    });
    
    emit NftOnSale(offerHash, address(_collection), _tokenId, _priceInUsd);
  }
  
  /**
   * Allows to purchase a @param _tokenId from @param _collection and sends it to @param _receiver.
   * ETH value sent must be enough for purchasing.
   * Emits NftBought event when successful.
   */
  function purchase(IERC721 _collection, uint256 _tokenId, address _receiver) external payable {
    bytes32 offerHash = getOfferHash(_collection, _tokenId);
    Offer memory offer = offers[offerHash];
    require(address(offer.collection) != address(0x0), 'No offer found');
    uint96 priceInUsd = getPriceInUsd(_receiver, _collection, _tokenId);
    uint256 priceInWei = getConversionRate(priceInUsd);
    require(msg.value + deltaInWei >= priceInWei, 'Not enough ETH');
    address payable seller = payable(IERC721(offer.collection).ownerOf(offer.tokenId));

    Address.sendValue(seller, priceInWei);
    IERC721(offer.collection).transferFrom(seller, _receiver, offer.tokenId);

    delete offers[offerHash];

    emit NftBought(address(offer.collection), offer.tokenId, seller, _receiver, msg.value);
  }

  /**
   * Generates the hash based on @param _collection and @param _tokenId.
   */
  function getOfferHash(IERC721 _collection, uint256 _tokenId) internal pure returns(bytes32) {
    return keccak256(abi.encodePacked(_collection, _tokenId));
  }

  /**
   * To get latest price of ether in wei to buy an NFT.
   */
  function getConversionRate(uint96 valueInUsd) public view returns (uint256) {
      (, int256 price, , , ) = priceFeedContract.latestRoundData();
      uint256 ethAmountInWei = ((1 * 10**26) * valueInUsd) / uint256(price);
      return ethAmountInWei;
  }
  
  /**
   * Checks if an approval was give to marketplace contract from @param _owner of @param _tokenId from @param _collection.
   */
  function isApproved(address _owner, IERC721 _collection, uint256 _tokenId) internal view returns(bool) {
    return _collection.isApprovedForAll(_owner, address(this)) || _collection.getApproved(_tokenId) == address(this);
  }

  /**
   * Returns the price in USD based on ownership of any token in a @param _collection by a @param wallet.
   */
  function getPriceInUsd(address _wallet, IERC721 _collection, uint256 _tokenId) public view returns (uint96) {
    bytes32 offerHash = getOfferHash(_collection, _tokenId);
    Offer memory offer = offers[offerHash];
    if (isNotHolder(_wallet, _collection)) {
      // normal price for non-holders and non-existing accounts
      return offer.priceInUsd;
    }
    // discounted price for holders
    return offer.discountedPriceForHoldersInUsd;
  }

  /**
   * Identifies whether @param _wallet holds any tokens of a @param _collection.
   * Returns true if a wallet is not holder and false if a wallet is a holder.
   */
  function isNotHolder(address _wallet, IERC721 _collection) internal view returns (bool) {
    return _wallet == address(0x0) || _collection.balanceOf(_wallet) == 0;
  }

  /**
   * Returns the Offer object based on @param _collection and @param _tokenId.
   */
  function getOfferPriceInUsd(IERC721 _collection, uint256 _tokenId) public view returns (Offer memory) {
    bytes32 offerHash = getOfferHash(_collection, _tokenId);
    Offer memory offer = offers[offerHash];
    return offer;
  }
}