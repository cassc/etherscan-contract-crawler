// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICrossChainERC20.sol";
import "./extensions/ICrossChainERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@routerprotocol/router-crosstalk/contracts/RouterCrossTalk.sol";

/**
 * @dev Implementation of Router CrossTalk in the basic standard token ERC-20.
 *
 * TIP: For a detailed overview see our guide
 * https://dev.routerprotocol.com/crosstalk-library/overview
 */
contract CrossChainERC20 is ERC20, ICrossChainERC20, RouterCrossTalk {
    uint256 private _crossChainGasLimit;

    /**
     * @dev Sets the values for {name}, {symbol} and {genericHandler}
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address genericHandler_
    ) ERC20(name_, symbol_) RouterCrossTalk(genericHandler_) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ICrossChainERC20).interfaceId || interfaceId == type(ICrossChainERC20Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice setCrossChainGasLimit Used to set CrossChainGas, this can only be set by CrossChain Admin or Admins
     * @param _gasLimit Amount of gasLimit that is to be set
     */
    function _setCrossChainGasLimit(uint256 _gasLimit) internal {
        _crossChainGasLimit = _gasLimit;
    }

    /**
     * @notice fetchCrossChainGasLimit Used to fetch CrossChainGas
     * @return crossChainGasLimit that is set
     */
    function fetchCrossChainGasLimit() external view override returns (uint256) {
        return _crossChainGasLimit;
    }

    function transferCrossChain(
        uint8 _chainID,
        address _recipient,
        uint256 _amount,
        uint256 _crossChainGasPrice
    ) public virtual override returns (bool, bytes32) {
        require(_recipient != address(0), "CrossChainERC20: Recipient address cannot be null");
        _burn(msg.sender, _amount);
        (bool success, bytes32 hash) = _sendCrossChain(_chainID, _recipient, _amount, _crossChainGasPrice);
        return (success, hash);
    }

    /**
     * @notice _sendCrossChain This is an internal function to generate a cross chain communication request
     */
    function _sendCrossChain(
        uint8 _chainID,
        address _recipient,
        uint256 _amount,
        uint256 _crossChainGasPrice
    ) internal returns (bool, bytes32) {
        bytes4 _selector = bytes4(keccak256("receiveCrossChain(address,uint256)"));
        bytes memory _data = abi.encode(_recipient, _amount);
        (bool success, bytes32 hash) = routerSend(_chainID, _selector, _data, _crossChainGasLimit, _crossChainGasPrice);
        return (success, hash);
    }

    // The hash returned from RouterSend function should be used to replay a tx
    // These gas limit and gas price should be higher than one entered in the original tx.
    function replayTx(
        bytes32 hash,
        uint256 gasLimit,
        uint256 gasPrice
    ) internal {
        routerReplay(hash, gasLimit, gasPrice);
    }

    /**
     * @notice _routerSyncHandler This is an internal function to control the handling of various selectors and its corresponding
     * @param _selector Selector to interface.
     * @param _data Data to be handled.
     */
    function _routerSyncHandler(bytes4 _selector, bytes memory _data) internal virtual override returns (bool, bytes memory) {
        (address _recipient, uint256 _amount) = abi.decode(_data, (address, uint256));
        (bool success, bytes memory returnData) = address(this).call(abi.encodeWithSelector(_selector, _recipient, _amount));
        return (success, returnData);
    }

    /**
     * @notice receiveCrossChain Creates `_amount` tokens to `_recipient` on the destination chain
     *
     * NOTE: It can only be called by current contract.
     *
     * @param _recipient Address of the recipient on the destination chain
     * @param _amount Number of tokens
     * @return bool returns true when completed
     */
    function receiveCrossChain(address _recipient, uint256 _amount) external isSelf returns (bool) {
        _mint(_recipient, _amount);
        return true;
    }
}