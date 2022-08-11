// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Generic Upshot Oracle for testing / any use
/// @author Relyt29
/// @notice Calls the Upshot Chainlink oracle to get NFT token price appraisal data
/// @dev https://market.link/nodes/Upshot/integrations
contract GenericUpshotOracle is Ownable, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    struct TokenInfo {
        address tokenAddress;
        uint tokenId;
    }

    mapping(bytes32 => uint256) public prices;
    mapping(bytes32 => TokenInfo) public requests;


    ///  @notice constructor
    ///  @dev for unit testing, use mainnet
    ///  @param _link the LINK token address.
    ///  @param _oracle the Operator.sol contract address.
    constructor(
        address _link,
        address _oracle
    ) {
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
    }

    /// @notice Queries the stored history of prices and returns the value
    /// @param _tokenAddress which nft collection address to look up
    /// @param _tokenId which token number to look up
    /// @return price uint price value in wei stored in the oracle db history
    function getPrice(address _tokenAddress, uint256 _tokenId) external view returns (uint256 price) {
        return prices[b32(_tokenAddress, _tokenId)];
    }

    /* ========== CONSUMER REQUEST FUNCTIONS ========== */
    /**
     * @notice Returns the price of a specific token in WEI from an NFT collection.
     * @dev Result format is a uint256.
     * @param _specId the jobID.
     * @param _payment the LINK amount in Juels (i.e. 10^18 aka 1 LINK).
     * @param _assetAddress the address of the collection for which we want the floor price.
     * @param _tokenId the address of the collection for which we want the floor price.
     */
    function requestAssetPrice(
        bytes32 _specId,
        uint256 _payment,
        address _assetAddress,
        uint256 _tokenId
    ) external returns (bytes32) {
        Chainlink.Request memory req = buildOperatorRequest(_specId, this.fulfillAssetPrice.selector);

        req.addBytes("assetAddress", abi.encodePacked(_assetAddress));
        req.addUint("tokenId", _tokenId);

        bytes32 requestId = sendOperatorRequest(req, _payment);
        requests[requestId] =  TokenInfo(_assetAddress, _tokenId);
        return requestId;
    }

    /// @notice Callback called by Chainlink oracle with data
    /// @dev If oracle says price=0 store MUST store price of 1 wei (differentiate from uninitialized)
    /// @param _requestId requestId from sendOperatorRequest
    /// @param _price the answer from the oracle for the price appraisal
    function fulfillAssetPrice(bytes32 _requestId, uint256 _price)
        public
        recordChainlinkFulfillment(_requestId)
    {
        TokenInfo memory tInfo = requests[_requestId];
        prices[b32(tInfo.tokenAddress, tInfo.tokenId)] = _price;
    }

    /* ========== Helpers ========== */

    /// @notice Getter function to return the address of the oracle we are using
    /// @return address - the oracle address
    function getOracleAddress() external view returns (address) {
        return chainlinkOracleAddress();
    }

    /// @notice Setter function to set the address of the oracle to query
    /// @param _oracle address to set the new oracle to
    function setOracle(address _oracle) external onlyOwner {
        setChainlinkOracle(_oracle);
    }

    /// @notice Allows the marketplace operator to withdraw any excess link stored in the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface linkToken = LinkTokenInterface(
            chainlinkTokenAddress()
        );
        require(
            linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /// @dev helper function, hopefully the compiler is smart enough to inline this
    function b32(address _tokenAddress, uint _tokenId) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_tokenAddress, _tokenId));
    }

    /// @dev wrapper function for unit testing because ChainlinkClient does not expose s_pendingRequests directly
    function checkIsPending(bytes32 _requestId) external view notPendingRequest(_requestId) {
    }

    /// @dev wrapper function for unit testing because ChainlinkClient does not expose s_pendingRequests directly
    function isPendingRequest(bytes32 _requestId) external view returns (bool) {
        try this.checkIsPending(_requestId) {
            return false;
        } catch {
            return true;
        }
    }

    /// @notice Destroy the contract, free state on blockchain nodes if you don't need this anymore
    function murder() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}