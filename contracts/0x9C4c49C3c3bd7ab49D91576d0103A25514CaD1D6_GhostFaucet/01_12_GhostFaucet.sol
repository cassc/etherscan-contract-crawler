// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IGhostFaucet.sol";
import "./interfaces/IERC721Envious.sol";
import "./interfaces/IERC721EnviousDynamic.sol";
import "./libraries/Sigmoid.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/token/ERC721/IERC721.sol";
import "./openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";

contract GhostFaucet is IGhostFaucet {

	using SafeERC20 for IERC20;
	using Sigmoid for Sigmoid.SigmoidParams;

	uint256 public immutable override baseDisperse;
	uint256 public immutable override baseAmount;
	address public immutable override nftAddress;
	address public immutable override tokenAddress;

	uint256 public override totalTokensMinted;
	mapping(address => uint256) public override nftsMinted;
	mapping(address => uint256) public override tokensMinted;
	mapping(address => uint256) public override referralsNumber;

	Sigmoid.SigmoidParams private _sigmoid;

	constructor (
		address collection, 
		address token, 
		uint256 disperse, 
		uint256 amount,
		int256[3] memory sigmoidParams
	) {
		require(
			IERC721(collection).supportsInterface(type(IERC721EnviousDynamic).interfaceId) &&
			IERC721(collection).supportsInterface(type(IERC721Enumerable).interfaceId), 
			"Not a dynamic collection"
		);
		require(token != address(0), "Bad constructor addresses");
		
		nftAddress = collection;
		tokenAddress = token;
		baseDisperse = disperse;
		baseAmount = amount;

		_sigmoid = Sigmoid.SigmoidParams(sigmoidParams[0], sigmoidParams[1], sigmoidParams[2]);

		IERC20(token).approve(collection, type(uint256).max);
	}

	function sendMeGhostNft(address friend) external payable override {
		// NOTE: function `tokenOfOwnerByIndex` should revert if zero balance of address `friend`
		uint256 tokenId = IERC721Enumerable(nftAddress).tokenOfOwnerByIndex(friend, 0);
		uint256 ownedNfts = nftsMinted[msg.sender];
		uint256 amount = baseAmount + baseAmount * sigmoidValue(referralsNumber[friend]);

		referralsNumber[friend] += 1;
		nftsMinted[msg.sender] += 1;

		tokensMinted[friend] += amount;
		totalTokensMinted += amount;

		if (ownedNfts > 0) {
			uint256 disperseAmount = baseDisperse + baseDisperse * sigmoidValue(ownedNfts);
			(uint256[] memory values, address[] memory etherAddresses) = _prepareValues(disperseAmount, address(0));
			// NOTE: function `disperse` should revert if `disperseAmount` less then msg.value
			IERC721Envious(nftAddress).disperse{value: disperseAmount}(values, etherAddresses);
		}

		(uint256[] memory amounts, address[] memory tokenAddresses) = _prepareValues(amount, tokenAddress);
		IERC721EnviousDynamic(nftAddress).mint(msg.sender);
		IERC721Envious(nftAddress).collateralize(tokenId, amounts, tokenAddresses);

		// solhint-disable-next-line
		emit AssetAirdropped(msg.sender, friend, amount, block.timestamp);
	}

	function sigmoidValue(uint256 x) public override view returns (uint256) {
		return _sigmoid.sigmoid(x);
	}

	function _prepareValues(
		uint256 amount,
		address collateralAddress
	) private pure returns (uint256[] memory, address[] memory) {
		uint256[] memory amounts = new uint256[](1);
		address[] memory tokenAddresses = new address[](1);
		
		amounts[0] = amount;
		tokenAddresses[0] = collateralAddress;

		return (amounts, tokenAddresses);
	}
}