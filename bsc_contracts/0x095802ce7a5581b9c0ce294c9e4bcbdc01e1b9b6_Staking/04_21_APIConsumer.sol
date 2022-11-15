//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract APIConsumer is ChainlinkClient, ConfirmedOwner {
	using Chainlink for Chainlink.Request;
	using Strings for uint256;

	bytes32 private jobId;
	address private oracle;
	uint256 private fee;

	// multiple params returned in a single oracle response
	uint256 public value;

	uint256 private currentId;

	string public path;
	mapping(uint256 => uint256) public rarities;

	event RequestMultipleFulfilled(bytes32 indexed requestId, uint256 value);

	/**
	 * @notice Initialize the link token and target oracle
	 * @dev The oracle address must be an Operator contract for multiword response
	 *
	 *
	 * Goerli Testnet details:
	 * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
	 * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
	 * jobId: ca98366cc7314957b8c012c72f05aeeb
	 *
	 */
	constructor(address _linkToken, address _oracle)
		ConfirmedOwner(msg.sender)
	{
		setChainlinkToken(_linkToken);
		oracle = _oracle;
		setChainlinkOracle(_oracle);

		jobId = "a052732022e04e89be3e0fc06e457985"; //uint256
		fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
	}

	/**
	 * @notice Request mutiple parameters from the oracle in a single transaction
	 */
	function requestMultipleParameters(uint256 _id) public {
		Chainlink.Request memory req = buildChainlinkRequest(
			jobId,
			address(this),
			this.fulfillMultipleParameters.selector
		);
		path = string(
			abi.encodePacked(
				"http://stakeserver-production.up.railway.app/data?id=",
				_id.toString()
			)
		);

		req.add("get", path);
		req.add("path", "rarity");
		int256 timesAmount = 1;
		req.addInt("times", timesAmount);

		sendChainlinkRequest(req, fee); // MWR API.
	}

	/**
	 * @notice Fulfillment function for multiple parameters in a single request
	 * @dev This is called by the oracle. recordChainlinkFulfillment must be used.
	 */
	function fulfillMultipleParameters(
		bytes32 requestId,
		uint256 valueResponse
	) public recordChainlinkFulfillment(requestId) {
		emit RequestMultipleFulfilled(requestId, valueResponse);
		value = valueResponse;
		rarities[currentId] = valueResponse;
	}

	/**
	 * Allow withdraw of Link tokens from the contract
	 */
	function withdrawLink(address _to) public onlyOwner {
		LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
		require(
			link.transfer(_to, link.balanceOf(address(this))),
			"Unable to transfer"
		);
	}

	function setJobId(bytes32 _jobId) external onlyOwner {
		jobId = _jobId;
	}

	function getJobId() external view returns (bytes32 jobIdentifier) {
		return jobId;
	}

	function setOracle(address _oracle) external onlyOwner {
		require(_oracle != address(0)); //Check that it is not the zeroth address
		oracle = _oracle;
		setChainlinkOracle(_oracle);
	}

	function getOracle() external view returns (address oracleAddress) {
		return oracle;
	}

	function getLinkBalance() public view returns (uint256 balance) {
		LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
		balance = link.balanceOf(address(this));
	}

	function setCurrentId(uint256 _id) public {
		currentId = _id;
	}

	function getRarity(uint256 _id) public view returns (uint256 rarity) {
		rarity = rarities[_id];
	}
}