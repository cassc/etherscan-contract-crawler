// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Supported `collectionId`
 * --------------------
 *  1 : thecurrency (default)
 */

/**
 * @title A consumer contract for Heni API.
 * @author LinkPool.
 * @dev Uses @chainlink/contracts 0.4.0.
 */
contract HeniConsumer is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    /* ========== CONSUMER STATE VARIABLES ========== */

    uint256 public price;

    bytes32 private jobId;
    uint256 private fee;

    // Maps <RequestId, Result>
    mapping(bytes32 => uint256) public requestIdData;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _link the LINK token address.
     * @param _oracle the Operator.sol contract address.
     */
    constructor(
        address _link,
        address _oracle,
        uint256 _fee
    ) {
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
        jobId = "e2cd92c15f434290bb43e77be8de815a";
        fee = _fee;
    }

    /* ========== CONSUMER REQUEST FUNCTIONS ========== */

    /**
     * @dev Result format is uint256.
     
     */
    function requestPrice() public {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillPrice.selector
        );

        sendChainlinkRequest(req, fee);
    }

    /* ========== CONSUMER FULFILL FUNCTIONS ========== */

    function fulfillPrice(bytes32 _requestId, uint256 _price)
        public
        recordChainlinkFulfillment(_requestId)
    {
        price = _price;

        requestIdData[_requestId] = _price;
    }

    /* ========== OTHER FUNCTIONS ========== */

    function getOracleAddress() external view returns (address) {
        return chainlinkOracleAddress();
    }

    function setOracle(address _oracle) external {
        setChainlinkOracle(_oracle);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface linkToken = LinkTokenInterface(
            chainlinkTokenAddress()
        );
        require(
            linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
    @notice set fee function
    @param _fee uint256
     */
    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }
}