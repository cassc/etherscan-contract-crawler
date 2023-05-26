pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./libs/EIP712Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceOracle
 * @dev Contract for storing and providing price data for the Orion Protocol
 * @author @EmelyanenkoK
 */
contract PriceOracle is /* EIP712Interface, */ Ownable {

    struct Prices {
        address[] assetAddresses;
        uint64[] prices;
        uint64 timestamp;
        bytes signature;
    }

    struct PriceDataOut {
        uint64 price;
        uint64 timestamp;
    }

    /*bytes32 public constant PRICES_TYPEHASH = keccak256(
        abi.encodePacked(
            "Prices(address[] assetAddresses,uint64[] prices,uint64 timestamp)"
        )
    );*/

    address public oraclePublicKey;
    address public baseAsset;
    mapping(address => PriceDataOut) public assetPrices;
    mapping(address => address) public chainLinkETHAggregator;
    mapping(address => bool) public priceProviderAuthorization;

    constructor(address publicKey, address _baseAsset) public {
        oraclePublicKey = publicKey;
        baseAsset = _baseAsset;
    }
    /*
    function checkPriceFeedSignature(Prices memory priceFeed) public view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getPricesHash(priceFeed)
            )
        );

        if (priceFeed.signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        bytes memory signature = priceFeed.signature;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        return ecrecover(digest, v, r, s) == oraclePublicKey;
    
    }

    function provideData(Prices memory priceFeed) public {
       require(checkPriceFeedSignature(priceFeed), "Wrong signature");
       require(priceFeed.timestamp<block.timestamp+60, "Price data timestamp too far in the future");
       for(uint8 i=0; i<priceFeed.assetAddresses.length; i++) {
         PriceDataOut storage assetData = assetPrices[priceFeed.assetAddresses[i]];
         if(assetData.timestamp<priceFeed.timestamp) {
           assetData.price = priceFeed.prices[i];
           assetData.timestamp = priceFeed.timestamp;
         }
       }
    }
    */
    function provideDataAddressAuthorization(Prices memory priceFeed) public {
       require(priceProviderAuthorization[msg.sender], "Unauthorized dataprovider");
       require(priceFeed.timestamp<block.timestamp+60, "Price data timestamp too far in the future");
       for(uint8 i=0; i<priceFeed.assetAddresses.length; i++) {
         PriceDataOut storage assetData = assetPrices[priceFeed.assetAddresses[i]];
         if(assetData.timestamp<priceFeed.timestamp) {
           assetData.price = priceFeed.prices[i];
           assetData.timestamp = priceFeed.timestamp;
         }
       }
    }

    function givePrices(address[] calldata assetAddresses) external view returns (PriceDataOut[] memory) {
      PriceDataOut[] memory result = new PriceDataOut[](assetAddresses.length);
      for(uint8 i=0; i<assetAddresses.length; i++) {
        result[i] = assetPrices[assetAddresses[i]];
      }
      return result;
    }
    /*
    function getPricesHash(Prices memory priceVector)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    PRICES_TYPEHASH,
                    keccak256(abi.encodePacked(priceVector.assetAddresses)),
                    keccak256(abi.encodePacked(priceVector.prices)),
                    priceVector.timestamp
                )
            );
    }
    */
    function getChainLinkPriceData(address[] memory assets) public {
      address baseAggregator = chainLinkETHAggregator[baseAsset];
      if(baseAggregator == address(0))
        return;
      (
          uint80 roundID,
          int _basePrice,
          uint startedAt,
          uint timestamp,
          uint80 answeredInRound
      ) = AggregatorV3Interface(baseAggregator).latestRoundData();
      uint now = block.timestamp;
      if(now - timestamp < 24 hours) {
        timestamp = now;
      }
      require(_basePrice>=0, "Negative base price is not allowed");
      uint basePrice = uint(_basePrice);
      
      //ETH/ORN  
      PriceDataOut storage baseAssetData = assetPrices[address(0)];
      if(baseAssetData.timestamp<timestamp) {
          uint price = ( (10**AggregatorV3Interface(baseAggregator).decimals()) *1e8)/basePrice;
          require(price<2**64-1, "Too big price");
          baseAssetData.price = uint64(price);
          baseAssetData.timestamp = uint64(timestamp);
      }
        
      for(uint8 i=0; i<assets.length; i++) {
        address currentAsset = assets[i];
        address currentAggregator = chainLinkETHAggregator[currentAsset];
        if( currentAggregator == address(0))
          continue;
        (
            uint80 aRoundID,
            int _aPrice,
            uint aStartedAt,
            uint aTimestamp,
            uint80 aAnsweredInRound
        ) = AggregatorV3Interface(currentAggregator).latestRoundData();
        require(_aPrice>=0, "Negative price is not allowed");
        if(now - timestamp < 24 hours) {
          aTimestamp = now;
        }
        uint aPrice = uint(_aPrice);
        uint newTimestamp = timestamp > aTimestamp? aTimestamp : timestamp;

        PriceDataOut storage assetData = assetPrices[currentAsset];
        if(assetData.timestamp<newTimestamp) {
          uint price = (aPrice *1e8)/basePrice;
          require(price<2**64-1, "Too big price");
          assetData.price = uint64(price);
          assetData.timestamp = uint64(newTimestamp);
        }

      }
    }    
    function setChainLinkAggregators(address[] memory assets, address[] memory aggregatorAddresses) public onlyOwner {
      for(uint8 i=0; i<assets.length; i++) {
        chainLinkETHAggregator[assets[i]] = aggregatorAddresses[i];
      }
    }
    
    function changePriceProviderAuthorization(address[] memory added, address[] memory removed) public onlyOwner {
      for(uint8 i=0; i<added.length; i++) {
        priceProviderAuthorization[added[i]] = true;
      }
      for(uint8 i=0; i<removed.length; i++) {
        priceProviderAuthorization[removed[i]] = false;
      }
    }
}