pragma solidity ^0.5.16;

import "./MTokenTest_coins.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the price of an underlying token
      * @param underlyingToken The address of the underlying token contract
      * @param tokenID The ID of the underlying token if it is a NFT (0 for fungible tokens)
      * @return The underlying asset price mantissa (scaled by 1e18). For fungible underlying tokens that
      * means e.g. if one single underlying token costs 1 Wei then the asset price mantissa should be 1e18. 
      * In case of underlying (ERC-721 compliant) NFTs one NFT always corresponds to oneUnit = 1e18 
      * internal calculatory units (see MTokenInterfaces.sol), therefore if e.g. one NFT costs 0.1 ETH 
      * then the asset price mantissa returned here should be 0.1e18.
      * Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address underlyingToken, uint256 tokenID) public view returns (uint);
}

contract PriceOracleV0_1 is PriceOracle {

    event NewCollectionFloorPrice(uint oldFloorPrice, uint newFloorPrice);

    address admin;
    TestNFT glassesContract;
    IERC721 collectionContract;
    uint collectionFloorPrice;

    constructor(address _admin, TestNFT _glassesContract, IERC721 _collectionContract) public {
        admin = _admin;
        glassesContract = _glassesContract;
        collectionContract = _collectionContract;
    }

    function getUnderlyingPrice(address underlyingToken, uint256 tokenID) public view returns (uint) {
        tokenID;
        if (underlyingToken == address(uint160(-1))) {
            return 1.0e18; // relative price of MEther token is 1.0 (1 token = 1 Wei)
        }
        else if (underlyingToken == address(glassesContract)) {
            return glassesContract.price(); // one unit (1e18) of NFT price in wei
        }
        else if (underlyingToken == address(collectionContract)) {
            return collectionFloorPrice; // one unit (1e18) of NFT price in wei
        }
        else {
            return 0;
        }
    }

    function _setCollectionFloorPrice(uint newFloorPrice) external {
        require(msg.sender == admin, "only admin");
        uint oldFloorPrice = collectionFloorPrice;
        collectionFloorPrice = newFloorPrice;

        emit NewCollectionFloorPrice(oldFloorPrice, newFloorPrice);
    }
}

contract PriceOracleV0_2 is PriceOracleV0_1 {

    event NewIndividualPrice(uint256 tokenID, uint oldPrice, uint newPrice);

    mapping (uint256 => uint256) individualPrices;

    constructor(address _admin, TestNFT _glassesContract, IERC721 _collectionContract) PriceOracleV0_1(_admin, _glassesContract, _collectionContract) public {
    }

    function getUnderlyingPrice(address underlyingToken, uint256 tokenID) public view returns (uint) {
        if (underlyingToken == address(uint160(-1))) {
            return 1.0e18; // relative price of MEther token is 1.0 (1 token = 1 Wei)
        }
        else if (underlyingToken == address(glassesContract)) {
            return glassesContract.price(); // one unit (1e18) of NFT price in wei
        }
        else if (underlyingToken == address(collectionContract)) {
            uint collection = collectionFloorPrice;
            uint individual = individualPrices[tokenID];
            return (individual > collection ? individual : collection); // one unit (1e18) of NFT price in wei
        }
        else {
            return 0;
        }
    }

    function _setIndividualPrice(uint256 tokenID, uint newPrice) external {
        require(msg.sender == admin, "only admin");
        uint oldPrice = individualPrices[tokenID];
        if (newPrice != oldPrice) {
            individualPrices[tokenID] = newPrice;
            emit NewIndividualPrice(tokenID, oldPrice, newPrice);
        }
    }
}