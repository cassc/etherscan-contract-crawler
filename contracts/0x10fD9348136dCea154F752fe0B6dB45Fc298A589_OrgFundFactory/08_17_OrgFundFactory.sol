//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { Registry } from "./Registry.sol";
import { EntityFactory } from "./EntityFactory.sol";
import { Entity } from "./Entity.sol";
import { Org } from "./Org.sol";
import { Fund } from "./Fund.sol";
import { ISwapWrapper } from "./interfaces/ISwapWrapper.sol";

/**
 * @notice This contract is the factory for both the Org and Fund objects.
 */
contract OrgFundFactory is EntityFactory {
    using SafeTransferLib for ERC20;

    /// @notice Placeholder address used in swapping method to denote usage of ETH instead of a token.
    address public constant ETH_PLACEHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The concrete Org used for minimal proxy deployment.
    Org public immutable orgImplementation;

    /// @dev The concrete Fund used for minimal proxy deployment.
    Fund public immutable fundImplementation;

    /// @notice Base Token address is the stable coin used throughout the system.
    ERC20 public immutable baseToken;

    /**
     * @param _registry The Registry this factory will configure Entities to interact with. This factory must be
     * approved on this Registry for it to work properly.
     */
    constructor(Registry _registry) EntityFactory(_registry) {
        orgImplementation = new Org();
        orgImplementation.initialize(_registry, bytes32("IMPL")); // necessary?
        fundImplementation = new Fund();
        fundImplementation.initialize(_registry, address(0));
        baseToken = _registry.baseToken();
    }

    /**
     * @notice Deploys a Fund.
     * @param _manager The address of the Fund's manager.
     * @param _salt A 32-byte value used to create the contract at a deterministic address.
     * @return _fund The deployed Fund.
     */
    function deployFund(address _manager, bytes32 _salt) public returns (Fund _fund) {
        _fund = Fund(payable(Clones.cloneDeterministic(address(fundImplementation), keccak256(bytes.concat(bytes20(_manager), _salt)))));
        _fund.initialize(registry, _manager);
        registry.setEntityActive(_fund);
        emit EntityDeployed(address(_fund), _fund.entityType(), _manager);
    }

    /**
     * @notice Deploys a Fund then pulls base token from the sender and donates to it.
     * @param _manager The address of the Fund's manager.
     * @param _salt A 32-byte value used to create the contract at a deterministic address.
     * @param _amount The amount of base token to donate.
     * @return _fund The deployed Fund.
     */
    function deployFundAndDonate(address _manager, bytes32 _salt, uint256 _amount) external returns (Fund _fund) {
        _fund = deployFund(_manager, _salt);
        _donate(_fund, _amount);
    }

    /**
     * @notice Deploys a new Fund, then pulls a ETH or ERC20 tokens, swaps them to base tokens,
     * and donates to the new Fund.
     * @param _manager The address of the Fund's manager.
     * @param _salt A 32-byte value used to create the contract at a deterministic address.
     * @param _swapWrapper The swap wrapper to use for the donation. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap and donate, or ETH_PLACEHOLDER if donating ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and donated.
     * @param _data Additional call data required by the ISwapWrapper being used.
     * @return _fund The deployed Fund.
     */
    function deployFundSwapAndDonate(
        address _manager,
        bytes32 _salt,
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) external payable returns (Fund _fund) {
        _fund = deployFund(_manager, _salt);
        _swapAndDonate(_fund, _swapWrapper, _tokenIn, _amountIn, _data);
    }

    /**
     * @notice Deploys an Org.
     * @param _orgId The Org's ID for tax purposes.
     * @return _org The deployed Org.
     */
    function deployOrg(bytes32 _orgId) public returns (Org _org) {
        _org = Org(payable(Clones.cloneDeterministic(address(orgImplementation), _orgId)));
        _org.initialize(registry, _orgId);
        registry.setEntityActive(_org);
        emit EntityDeployed(address(_org), _org.entityType(), _org.manager());
    }

    /**
     * @notice Deploys an Org then pulls base token from the sender and donates to it.
     * @param _orgId The Org's ID for tax purposes.
     * @param _amount The amount of base token to donate.
     * @return _org The deployed Org.
     */
    function deployOrgAndDonate(bytes32 _orgId, uint256 _amount) external returns (Org _org) {
        _org = deployOrg(_orgId);
        _donate(_org, _amount);
    }

    /**
     * @notice Deploys a new Org, then pulls a ETH or ERC20 tokens, swaps them to base tokens,
     * and donates to the new Org.
     * @param _orgId The Org's ID for tax purposes.
     * @param _swapWrapper The swap wrapper to use for the donation. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap and donate, or ETH_PLACEHOLDER if donating ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and donated.
     * @param _data Additional call data required by the ISwapWrapper being used.
     * @return _org The deployed Org.
     */
    function deployOrgSwapAndDonate(
        bytes32 _orgId,
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) external payable returns (Org _org) {
        _org = deployOrg(_orgId);
        _swapAndDonate(_org, _swapWrapper, _tokenIn, _amountIn, _data);
    }

    /**
     * @notice Calculates an Org contract's deployment address.
     * @param _orgId Org's tax ID.
     * @return The Org's deployment address.
     * @dev This function is used off-chain by the automated tests to verify proper contract address deployment.
     */
    function computeOrgAddress(bytes32 _orgId) external view returns (address) {
        return Clones.predictDeterministicAddress(address(orgImplementation), _orgId, address(this));
    }

    /**
     * @notice Calculates a Fund contract's deployment address.
     * @param _manager The manager of the fund.
     * @param _salt A 32-byte value used to create the contract at a deterministic address.
     * @return The Fund's deployment address.
     * @dev This function is used off-chain by the automated tests to verify proper contract address deployment.
     */
    function computeFundAddress(address _manager, bytes32 _salt) external view returns (address) {
        return Clones.predictDeterministicAddress(address(fundImplementation), keccak256(bytes.concat(bytes20(_manager), _salt)), address(this));
    }

    /// @dev Pulls base tokens from sender and donates them to the entity.
    function _donate(Entity _entity, uint256 _amount) private {
        // Send tokens directly to the entity, then reconcile its balance. Cheaper than doing a double transfer
        // and calling `donate`.
        baseToken.safeTransferFrom(msg.sender, address(_entity), _amount);
        _entity.reconcileBalance();
    }

    /// @dev Pulls ERC20 tokens, or receives ETH, and swaps and donates them to the entity.
    function _swapAndDonate(
        Entity _entity,
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) private {
        if (_tokenIn != ETH_PLACEHOLDER) {
            ERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            ERC20(_tokenIn).safeApprove(address(_entity), 0);
            ERC20(_tokenIn).safeApprove(address(_entity), _amountIn);
        }

        _entity.swapAndDonate{value: msg.value}(_swapWrapper, _tokenIn, _amountIn, _data);
    }
}