pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { ILPTokenInit } from "../interfaces/ILPTokenInit.sol";
import { ILiquidStakingManagerChildContract } from "../interfaces/ILiquidStakingManagerChildContract.sol";
import { ITransferHookProcessor } from "../interfaces/ITransferHookProcessor.sol";

contract LPToken is ILPTokenInit, ILiquidStakingManagerChildContract, Initializable, ERC20PermitUpgradeable {

    uint256 constant MIN_TRANSFER_AMOUNT = 0.001 ether;

    /// @notice Contract deployer that can control minting and burning but is associated with a liquid staking manager
    address public deployer;

    /// @notice Optional hook for processing transfers
    ITransferHookProcessor transferHookProcessor;

    /// @notice Whenever the address last interacted with a token
    mapping(address => uint256) public lastInteractedTimestamp;

    modifier onlyDeployer {
        require(msg.sender == deployer, "Only savETH vault");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _deployer Address of the account deploying the LP token
    /// @param _transferHookProcessor Optional contract account that can be notified about transfer hooks
    function init(
        address _deployer,
        address _transferHookProcessor,
        string calldata _tokenSymbol,
        string calldata _tokenName
    ) external override initializer {
        deployer = _deployer;
        transferHookProcessor = ITransferHookProcessor(_transferHookProcessor);
        __ERC20_init(_tokenName, _tokenSymbol);
        __ERC20Permit_init(_tokenName);
    }

    /// @notice Mints a given amount of LP tokens
    /// @dev Only savETH vault can mint
    function mint(address _recipient, uint256 _amount) external onlyDeployer {
        _mint(_recipient, _amount);
    }

    /// @notice Allows a LP token owner to burn their tokens
    function burn(address _recipient, uint256 _amount) external onlyDeployer {
        _burn(_recipient, _amount);
    }

    /// @notice In order to know the liquid staking network and manager associated with the LP token, call this
    function liquidStakingManager() external view returns (address) {
        return ILiquidStakingManagerChildContract(deployer).liquidStakingManager();
    }

    /// @dev If set, notify the transfer hook processor before token transfer
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        require(_amount >= MIN_TRANSFER_AMOUNT, "Min transfer amount");
        require(_from != _to, "Self transfer");
        if (address(transferHookProcessor) != address(0)) transferHookProcessor.beforeTokenTransfer(_from, _to, _amount);
    }

    /// @dev If set, notify the transfer hook processor after token transfer
    function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        lastInteractedTimestamp[_from] = block.timestamp;
        lastInteractedTimestamp[_to] = block.timestamp;
        if (address(transferHookProcessor) != address(0)) transferHookProcessor.afterTokenTransfer(_from, _to, _amount);
    }
}