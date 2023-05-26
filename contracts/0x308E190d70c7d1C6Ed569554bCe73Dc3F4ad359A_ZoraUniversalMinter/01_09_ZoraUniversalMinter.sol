// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IZoraUniversalMinter} from "./IZoraUniversalMinter.sol";
import {IMinterAgent} from "./IMinterAgent.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title Zora Universal Minter.
/// @notice Immutable contract that mints tokens on behalf of an account on any standard ER721 or ERC1155 contract, and collects fees for Zora and optionally a rewards for a finder.
contract ZoraUniversalMinter is IZoraUniversalMinter {
    /// @dev Default fee zora collects per token minted
    uint256 constant ZORA_FEE_PER_TOKEN = 0.000222 ether;
    /// @dev Default reward finder collects per token minted
    uint256 constant FINDER_REWARD_PER_TOKEN = 0.000555 ether;
    /// @dev default fee zora collects per token minted when no finder is specified
    uint256 constant ZORA_FEE_PER_TOKEN_WHEN_NO_FINDER = ZORA_FEE_PER_TOKEN + FINDER_REWARD_PER_TOKEN;
    /// @dev Rewards allocated to addresses that can be withdran from later
    mapping(address => uint256) rewardAllocations;
    /// @dev How much has been withdrawn so far by each address
    mapping(address => uint256) withdrawn;

    /// @dev The address of the Protocol's fee recipient
    address public immutable zoraFeeRecipient;
    /// @dev The address of the minter agent implementation, which is cloned for each EOA
    address public immutable agentImpl;

    constructor(address _minterAgentImpl, address _zoraFeeRecipient) {
        zoraFeeRecipient = _zoraFeeRecipient;
        agentImpl = _minterAgentImpl;
    }

    /// Executes mint calls on a series of target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Adds a mint fee to the msg.value sent to the contract.
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must include all the values to send to the minting contracts and the fees + reward amount.
    /// This can be determined by calling `fee`, and getting the requiredToSend parameter.
    /// @param _targets Addresses of contracts to call
    /// @param _calldatas Data to pass to the mint functions for each target
    /// @param _values Value to send to each target - must match the value required by the target's mint function.
    /// @param _tokensMinted Total number of tokens minted across all targets, used to calculate fees
    /// @param _finder Optional - address of finder that will receive a portion of the fees
    function mintBatch(
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values,
        uint256 _tokensMinted,
        address _finder
    ) external payable {
        uint256 totalValue = _uncheckedSum(_values);

        // calculate fees
        (uint256 zoraFee, uint256 finderReward, uint256 totalWithFees) = fee(totalValue, _tokensMinted, _finder);

        emit MintedBatch(_targets, _values, _tokensMinted, _finder, msg.sender, totalWithFees, zoraFee, finderReward);

        // allocate the fees to the mint fee receiver and finder, which can be withdrawn against later.  Validates
        // that proper value has been sent.
        _allocateFeesAndRewards(zoraFee, finderReward, totalWithFees, _finder);

        _mintAll(msg.sender, totalValue, _targets, _calldatas, _values);
    }

    /// @notice Executes mint calls on a series of target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Does not add a mint feee
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must equal the total values to send to the minting contracts.
    /// @param _targets Addresses of contracts to call
    /// @param _calldatas Data to pass to the mint functions for each target
    /// @param _values Value to send to each target - must match the value required by the target's mint function.
    function mintBatchWithoutFees(address[] calldata _targets, bytes[] calldata _calldatas, uint256[] calldata _values) external payable {
        uint256 totalValue = _uncheckedSum(_values);

        // make sure that enough value was sent to cover the fees + values needed to be sent to the contracts
        // Cannot realistically overflow
        if (totalValue != msg.value) {
            revert INSUFFICIENT_VALUE(totalValue, msg.value);
        }

        emit MintedBatch(_targets, _values, 0, address(0), msg.sender, 0, 0, 0);

        _mintAll(msg.sender, totalValue, _targets, _calldatas, _values);
    }

    /// Execute a mint call on a series a target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Adds a mint fee to the msg.value sent to the contract.
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must include the value to send to the minting contract and the universal minter fee + finder reward amount.
    /// This can be determined by calling `fee`, and getting the requiredToSend parameter.
    /// @param _target Addresses of contract to call
    /// @param _calldata Data to pass to the mint function for the target
    /// @param _value Value to send to the target - must match the value required by the target's mint function.
    /// @param _tokensMinted Total number of tokens minted across all targets, used to calculate fees
    /// @param _finder Optional - address of finder that will receive a portion of the fees
    function mint(address _target, bytes calldata _calldata, uint256 _value, uint256 _tokensMinted, address _finder) external payable {
        IMinterAgent agent = _getOrCloneAgent(msg.sender);

        (uint256 zoraFee, uint256 finderReward, uint256 totalWithFees) = fee(_value, _tokensMinted, _finder);

        emit Minted(_target, _value, _tokensMinted, _finder, msg.sender, totalWithFees, zoraFee, finderReward);

        // allocate the fees to the mint fee receiver and rewards to the finder, which can be withdrawn against later
        _allocateFeesAndRewards(zoraFee, finderReward, totalWithFees, _finder);

        // mint the fokens for each target contract.  These will be transferred to the msg.caller.
        _mint(agent, _target, _calldata, _value);
    }

    /// Withdraws any fees that have been allocated to the caller's address to a specified address.
    /// @param to The address to withdraw to
    function withdraw(address to) external {
        uint256 feeAllocation = rewardAllocations[msg.sender];

        uint256 withdrawnSoFar = withdrawn[msg.sender];

        if (feeAllocation <= withdrawnSoFar) {
            revert NOTHING_TO_WITHDRAW();
        }

        uint256 toWithdraw = feeAllocation - withdrawnSoFar;

        withdrawn[msg.sender] = withdrawnSoFar + toWithdraw;

        _safeSend(toWithdraw, to);
    }

    /// Calculates the fees that will be collected for a given mint, based on the value and tokens minted.
    /// @param _mintValue Total value of the mint
    /// @param _tokensMinted Quantity of tokens minted
    /// @param _finderAddress Address of the finder, if any.  If the finder is the zora fee recipient, then the finder fee is 0.
    /// @return zoraFee The fee that will be allocated to the zora fee recipient
    /// @return finderReward The reward that will be allcoated to the finder
    /// @return requiredToSend The total value that must be sent to the contract, including fees
    function fee(
        uint256 _mintValue,
        uint256 _tokensMinted,
        address _finderAddress
    ) public view returns (uint256 zoraFee, uint256 finderReward, uint256 requiredToSend) {
        if (_finderAddress == address(0) || _finderAddress == zoraFeeRecipient) {
            unchecked {
                zoraFee = ZORA_FEE_PER_TOKEN_WHEN_NO_FINDER * _tokensMinted;
                requiredToSend = zoraFee + _mintValue;
            }
        } else {
            unchecked {
                zoraFee = ZORA_FEE_PER_TOKEN * _tokensMinted;
                finderReward = FINDER_REWARD_PER_TOKEN * _tokensMinted;
                requiredToSend = zoraFee + finderReward + _mintValue;
            }
        }
    }

    /// Has a minter agent execute a transaction on behalf of the calling acccount.  The minter
    /// agent's address will be the same for the calling account as the address that was
    /// used to mint the tokens.  Can be used to recover tokens that may get accidentally locked in
    /// the minter agent's contract address.
    /// @param _target Address of contract to call
    /// @param _calldata Calldata for arguments to call.
    function forwardCallFromAgent(address _target, bytes calldata _calldata, uint256 _additionalValue) external payable {
        IMinterAgent agent = _getOrCloneAgent(msg.sender);

        (bool success, bytes memory result) = agent.forwardCall{value: msg.value}(_target, _calldata, msg.value + _additionalValue);

        if (!success) {
            _handleForwardCallFail(result);
        }
    }

    /// @dev Unwraps a forward call failure to return the original error.  Useful
    /// for debugging failed minting calls.
    function _handleForwardCallFail(bytes memory result) private pure {
        // source: https://yos.io/2022/07/16/bubbling-up-errors-in-solidity/#:~:text=An%20inline%20assembly%20block%20is,object%20is%20returned%20in%20result%20.
        // if no error message, revert with generic error
        if (result.length == 0) {
            revert FORWARD_CALL_FAILED();
        }
        assembly {
            // We use Yul's revert() to bubble up errors from the target contract.
            revert(add(32, result), mload(result))
        }
    }

    /// Gets the deterministic address of the MinterAgent clone that gets created for a given recipient.
    /// @param recipient The account that the agent is cloned on behalf of.
    function agentAddress(address recipient) public view returns (address) {
        return Clones.predictDeterministicAddress(agentImpl, _agentSalt(recipient));
    }

    /// Creates a clone of an agent contract, which mints tokens on behalf of the msg.sender.  If a clone has already been created
    /// for that account, returns it.  Clone address is deterministic based on the recipient's address.
    /// Sends all tokens received as a result of minting to the recipient.
    /// @param callingAccount the account to receive tokens minted by this cloned agent.
    /// @return agent the created agent
    function _getOrCloneAgent(address callingAccount) private returns (IMinterAgent agent) {
        address targetAddress = agentAddress(callingAccount);
        if (targetAddress.code.length > 0) {
            return IMinterAgent(targetAddress);
        }

        address cloneAddress = Clones.cloneDeterministic(agentImpl, _agentSalt(callingAccount));
        agent = IMinterAgent(cloneAddress);
        agent.initialize(address(this), callingAccount);
    }

    /// @dev Unique salt generated from an address for a callingAccount that a MinterAgent is create for.
    function _agentSalt(address callingAccount) private pure returns (bytes32) {
        return bytes32(uint256(uint160(callingAccount)) << 96);
    }

    function _mint(IMinterAgent _agent, address _target, bytes calldata _calldata, uint256 _value) private {
        (bool success, bytes memory result) = _agent.forwardCall{value: _value}(_target, _calldata, _value);

        if (!success) {
            _handleForwardCallFail(result);
        }
    }

    /// @dev Iterates through minting calls and calls them each via a IMinterAgent.
    function _mintAll(
        address callingAccount,
        uint256 totalValueToSend,
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values
    ) private {
        IMinterAgent _agent = _getOrCloneAgent(callingAccount);

        (bool success, bytes memory result) = _agent.forwardCallBatch{value: totalValueToSend}(_targets, _calldatas, _values);

        if (!success) {
            _handleForwardCallFail(result);
        }
    }

    /// Allocates fees and rewards which can be withdrawn against later.
    /// Validates that the proper value has been sent by the calling account.
    function _allocateFeesAndRewards(uint256 zoraFee, uint256 finderReward, uint256 requiredToBeSent, address finder) private {
        // make sure that the correct amount was sent
        if (requiredToBeSent != msg.value) {
            revert INSUFFICIENT_VALUE(requiredToBeSent, msg.value);
        }

        rewardAllocations[zoraFeeRecipient] += zoraFee;
        if (finderReward > 0) {
            rewardAllocations[finder] += finderReward;
        }
    }

    function _safeSend(uint256 amount, address to) private {
        (bool success, ) = to.call{value: amount}("");

        if (!success) revert FAILED_TO_SEND();
    }

    function _uncheckedSum(uint256[] calldata _values) private pure returns (uint256 totalValue) {
        unchecked {
            for (uint256 i = 0; i < _values.length; i++) {
                totalValue += _values[i];
            }
        }
    }
}