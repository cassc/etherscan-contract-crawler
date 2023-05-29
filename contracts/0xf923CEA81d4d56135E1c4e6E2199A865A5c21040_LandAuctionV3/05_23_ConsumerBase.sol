// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../vendor/OOOSafeMath.sol";
import "../interfaces/IERC20_Ex.sol";
import "../interfaces/IRouter.sol";
import "./RequestIdBase.sol";

/**
 * @title ConsumerBase smart contract
 *
 * @dev This contract can be imported by any smart contract wishing to include
 * off-chain data or data from a different network within it.
 *
 * The consumer initiates a data request by forwarding the request to the Router
 * smart contract, from where the data provider(s) pick up and process the
 * data request, and forward it back to the specified callback function.
 *
 */
abstract contract ConsumerBase is RequestIdBase {
    using OOOSafeMath for uint256;

    /*
     * STATE VARIABLES
     */

    // nonces for generating requestIds. Must be in sync with the
    // nonces defined in Router.sol.
    mapping(address => uint256) private nonces;

    IERC20_Ex internal immutable xFUND;
    IRouter internal router;

    /*
     * WRITE FUNCTIONS
     */

    /**
     * @dev Contract constructor. Accepts the address for the router smart contract,
     * and a token allowance for the Router to spend on the consumer's behalf (to pay fees).
     *
     * The Consumer contract should have enough tokens allocated to it to pay fees
     * and the Router should be able to use the Tokens to forward fees.
     *
     * @param _router address of the deployed Router smart contract
     * @param _xfund address of the deployed xFUND smart contract
     */
    constructor(address _router, address _xfund) {
        require(_router != address(0), "router cannot be the zero address");
        require(_xfund != address(0), "xfund cannot be the zero address");
        router = IRouter(_router);
        xFUND = IERC20_Ex(_xfund);
    }

    /**
     * @notice _setRouter is a helper function to allow changing the router contract address
     * Allows updating the router address. Future proofing for potential Router upgrades
     * NOTE: it is advisable to wrap this around a function that uses, for example, OpenZeppelin's
     * onlyOwner modifier
     *
     * @param _router address of the deployed Router smart contract
     */
    function _setRouter(address _router) internal returns (bool) {
        require(_router != address(0), "router cannot be the zero address");
        router = IRouter(_router);
        return true;
    }

    /**
     * @notice _increaseRouterAllowance is a helper function to increase token allowance for
     * the xFUND Router
     * Allows this contract to increase the xFUND allowance for the Router contract
     * enabling it to pay request fees on behalf of this contract.
     * NOTE: it is advisable to wrap this around a function that uses, for example, OpenZeppelin's
     * onlyOwner modifier
     *
     * @param _amount uint256 amount to increase allowance by
     */
    function _increaseRouterAllowance(uint256 _amount) internal returns (bool) {
        // The context of msg.sender is this contract's address
        require(xFUND.increaseAllowance(address(router), _amount), "failed to increase allowance");
        return true;
    }

    /**
     * @dev _requestData - initialises a data request. forwards the request to the deployed
     * Router smart contract.
     *
     * @param _dataProvider payable address of the data provider
     * @param _fee uint256 fee to be paid
     * @param _data bytes32 value of data being requested, e.g. PRICE.BTC.USD.AVG requests
     * average price for BTC/USD pair
     * @return requestId bytes32 request ID which can be used to track or cancel the request
     */
    function _requestData(address _dataProvider, uint256 _fee, bytes32 _data)
    internal returns (bytes32) {
        bytes32 requestId = makeRequestId(address(this), _dataProvider, address(router), nonces[_dataProvider], _data);
        // call the underlying ConsumerLib.sol lib's submitDataRequest function
        require(router.initialiseRequest(_dataProvider, _fee, _data));
        nonces[_dataProvider] = nonces[_dataProvider].safeAdd(1);
        return requestId;
    }

    /**
     * @dev rawReceiveData - Called by the Router's fulfillRequest function
     * in order to fulfil a data request. Data providers call the Router's fulfillRequest function
     * The request is validated to ensure it has indeed been sent via the Router.
     *
     * The Router will only call rawReceiveData once it has validated the origin of the data fulfillment.
     * rawReceiveData then calls the user defined receiveData function to finalise the fulfilment.
     * Contract developers will need to override the abstract receiveData function defined below.
     *
     * @param _price uint256 result being sent
     * @param _requestId bytes32 request ID of the request being fulfilled
     * has sent the data
     */
    function rawReceiveData(
        uint256 _price,
        bytes32 _requestId) external
    {
        // validate it came from the router
        require(msg.sender == address(router), "only Router can call");

        // call override function in end-user's contract
        receiveData(_price, _requestId);
    }

    /**
    * @dev receiveData - should be overridden by contract developers to process the
    * data fulfilment in their own contract.
    *
    * @param _price uint256 result being sent
    * @param _requestId bytes32 request ID of the request being fulfilled
    */
    function receiveData(
        uint256 _price,
        bytes32 _requestId
    ) internal virtual;

    /*
     * READ FUNCTIONS
     */

    /**
     * @dev getRouterAddress returns the address of the Router smart contract being used
     *
     * @return address
     */
    function getRouterAddress() external view returns (address) {
        return address(router);
    }

}