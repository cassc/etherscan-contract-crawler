// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {NATIVE_TOKEN} from "./constants/Tokens.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {
    EnumerableSetUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FeeCollector is Proxied, Initializable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // solhint-disable var-name-mixedcase
    address public immutable LIFI;

    /// @dev _managers is a list of addresses that can call functions to move funds
    EnumerableSetUpgradeable.AddressSet private _managers;

    /**
     @dev confirmations is the number of blocks that have to be included between endBlock
     and the current block number. Used to avoid refunding transactions that may be reorg'd.
     */
    uint256 public confirmations;

    /**
     @dev prevRefundEndBlockByExecutor stores the end block of the previous refund for each
     executor. Used to track settled refunds and avoid any duplicates or unrefunded blocks.
     */
    mapping(address executor => uint256 prevRefundEndBlock)
        public prevRefundEndBlockByExecutor;

    event LogGasRefund(
        uint256 startBlock,
        uint256 endBlock,
        address recipient,
        uint256 amount
    );

    event LogTransfer(
        address[] tokens,
        address[] recipients,
        uint256[] amounts
    );

    event LogTransferAll(address[] tokens, address[] recipients);

    /**
     @dev senderIsOwnerOrManager is a modifier to restrict access to any function that moves
     funds to only owner or an approved list of managers.
     */
    modifier senderIsOwnerOrManager() {
        require(
            (msg.sender == _proxyAdmin() || isManager(msg.sender)),
            "FeeCollector.senderIsOwnerOrManager"
        );
        _;
    }

    constructor(address _lifi) {
        LIFI = _lifi;
    }

    function initialize(
        uint256 _confirmations
    ) external onlyProxyAdmin initializer {
        confirmations = _confirmations;
    }

    function setConfirmations(uint256 _confirmations) external onlyProxyAdmin {
        confirmations = _confirmations;
    }

    /**
     @dev Triggers a bridge/swap using LI.FI. Calldata is obtained off-chain by calling
     the LI.FI API. Moves funds so only callable by owner or a manger.
     */
    function bridgeViaLifi(
        address _srcToken,
        uint256 _amount,
        bytes calldata _data
    ) external senderIsOwnerOrManager {
        require(
            address(LIFI) != address(0),
            "FeeCollector.bridgeViaLifi: zero address"
        );

        bool isNative = _srcToken == NATIVE_TOKEN;
        if (!isNative) {
            IERC20(_srcToken).safeIncreaseAllowance(address(LIFI), _amount);
        }

        (bool success, ) = isNative
            ? LIFI.call{value: _amount}(_data)
            : LIFI.call(_data);

        require(success, "FeeCollector.bridgeViaLifi: call failed");
    }

    /**
     @dev revokeUnspentAllowances disables allowance for any passed token.
     Needed as operations through LI.FI may lead to leftover allowances which may
     grow over time.
     */
    function revokeUnspentAllowances(
        address[] calldata _tokens
    ) external senderIsOwnerOrManager {
        for (uint256 i; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeApprove(address(LIFI), 0);
        }
    }

    /**
    @dev gasRefund takes care of refunding gas spending for a given
    block range (from startBlock to endBlock, including these 2).
    The refund replay protection is only safe due to access modifier.
    Without it an attacker can submit bogus startBlock and endBlock to bypass
    block-based settlements. But it prevents refund replay racing conditions by using
    endBlock as a refund checkpoint.
    Moves funds so only callable by owner or a manger.
    */
    // solhint-disable-next-line function-max-lines
    function gasRefund(
        uint256[] calldata _startBlocks,
        uint256[] calldata _endBlocks,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external senderIsOwnerOrManager {
        // Checks

        for (uint256 i; i < _recipients.length; i++) {
            uint256 startBlock = _startBlocks[i];
            uint256 endBlock = _endBlocks[i];

            require(
                endBlock > startBlock,
                "FeeCollector.gasRefund: endBlock > startBlock"
            );

            require(
                block.number > endBlock + confirmations,
                "FeeCollector.gasRefund: confirmations"
            );
            uint256 prevRefundEndBlock = prevRefundEndBlockByExecutor[
                _recipients[i]
            ];

            if (prevRefundEndBlock > 0) {
                require(
                    startBlock == prevRefundEndBlock + 1,
                    "FeeCollector.gasRefund: already settled or missing blocks"
                );
            }

            // Effects
            prevRefundEndBlockByExecutor[_recipients[i]] = endBlock;

            // Interactions
            // If a single recipient reverts in the receive function, it would block the whole list
            payable(_recipients[i]).sendValue(_amounts[i]);

            emit LogGasRefund(
                startBlock,
                endBlock,
                _recipients[i],
                _amounts[i]
            );
        }
    }

    /**
    @dev transfer is used to transfer one or more tokens to one or more recipients.
    Tokens, recipients and amounts list lengths have to be equal except recipients
    which is allowed to also contain a recipient.
    Moves funds so only callable by owner or a manger.
    */
    function transfer(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external senderIsOwnerOrManager {
        bool isSingle = _recipients.length == 1;

        require(
            isSingle || _recipients.length == _tokens.length,
            "FeeCollector.transfer: recipients length"
        );

        for (uint256 i; i < _tokens.length; i++) {
            address recipient = isSingle ? _recipients[0] : _recipients[i];

            _tokens[i] == NATIVE_TOKEN
                ? payable(recipient).sendValue(_amounts[i])
                : IERC20(_tokens[i]).safeTransfer(recipient, _amounts[i]);
        }

        emit LogTransfer(_tokens, _recipients, _amounts);
    }

    /**
    @dev transferAll is the same as transfer but transfers the total available amount.
    Moves funds so only callable by owner or a manger.
    */
    function transferAll(
        address[] calldata _tokens,
        address[] calldata _recipients
    ) external senderIsOwnerOrManager {
        bool isSingle = _recipients.length == 1;

        require(
            isSingle || _recipients.length == _tokens.length,
            "FeeCollector.transferAll: recipients length"
        );

        for (uint256 i; i < _tokens.length; i++) {
            address recipient = isSingle ? _recipients[0] : _recipients[i];

            _tokens[i] == NATIVE_TOKEN
                ? payable(recipient).sendValue(address(this).balance)
                : IERC20(_tokens[i]).safeTransfer(
                    recipient,
                    IERC20(_tokens[i]).balanceOf(address(this))
                );
        }

        emit LogTransferAll(_tokens, _recipients);
    }

    /// @dev Only the owner can add a manager
    function addManager(
        address _manager
    ) external onlyProxyAdmin returns (bool) {
        return _managers.add(_manager);
    }

    /// @dev Only the owner can remove a manager
    function removeManager(
        address _manager
    ) external onlyProxyAdmin returns (bool) {
        return _managers.remove(_manager);
    }

    function managerAt(uint256 _index) external view returns (address) {
        return _managers.at(_index);
    }

    function managers() external view returns (address[] memory) {
        return _managers.values();
    }

    function numberOfManagers() external view returns (uint256) {
        return _managers.length();
    }

    function isManager(address _manager) public view returns (bool) {
        return _managers.contains(_manager);
    }

    /**
     @dev getUnspentAllowances computes the leftover allowances on the given list
     of tokens.
     */
    function getUnspentAllowances(
        address[] calldata _tokens
    ) public view returns (uint256[] memory) {
        uint256[] memory unspentAllowances = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            unspentAllowances[i] = IERC20(_tokens[i]).allowance(
                address(this),
                address(LIFI)
            );
        }
        return unspentAllowances;
    }
}