/*
            ,« ⁿφφ╔╓,
         ,φ░╚╚    ╘▒▒▒φ,                                              
        φ░          ╠░▒▒φ        ▄████▄                 █▌          ██▀▀▀
       φ             ▒░░▒▒     ▄██    ██▌  ▄▄▄▄▄    ▄▄▄██▌   ▄▄▄   ▐██▄▄  ▄▄   ▄▄
       ░             ╚░░░░     ██      ██ ▐█▌  ██ ▐██   █▌ ██   ██ ▐█▌    ▐█▌ ▐█▌
       ░             ░░░░▒     ██▄    ▄██ ▐█▌  ██ ▐██   █▌ ██▀▀▀▀▀ ▐█▌     ██ ██
        ░           φ░░░░       ▀██████▀  ▐█▌  ██  ▀█████▌  █████  ▐█▌      ███
         ⁿ░≥»,    ,φ░░░∩                                                  ▄▄██
           `ⁿ≥ ,«φ░≥ⁿ`                                                    
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AdapterBase.sol";

/**
// @title Ondefy Router
// @notice Acts as the registry for DEX aggregator adapters
// @author Ondefy
*/
contract Router is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;
    address internal constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private agent;

    address private ftatInputToken;

    uint16 private feeRateBps;

    event AgentshipTransferred(address oldAgent, address newAgent);

    event NewAdapter(address adapter, uint256 index);

    event FeeRateChange(uint16 indexed newFeeRateBps);

    struct Adapter {
        address deployedContract;
        bool isActivated;
    }

    /**
    // @dev The registry of adapters
    // 0 for 0x, 1 for 1inch, 2 for Paraswap... 
    */
    mapping(uint256 => Adapter) public adapters;

    /**
     * @dev Initializes the contract. Inherits parent constructor and sets the agent.
     */
    constructor(address _agent, uint16 _feeRateBps, address _ftatInputToken) Ownable() {
        transferAgentship(_agent);
        setFeeRate( _feeRateBps);
        setFtatInput(_ftatInputToken);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getAgent() public view returns (address) {
        return agent;
    }

    /**
     * @dev Returns the address of the current ftat input token.
     */
    function getFtatInputToken() public view returns (address) {
        return ftatInputToken;
    }

    /**
     * @dev Returns the fixed swap operation fee expressed in bps (not for FTAT operations).
     */
    function getFeeRateBps() public view returns (uint16) {
        return feeRateBps;
    }

    /**
     * @dev Throws if called by any account other than the agent.
     */
    modifier onlyAgent {
        require(agent == _msgSender(), "CALLER_IS_NOT_AGENT");
        _;
    }

    /**
    // @dev Allows contract to receive ether
    */
    receive() external payable {}

    /**
    // @dev Transfer funds and data to selected adapter in order to request swap execution
    // @param _adapterIndex index of the adapter to call
    // @param _inputToken input token address
    // @param _inputAmount swap input amount
    // @param _outputToken output token address
    // @param _swapCallData swap callData (intended for one specific protocol)
    // @notice swap amount in @param _swapCallData must be equal to @param _inputAmount - fee
    */
    function swap(uint256 _adapterIndex, address _inputToken, uint256 _inputAmount, address _outputToken, bytes memory _swapCallData) public payable {
        require(adapters[_adapterIndex].deployedContract != address(0), "ADAPTER_NOT_DEPLOYED");
        require(adapters[_adapterIndex].isActivated, "ADAPTER_NOT_ACTIVATED");
        require(_inputToken != _outputToken, "SAME_INPUT_AND_OUTPUT_TOKENS");

        uint256 fee = computeSwapFee(_inputAmount);
        uint256 swapInputAmount = _inputAmount - fee;
        address payable adapter = payable(adapters[_adapterIndex].deployedContract);
        if (_inputToken != NATIVE) {
            IERC20(_inputToken).safeTransferFrom(msg.sender, getAgent(), fee);
            IERC20(_inputToken).safeTransferFrom(msg.sender, address(adapters[_adapterIndex].deployedContract), swapInputAmount);
            AdapterBase(adapter).callAction(msg.sender, _inputToken, swapInputAmount, _outputToken, _swapCallData);
        } else {
            payable(getAgent()).transfer(fee);
            AdapterBase(adapter).callAction{value: swapInputAmount}(msg.sender, _inputToken, swapInputAmount, _outputToken, _swapCallData);
        }
    }

    function ftatSwapWithPermit(
        address _onBehalfOf,
        uint256 _adapterIndex,
        uint256 _permitAmount,
        uint256 _inputFee,
        uint256 _swapInputAmount,
        address _outputToken,
        bytes memory _swapCallData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable onlyAgent {
        require(adapters[_adapterIndex].deployedContract != address(0), "ADAPTER_NOT_DEPLOYED");
        require(adapters[_adapterIndex].isActivated, "ADAPTER_NOT_ACTIVATED");
        require(_permitAmount >= _swapInputAmount + _inputFee, "PERMIT_AMOUNT_TOO_LOW");

        IERC20Permit(ftatInputToken).safePermit(_onBehalfOf, address(this), _permitAmount, deadline, v, r, s);

        IERC20(ftatInputToken).safeTransferFrom(_onBehalfOf, getAgent(), _inputFee);
        
        address payable adapter = payable(adapters[_adapterIndex].deployedContract);
        IERC20(ftatInputToken).safeTransferFrom(_onBehalfOf, adapter, _swapInputAmount);
        AdapterBase(adapter).callAction(_onBehalfOf, ftatInputToken, _swapInputAmount, _outputToken, _swapCallData);
    }

    /**
    // @dev Computes swap fee for a given amount
    // @param amount amount to swap
    */
    function computeSwapFee(uint256 amount) public view returns (uint) {
        return (5000 + (amount * feeRateBps)) / 10000;
    }

    // Only owner functions

    /**
    // @dev Activates selected adapters
    // @param index adapter index
    */
    function activateAdapter(uint256 index) public onlyOwner {
        require(adapters[index].deployedContract != address(0), "ADAPTER_NOT_DEPLOYED");
        require(!adapters[index].isActivated, "ADAPTER_ALREADY_ACTIVATED");
        adapters[index].isActivated = true;
    }

    /**
    // @dev Deactivates selected adapters
    // @param index adapter index
    */
    function deactivateAdapter(uint256 index) public onlyOwner {
        require(adapters[index].deployedContract != address(0), "ADAPTER_NOT_DEPLOYED");
        require(adapters[index].isActivated, "ADAPTER_ALREADY_DEACTIVATED");
        adapters[index].isActivated = false;
    }

    /**
    // @dev Modifies adapter at given index
    // @param index adapter index
    // @param _deployedContract address of the deployed contract
    // @param _isActivated true for activating right away, false otherwise
    // @dev an adapter must be already present at given index
    */
    function modifyAdapter(uint256 index, address _deployedContract, bool _isActivated) public onlyOwner {
        adapters[index].deployedContract = _deployedContract;
        adapters[index].isActivated = _isActivated;
        emit NewAdapter(_deployedContract, index);
    }

    /**
    // @dev Adds adapter at given index
    // @param index adapter index
    // @param _deployedContract address of the deployed contract
    // @param _isActivated true for activating right away, false otherwise
    // @dev no adapter should be already present at given index
    */
    function addAdapter(uint256 index, address _deployedContract, bool _isActivated) public onlyOwner {
        require(adapters[index].deployedContract == address(0), "EXISTING_ADAPTER_AT_GIVEN_INDEX");
        modifyAdapter(index, _deployedContract, _isActivated);
    }

    /**
    // @dev Sets fee rate
    // @param _feeRateBps fee rate in bps
    */
    function setFeeRate(uint16 _feeRateBps) public onlyOwner {
        require(_feeRateBps < 10000, "INVALID_FEE_RATE");
        feeRateBps = _feeRateBps;
        emit FeeRateChange(_feeRateBps);
    }

    /**
    // @dev Transfers contract funds to userAddress
    // @param token token address, see NATIVE constant above for native asset transfer
    // @param recipient recipient of the transfer
    // @param amount amount to transfer
    */
    function rescueFunds(address token, address recipient, uint256 amount) public onlyOwner {
        if (token != NATIVE) {
            IERC20(token).safeTransfer(recipient, amount);
        } else {
            payable(recipient).transfer(amount);
        }
    }

    /**
    // @dev Transfers adapter funds to userAddress
    // @param index adapter index
    // @param token token address, see NATIVE constant above for native asset transfer
    // @param recipient recipient of the transfer
    // @param amount amount to transfer
    */
    function redeemAdapterFunds(uint256 index, address token, address recipient, uint256 amount) public onlyOwner {
        AdapterBase(payable(adapters[index].deployedContract)).rescueFunds(token, recipient, amount);
    }

    /**
    // @dev Transfers given adapater governance to _newGovernance
    // @param index adapter index
    // @param _newGovernance address of the new governance contract
    // @dev the new governance contract must implement necessary functions to manage adapter governance and actions
    */
    function transferGovernance(uint256 index, address _newGovernance) public onlyOwner {
        AdapterBase(payable(adapters[index].deployedContract)).transferGovernance(_newGovernance);
    }

    /**
     * @dev Transfers agentship of the Router to _newAgent
     * @param _agent new agent
     */
    function transferAgentship(address _agent) public virtual onlyOwner {
        require(_agent != address(0), "ZERO_ADDRESS_FORBIDDEN");
        address oldAgent = agent;
        agent = _agent;
        emit OwnershipTransferred(oldAgent, _agent);
    }

    /**
     * @dev Sets FTAT input token and associated fee
     * @param _ftatInputToken new FTAT input token
     */
    function setFtatInput(address _ftatInputToken) public virtual onlyOwner {
        require(_ftatInputToken != address(0), "ZERO_ADDRESS_FORBIDDEN");
        ftatInputToken = _ftatInputToken;
    }
}