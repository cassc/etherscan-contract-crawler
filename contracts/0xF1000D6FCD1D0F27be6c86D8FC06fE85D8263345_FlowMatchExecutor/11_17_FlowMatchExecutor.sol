// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { FlowMatchExecutorTypes } from "../libs/FlowMatchExecutorTypes.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { SignatureChecker } from "../libs/SignatureChecker.sol";
import { IFlowExchange } from "../interfaces/IFlowExchange.sol";

/**
@title FlowMatchExecutor
@author Joe
@notice The contract that is called to execute order matches
*/
contract FlowMatchExecutor is
    IERC1271,
    IERC721Receiver,
    Ownable,
    Pausable,
    SignatureChecker
{
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    IFlowExchange public immutable exchange;
    IERC20 public immutable weth;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
      //////////////////////////////////////////////////////////////*/
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
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier netNonNegative() {
        uint256 initialBalance = address(this).balance +
            weth.balanceOf(address(this));
        _;
        uint256 finalBalance = address(this).balance +
            weth.balanceOf(address(this));

        require(
            finalBalance >= initialBalance,
            "Transaction not non-negative"
        );
    }

    modifier onlyInitiator() {
        require(msg.sender == initiator, "only initiator can call");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(IFlowExchange _exchange, address _initiator, address _weth) {
        exchange = _exchange;
        initiator = _initiator;
        weth = IERC20(_weth);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    ///////////////////////////////////////////////// OVERRIDES ///////////////////////////////////////////////////////

    // returns the magic value if the message is signed by the owner of this contract, invalid value otherwise
    function isValidSignature(
        bytes32 message,
        bytes calldata signature
    ) external view override returns (bytes4) {
        _assertValidSignatureHelper(initiator, message, signature);
        return 0x1626ba7e; // EIP-1271 magic value
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
    ) external whenNotPaused onlyInitiator netNonNegative {
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
    ) external whenNotPaused onlyInitiator netNonNegative {
        _matchOrders(matches);
    }

    //////////////////////////////////////////////////// INTERNAL FUNCTIONS ///////////////////////////////////////////////////////

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

        uint256 numNftsToTransfer = externalFulfillments.nftsToTransfer.length;
        if (numNftsToTransfer > 0) {
            for (uint256 i; i < numNftsToTransfer; ) {
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
        (bool _success, bytes memory _result) = params.to.call{
            value: params.value
        }(params.data);
        require(_success, "external call failed");
        return _result;
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