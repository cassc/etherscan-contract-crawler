// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { FlowMatchExecutorTypes } from "../libs/FlowMatchExecutorTypes.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { SignatureChecker } from "../libs/SignatureChecker.sol";
import { IFlowExchange } from "../interfaces/IFlowExchange.sol";

/**
@title FlowMatchExecutor
@author Joe
@notice The contract that is called to execute order matches
*/
contract FlowMatchExecutor is IERC1271, IERC721Receiver, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    IFlowExchange public immutable exchange;

    /*//////////////////////////////////////////////////////////////
                              EXCHANGE STATES
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping to keep track of which exchanges are enabled
    EnumerableSet.AddressSet private _enabledExchanges;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
      //////////////////////////////////////////////////////////////*/
    event EnabledExchangeAdded(address indexed exchange);
    event EnabledExchangeRemoved(address indexed exchange);
    event InitiatorChanged(address indexed oldVal, address indexed newVal);

    ///@notice admin events
    event ETHWithdrawn(address indexed destination, uint256 amount);
    event ERC20Withdrawn(
        address indexed destination,
        address indexed currency,
        uint256 amount
    );

    address public initiator;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(IFlowExchange _exchange, address _initiator) {
        exchange = _exchange;
        initiator = _initiator;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    ///////////////////////////////////////////////// OVERRIDES ///////////////////////////////////////////////////////

    // returns the magic value if the message is signed by the owner of this contract, invalid value otherwise
    function isValidSignature(
        bytes32 message,
        bytes calldata signature
    ) external view override returns (bytes4) {
        (bytes32 r, bytes32 s, bytes32 vBytes) = _decodePackedSig(
            signature,
            32,
            32,
            1
        );
        uint8 v = uint8(uint256(vBytes));
        if (SignatureChecker.recover(message, r, s, v) == owner()) {
            return 0x1626ba7e; // EIP-1271 magic value
        } else {
            return 0xffffffff;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    ///////////////////////////////////////////////// EXTERNAL FUNCTIONS ///////////////////////////////////////////////////////

    /**
     * @notice The entry point for executing brokerage matches. Callable only by owner
     * @param batches The batches of calls to make
     */
    function executeBrokerMatches(
        FlowMatchExecutorTypes.Batch[] calldata batches
    ) external whenNotPaused {
        require(msg.sender == initiator, "only initiator can call");
        uint256 numBatches = batches.length;
        for (uint256 i; i < numBatches; ) {
            _broker(batches[i].externalFulfillments);
            _matchOrders(batches[i].matches);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice The entry point for executing native matches. Callable only by owner
     * @param matches The matches to make
     */
    function executeNativeMatches(
        FlowMatchExecutorTypes.MatchOrders[] calldata matches
    ) external whenNotPaused {
        require(msg.sender == initiator, "only initiator can call");
        _matchOrders(matches);
    }

    //////////////////////////////////////////////////// INTERNAL FUNCTIONS ///////////////////////////////////////////////////////

    /**
     * @notice Decodes abi encodePacked signature. There is no abi.decodePacked so we have to do it manually
     * @param _data The abi encodePacked data
     * @param _la The length of the first parameter i.e r
     * @param _lb The length of the second parameter i.e s
     * @param _lc The length of the third parameter i.e v
     */
    function _decodePackedSig(
        bytes memory _data,
        uint256 _la,
        uint256 _lb,
        uint256 _lc
    ) internal pure returns (bytes32 _a, bytes32 _b, bytes32 _c) {
        uint256 o;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let s := add(_data, 32)
            _a := mload(s)
            let l := sub(32, _la)
            if l {
                _a := div(_a, exp(2, mul(l, 8)))
            }
            o := add(s, _la)
            _b := mload(o)
            l := sub(32, _lb)
            if l {
                _b := div(_b, exp(2, mul(l, 8)))
            }
            o := add(o, _lb)
            _c := mload(o)
            l := sub(32, _lc)
            if l {
                _c := div(_c, exp(2, mul(l, 8)))
            }
            o := sub(o, s)
        }
        require(_data.length >= o, "out of bounds");
    }

    /**
     * @notice broker a trade by fulfilling orders on other exchanges and transferring nfts to the intermediary
     * @param externalFulfillments The specification of the external calls to make and nfts to transfer
     */
    function _broker(
        FlowMatchExecutorTypes.ExternalFulfillments
            calldata externalFulfillments
    ) internal {
        uint256 numCalls = externalFulfillments.calls.length;
        if (numCalls > 0) {
            for (uint256 i; i < numCalls; ) {
                _call(externalFulfillments.calls[i]);
                unchecked {
                    ++i;
                }
            }
        }

        if (externalFulfillments.nftsToTransfer.length > 0) {
            for (uint256 i; i < externalFulfillments.nftsToTransfer.length; ) {
                bool isApproved = IERC721(
                    externalFulfillments.nftsToTransfer[i].collection
                ).isApprovedForAll(address(this), address(exchange));

                if (!isApproved) {
                    IERC721(externalFulfillments.nftsToTransfer[i].collection)
                        .setApprovalForAll(address(exchange), true);
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Execute a call to the specified contract
     * @param params The call to execute
     */
    function _call(
        FlowMatchExecutorTypes.Call memory params
    ) internal returns (bytes memory) {
        if (params.isPayable) {
            require(
                _enabledExchanges.contains(params.to),
                "contract is not enabled"
            );
            (bool _success, bytes memory _result) = params.to.call{
                value: params.value
            }(params.data);
            require(_success, "external MP call failed");
            return _result;
        } else {
            require(params.value == 0, "value not 0 in non-payable call");
            (bool _success, bytes memory _result) = params.to.call(params.data);
            require(_success, "external MP call failed");
            return _result;
        }
    }

    /**
     * @notice Function called to execute a batch of matches by calling the exchange contract
     * @param matches The batch of matches to execute on the exchange
     */
    function _matchOrders(
        FlowMatchExecutorTypes.MatchOrders[] calldata matches
    ) internal {
        uint256 numMatches = matches.length;
        if (numMatches > 0) {
            for (uint256 i; i < numMatches; ) {
                FlowMatchExecutorTypes.MatchOrdersType matchType = matches[i]
                    .matchType;
                if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToOneSpecific
                ) {
                    exchange.matchOneToOneOrders(
                        matches[i].buys,
                        matches[i].sells
                    );
                } else if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToOneUnspecific
                ) {
                    exchange.matchOrders(
                        matches[i].sells,
                        matches[i].buys,
                        matches[i].constructs
                    );
                } else if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToMany
                ) {
                    if (matches[i].buys.length == 1) {
                        exchange.matchOneToManyOrders(
                            matches[i].buys[0],
                            matches[i].sells
                        );
                    } else if (matches[i].sells.length == 1) {
                        exchange.matchOneToManyOrders(
                            matches[i].sells[0],
                            matches[i].buys
                        );
                    } else {
                        revert("invalid one to many order");
                    }
                } else {
                    revert("invalid match type");
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    // ======================================================= VIEW FUNCTIONS ============================================================

    function numEnabledExchanges() external view returns (uint256) {
        return _enabledExchanges.length();
    }

    function getEnabledExchangeAt(
        uint256 index
    ) external view returns (address) {
        return _enabledExchanges.at(index);
    }

    function isExchangeEnabled(address _exchange) external view returns (bool) {
        return _enabledExchanges.contains(_exchange);
    }

    //////////////////////////////////////////////////// ADMIN FUNCTIONS ///////////////////////////////////////////////////////

    function withdrawETH(address destination) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = destination.call{ value: amount }("");
        require(sent, "failed");
        emit ETHWithdrawn(destination, amount);
    }

    /// @dev Used for withdrawing exchange fees paid to the contract in ERC20 tokens
    function withdrawTokens(
        address destination,
        address currency,
        uint256 amount
    ) external onlyOwner {
        IERC20(currency).transfer(destination, amount);
        emit ERC20Withdrawn(destination, currency, amount);
    }

    /**
     * @notice Enable an exchange
     * @param _exchange The exchange to enable
     */
    function addEnabledExchange(address _exchange) external onlyOwner {
        _enabledExchanges.add(_exchange);
        emit EnabledExchangeAdded(_exchange);
    }

    /**
     * @notice Disable an exchange
     * @param _exchange The exchange to disable
     */
    function removeEnabledExchange(address _exchange) external onlyOwner {
        _enabledExchanges.remove(_exchange);
        emit EnabledExchangeRemoved(_exchange);
    }

    function updateInitiator(address _initiator) external onlyOwner {
        address oldVal = initiator;
        initiator = _initiator;
        emit InitiatorChanged(oldVal, _initiator);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}