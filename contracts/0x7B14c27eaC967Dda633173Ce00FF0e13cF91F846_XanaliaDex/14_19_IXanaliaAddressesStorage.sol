// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXanaliaAddressesStorage {
	event XNftURIAddressChanged(address xNftURI);
	event AuctionDexChanged(address auctionDex);
	event MarketDexChanged(address marketDex);
	event OfferDexChanged(address offerDex);
	event XanaliaDexChanged(address xanaliaDex);
	event TreasuryChanged(address xanaliaTreasury);
	event DeployerChanged(address collectionDeployer);
	event XanaliaDexProxyChanged(address oldXanaliaDexProxy);

	function xNftURI() external view returns (address);

	function auctionDex() external view returns (address);

	function marketDex() external view returns (address);

	function offerDex() external view returns (address);

	function xanaliaDex() external view returns (address);

	function xanaliaTreasury() external view returns (address);

	function collectionDeployer() external view returns (address);

	function oldXanaliaDexProxy() external view returns (address);
}