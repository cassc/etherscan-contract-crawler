interface IPandaNFT {
    function mint(
        uint256[] memory token_ids,
        uint256[] memory quantities,
        address sender
    ) external;

    function mint(uint256[] memory token_ids, address sender) external payable;

    function getCost(uint256 token_id) external returns (uint256);

    function getPrices(uint256 token_id) external returns (uint256);

    function getSupply(uint256 token_id) external returns (uint256);

    function getRemainingBalance(uint256 token_id) external returns (uint256);

    function getMintTime(uint256 _tokenId) external returns (uint256);
    
    function getMintedQuantity(uint256 token_id) external returns (uint256);

    
}