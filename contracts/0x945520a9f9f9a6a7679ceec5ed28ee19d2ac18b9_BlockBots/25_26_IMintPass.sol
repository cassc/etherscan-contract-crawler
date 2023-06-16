pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMintPass is IERC1155 {
    function totalMinted() external view returns (uint256);

    function getOnMarketMintPassTokenId() external view returns (uint256);

    function getOffMarketMintPassTokenId() external view returns (uint256);

    function totalSupply(uint256 tokenId) external view returns (uint256);

    function setUri(string memory _uri) external;

    function uri(uint256 tokenId) external view returns (string memory);

    function setMintPause(bool _pauseMintPass, bool _pauseBatchMintPass)
        external;

    function createMintPass(address recipient, uint256 quantity) external;

    function onMarketRedeemPass(address blockbots, uint256 quantity)
        external
        payable;

    function offMarketRedeemPass(
        address blockbots,
        address recipient,
        uint256 quantity
    ) external;

    function fetchBalanceOf(address owner) external view returns (uint256);

    function withdraw() external payable;

    function batchMintPass(
        address[] memory _recipients,
        uint256[] memory _quantities
    ) external;

    function batchOffMarketRedeemPass(
        address blockbots,
        address[] memory _recipients,
        uint256[] memory _quantities
    ) external;
}