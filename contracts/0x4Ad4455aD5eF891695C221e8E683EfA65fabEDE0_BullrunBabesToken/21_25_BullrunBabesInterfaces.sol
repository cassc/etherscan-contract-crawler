pragma solidity >0.6.1 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface BullrunBabesCoordinatorI {
    function draw() external payable;

    function tradeUp(uint256[] memory tokens) external payable;

    struct CardView {
        uint256 id;
        uint256 serial;
        string cid;
        uint256 tier;
        uint256 cardTypeId;
        uint256 price;
        uint256 prevPrice;
        uint256 currentSerialForType;
    }

    function getAllocations() external view returns (uint256[][] memory);

    function getCard(uint256 id) external view returns (CardView memory);

    function getPrice(uint256 reserve) external view returns (uint256);

    function setPrice(uint256 tokenId, uint256 price) external;

    function purchase(uint256 tokenId) external payable;

    function totalSaleSupply() external view returns (uint256);

    function saleTokenByIndex(uint256 index) external view returns (uint256);

    event CardAllocated(
        address indexed owner,
        uint256 tokenId,
        uint256 serial,
        uint256 cardTypeId,
        uint256 tier,
        string cid,
        bytes32 queryId
    );
}

interface BullrunBabesCoordinatorIAdmin is BullrunBabesCoordinatorI {
    function getOracleGasFee() external view returns (uint256, uint256);

    function setOracleGasFee(uint256 _gas, uint256 _fee) external;

    function cancelRandom(bytes32 _queryId) external payable;

    function inflightReserves() external view returns (uint256[] memory);

    function checkInflight(bytes32[] memory _queryIds)
        external
        view
        returns (bytes32[] memory);

    function withdraw() external payable;

    event RandomInitiated(bytes32 queryId);
    event RandomReceived(bytes32 queryId);
}

interface BullrunBabesOracleI {
    function setCoordinator(address _coordinator) external;

    function _init_random() external payable returns (bytes32);

    event RandomInitiated(bytes32 indexed queryId);
    event RandomReceived(bytes32 indexed queryId);
}

interface BullrunBabesOracleIAdmin is BullrunBabesOracleI {
    function getGasPriceAndGas() external view returns (uint256, uint256);

    function setGasPriceAndGas(uint256 _gasPrice, uint256 _gas) external;
}

interface BullrunBabesTokenI is IERC721, IERC721Metadata, IERC721Enumerable {}