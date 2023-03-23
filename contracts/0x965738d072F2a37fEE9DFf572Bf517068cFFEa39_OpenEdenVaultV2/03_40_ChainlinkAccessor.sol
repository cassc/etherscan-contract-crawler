// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./external/chainlink/ChainlinkClientModified.sol";
import "./interfaces/IChainlinkAccessor.sol";
import "./interfaces/IOpenEdenVault.sol";
import "hardhat/console.sol";

abstract contract ChainlinkAccessor is
    IChainlinkAccessor,
    ChainlinkClientModified
{
    using Chainlink for Chainlink.Request;
    ChainlinkParameters _params;
    mapping(bytes32 => RequestData) internal _requestIdToRequestData; // requestId => RequestData

    event SetChainlinkOracleAddress(address newAddress);
    event SetChainlinkJobId(bytes32 jobId);
    event SetChainlinkFee(uint256 fee);
    event SetChainlinkURLData(string url);
    event SetPathToOffchainAssets(string path);
    event SetPathToTotalOffchainAssetAtLastClose(string path);

    /*//////////////////////////////////////////////////////////////
                     !!!NOTE!!! MUST BE IMPLEMENTED
    //////////////////////////////////////////////////////////////*/

    function setChainlinkOracleAddress(address newAddress) external virtual;

    function setChainlinkFee(uint256 fee) external virtual;

    function setChainlinkJobId(bytes32 jobId) external virtual;

    function setChainlinkURLData(string memory url) external virtual;

    function setPathToOffchainAssets(string memory path) external virtual;

    function setPathToTotalOffchainAssetAtLastClose(
        string memory path
    ) external virtual;

    /**
     * @dev Initializes Chainlink parameters, token, and oracle.
     * @param params Chainlink parameters containing fee, jobId, urlData, and paths.
     * @param chainlinkToken Address of the Chainlink token.
     * @param chainlinkOracle Address of the Chainlink oracle.
     */
    function init(
        ChainlinkParameters memory params,
        address chainlinkToken,
        address chainlinkOracle
    ) internal {
        _params.fee = params.fee;
        _params.jobId = params.jobId;
        _params.urlData = params.urlData;
        _params.pathToOffchainAssets = params.pathToOffchainAssets;
        _params.pathToTotalOffchainAssetAtLastClose = params
            .pathToTotalOffchainAssetAtLastClose;
        setChainlinkOracle(chainlinkOracle);
        setChainlinkToken(chainlinkToken);
        super.init();
    }

    function _requestTotalOffchainAssets(
        address investor,
        uint256 amount,
        Action action,
        uint8 decimals
    ) internal returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            _params.jobId,
            // !NOTE: what we set here will be ignored and replace by address(this) during encode
            address(0),
            IOpenEdenVault(address(this)).fulfill.selector
        );
        // Set the URL to perform the GET request on
        req.add(
            "get",
            _params.urlData // offchain assets url
        );
        if (action == Action.EPOCH_UPDATE)
            req.add("path", _params.pathToTotalOffchainAssetAtLastClose);
        else {
            req.add("path", _params.pathToOffchainAssets);
        }
        // Multiply the result by decimals
        int256 timesAmount = int256(10 ** decimals);
        req.addInt("times", timesAmount);
        RequestData memory requestData = RequestData(investor, amount, action);

        requestId = sendChainlinkRequest(req, _params.fee);

        // TODO
        _requestIdToRequestData[requestId] = requestData;
        // console.log("request send successfully!");
    }

    function getChainLinkParameters()
        external
        view
        returns (ChainlinkParameters memory params)
    {
        params = _params;
    }

    function getRequestData(
        bytes32 requestId
    ) public view returns (address investor, uint256 amount, Action action) {
        investor = _requestIdToRequestData[requestId].investor;
        amount = _requestIdToRequestData[requestId].amount;
        action = _requestIdToRequestData[requestId].action;
    }

    /*//////////////////////////////////////////////////////////////
                     INTERNAL IMPLEMENTATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setChainlinkOracleAddress(address newAddress) internal {
        super.setChainlinkOracle(newAddress);
        emit SetChainlinkOracleAddress(newAddress);
    }

    function _setChainlinkFee(uint256 fee) internal {
        _params.fee = fee;
        emit SetChainlinkFee(fee);
    }

    function _setChainlinkJobId(bytes32 jobId) internal {
        _params.jobId = jobId;
        emit SetChainlinkJobId(jobId);
    }

    function _setChainlinkURLData(string memory url) internal {
        _params.urlData = url;
        emit SetChainlinkURLData(url);
    }

    function _setPathToOffchainAssets(string memory path) internal {
        _params.pathToOffchainAssets = path;
        emit SetPathToOffchainAssets(path);
    }

    function _setPathToTotalOffchainAssetAtLastClose(
        string memory path
    ) internal {
        _params.pathToTotalOffchainAssetAtLastClose = path;
        emit SetPathToTotalOffchainAssetAtLastClose(path);
    }
}