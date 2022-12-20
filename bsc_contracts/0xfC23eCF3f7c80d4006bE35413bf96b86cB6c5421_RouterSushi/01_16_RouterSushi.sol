// SPDX-License-Identifier: GPL-3.0-or-late
pragma solidity 0.8.11;

import "@routerprotocol/router-crosstalk/contracts/RouterSequencerCrossTalk.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface ISushiXSwap {
    function cook(
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas
    ) external payable;
}

contract RouterSushi is RouterSequencerCrossTalk, AccessControl {
    using SafeERC20 for IERC20;
    bytes4 constant RECEIVE_SELECTOR = bytes4(keccak256("receiveCrossChain(bytes,address,uint256)"));

    address public sushiXSwap;

    struct RouterTeleportParams {
        bytes _erc20Data; // data for token transfer received using router api
        bytes _swapData; // data for swap received using router api
        uint8 _chainID; // router dest chain id
        address to; // receiver bridge token incase of transaction reverts on dest chain
        uint256 _crossChainGasLimit; // gas limit to be sent for dest chain operations
        uint256 _crossChainGasPrice; // gas price to be sent for dest chain operations
        bytes32 srcContext; // random bytes32 as source context
    }

    /// find the addresses at https://dev.routerprotocol.com/sequencer-crosstalk-library/deployment-addresses
    constructor(
        address _sequencerHandler,
        address _erc20handler,
        address _reservehandler,
        address _sushiXSwap
    ) RouterSequencerCrossTalk(_sequencerHandler, _erc20handler, _reservehandler) {
        sushiXSwap = _sushiXSwap;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function to set the linker address
    /// @dev Only DEFAULT_ADMIN can call this function
    /// @param _linker Address of the linker
    function setLinker(address _linker) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setLink(_linker);
    }

    /// @notice Function to set the fee token address
    /// @dev Only DEFAULT_ADMIN can call this function
    /// @param _feeToken Address of the fee token
    function setFeesToken(address _feeToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setFeeToken(_feeToken);
    }

    /// @notice Function to approve the generic handler to cut fees from this contract
    /// @dev Only owner can call this function
    /// @param _feeToken Address of the fee token
    /// @param _amount Amount of approval
    function _approveFees(address _feeToken, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        approveFees(_feeToken, _amount);
    }

    /// @notice Function to set the sushiXSwap contract address which integrates the Router adapter
    /// @dev Only owner can call this function
    /// @param _sushi Address of the sushiXSwap contract that integrates Router adapter
    function setSushiContract(address _sushi) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sushiXSwap = _sushi;
    }

    /// @notice Bridges the token to dest chain using Router Protocol's Bridge
    /// @param params required by Router, can be found at RouterTeleportParams struct.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. Native token amount to send along action.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    function swapAndCall(
        RouterTeleportParams memory params,
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas
    ) external returns (bytes32) {
        // require(msg.sender == sushiXSwap, "only sushiXSwap");
        bytes memory _payload = abi.encode(params.to, actions, values, datas, params.srcContext);
        bytes memory _genericData = abi.encode(RECEIVE_SELECTOR, _payload);

        Params memory _params = Params(
            params._chainID,
            params._erc20Data,
            params._swapData,
            _genericData,
            params._crossChainGasLimit,
            params._crossChainGasPrice,
            this.fetchFeeToken(),
            true,
            false
        );

        (bool success, bytes32 hash) = routerSend(_params);
        require(success, "Unsuccessful");
        return hash;
    }

    /// @notice Function to replay a transaction stuck on the bridge due to insufficient
    /// gas price or limit passed while transacting cross-chain
    /// @param __hash hash returned from the _routerTeleport function
    /// @param _crossChainGasLimit Updated gas limit
    /// @param _crossChainGasPrice Updated gas price
    function replayTx(
        bytes32 __hash,
        uint256 _crossChainGasLimit,
        uint256 _crossChainGasPrice
    ) external {
        require(msg.sender == sushiXSwap, "only sushiXSwap");
        routerReplay(__hash, _crossChainGasLimit, _crossChainGasPrice);
    }

    /// @notice Receiver handler function on dest chain
    /// @param data ABI-Encoded data received from src chain
    /// @param settlementToken bridge token received
    /// @param returnAmount amount of bridge tokens received
    function _routerSyncHandler(
        bytes4, /* selector */
        bytes memory data,
        address settlementToken,
        uint256 returnAmount
    ) internal override returns (bool, bytes memory) {
        // (bool success, ) = sushiXSwap.call(
        //     abi.encodeWithSelector(
        //         0x5fe987d4, // receiveCrossChain(bytes memory data, address settlementToken, uint256 returnAmount)
        //         data,
        //         settlementToken,
        //         returnAmount
        //     )
        // );

        (address to, uint8[] memory actions, uint256[] memory values, bytes[] memory datas, bytes32 srcContext) 
            = abi.decode(data, (address, uint8[], uint256[], bytes[], bytes32));
        
        try ISushiXSwap(payable(sushiXSwap)).cook(actions, values, datas) {} catch (bytes memory) {
          IERC20(settlementToken).safeTransfer(to, returnAmount);
      }

        // require(success, "unsuccessful call to sushiXSwap");
        return (true, "");
    }

    function withdrawToken(
        address token,
        address recipient,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        require(amount <= tokenBalance, "insufficient balance in contract");

        if (amount == 0) {
            IERC20(token).transfer(recipient, tokenBalance);
        } else {
            IERC20(token).transfer(recipient, amount);
        }
    }
}