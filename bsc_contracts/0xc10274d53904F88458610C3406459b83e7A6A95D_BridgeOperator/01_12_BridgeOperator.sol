// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-4.8/access/Ownable.sol";
import "openzeppelin-contracts-4.8/security/Pausable.sol";
import "openzeppelin-contracts-4.8/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-4.8/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IOFTWithFee.sol";
import "./interfaces/IMasterChefV2-0.8.17.sol";

contract BridgeOperator is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IOFTWithFee public immutable cakeOft;
    IMasterChefV2 public immutable masterChefV2;
    IERC20 public immutable cake;
    address public operator;

    bool public isInitialized;
    uint16 public immutable APTOS_CHAIN_ID;
    bytes32 public APTOS_OPERATOR_ADDRESS;
    uint256 public immutable pid;

    error NotOperator();

    event Init();
    event SetOperator(address newOperator);
    event SetAptosOperator(bytes32 newAptosOperator);

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        _;
    }

    constructor(
        IOFTWithFee _cakeOft,
        IMasterChefV2 _masterChef,
        uint256 _pid,
        uint16 _aptos_chain_id,
        bytes32 _aptos_operator_address
    ) {
        cakeOft = _cakeOft;
        cake = IERC20(cakeOft.token());
        masterChefV2 = _masterChef;
        pid = _pid;
        APTOS_CHAIN_ID = _aptos_chain_id;
        APTOS_OPERATOR_ADDRESS = _aptos_operator_address;
        operator = owner();

        cake.safeApprove(address(_cakeOft), type(uint256).max);
    }

    /**
     * @notice Deposits a dummy token to `MASTER_CHEF` MCV2.
     */
    function init() external onlyOwner {
        require(!isInitialized, "Already initialized");
        isInitialized = true;
        IERC20 mockLP = masterChefV2.lpToken(pid);
        uint256 balance = mockLP.balanceOf(msg.sender);
        require(balance != 0, "Balance must exceed 0");
        mockLP.safeTransferFrom(msg.sender, address(this), balance);
        mockLP.safeApprove(address(masterChefV2), balance);
        masterChefV2.deposit(pid, balance);
        emit Init();
    }

    function bridgeEmission(
        address refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) external payable onlyOperator whenNotPaused {
        masterChefV2.deposit(pid, 0); // harvest CAKE
        uint256 cakeBalance = cake.balanceOf(address(this));
        cakeOft.sendFrom{value: msg.value}(
            address(this),
            APTOS_CHAIN_ID,
            APTOS_OPERATOR_ADDRESS,
            cakeBalance,
            0,
            ICommonOFT.LzCallParams({
                refundAddress: payable(refundAddress),
                zroPaymentAddress: zroPaymentAddress,
                adapterParams: adapterParams
            })
        );
    }

    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit SetOperator(newOperator);
    }

    function setAptosOperator(bytes32 newAptosOperator) external onlyOwner {
        APTOS_OPERATOR_ADDRESS = newAptosOperator;
        emit SetAptosOperator(newAptosOperator);
    }

    function pauseBridging() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseBridging() external onlyOwner whenPaused {
        _unpause();
    }
}