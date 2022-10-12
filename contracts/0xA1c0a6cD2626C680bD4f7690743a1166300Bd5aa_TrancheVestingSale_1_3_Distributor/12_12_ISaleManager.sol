pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

interface ISaleManager_v_1_3 {
	function getAdmin(bytes32 saleId) external view returns(address);
	function getRecipient(bytes32 saleId) external view returns(address);
	function getMerkleRoot(bytes32 saleId) external view returns(bytes32);
    function getPriceOracle() external view returns(address);
	function getClaimManager(bytes32 saleId) external view returns(address);
	function getSaleBuyLimit(bytes32 saleId) external view returns(uint256);
	function getUserBuyLimit(bytes32 saleId) external view returns(uint256);
	function getPurchaseMinimum(bytes32 saleId) external view returns(uint256);
	function getStartTime(bytes32 saleId) external view returns(uint);
	function getEndTime(bytes32 saleId) external view returns(uint);
	function getUri(bytes32 saleId) external view returns(string memory);
	function getPrice(bytes32 saleId) external view returns(uint);
	function getDecimals(bytes32 saleId) external view returns(uint256);
	function getTotalSpent(bytes32 saleId) external view returns(uint256);
    function getRandomValue(bytes32 saleId) external view returns(uint160);
	function getMaxQueueTime(bytes32 saleId) external view returns(uint256);
	function generateRandomishValue(bytes32 merkleRoot) external view returns(uint160);
	function getFairQueueTime(bytes32 saleId, address buyer) external view returns(uint);
	function spentToBought(bytes32 saleId, uint256 spent) external view returns (uint256);
	function nativeToPaymentToken(uint256 nativeValue) external view returns (uint256);
	function getSpent(bytes32 saleId, address userAddress) external view returns(uint256);
	function getBought(bytes32 saleId, address userAddress) external view returns(uint256);
	function isOpen(bytes32 saleId) external view returns(bool);
	function isOver(bytes32 saleId) external view returns(bool);
	function newSale(address payable recipient, bytes32 merkleRoot, uint256 saleBuyLimit, uint256 userBuyLimit, uint256 purchaseMinimum, uint startTime, uint endTime, uint160 maxQueueTime, string memory uri, uint256 price, uint8 decimals) external returns(bytes32);
	function setStart(bytes32 saleId, uint startTime) external;
	function setEnd(bytes32 saleId, uint endTime) external;
	function setMerkleRoot(bytes32 saleId, bytes32 merkleRoot) external;
	function setMaxQueueTime(bytes32 saleId, uint160 maxQueueTime) external;
	function setUriAndMerkleRoot(bytes32 saleId, bytes32 merkleRoot, string calldata uri) external;
	function buy(bytes32 saleId, uint256 tokenQuantity, bytes32[] calldata proof) external;
	function buy(bytes32 saleId, bytes32[] calldata proof) external payable;
	function registerClaimManager(bytes32 saleId, address claimManager) external;
	function recoverERC20(bytes32 saleId, address tokenAddress, uint256 tokenAmount) external;
}