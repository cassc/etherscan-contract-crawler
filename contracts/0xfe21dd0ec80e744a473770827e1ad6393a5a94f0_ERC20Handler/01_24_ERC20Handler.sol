// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IDepositExecute.sol";
import "./HandlerHelpers.sol";
import "../ERC20Safe.sol";
import "../interfaces/IBridge.sol";
import "../interfaces/IDAO.sol";

/**
    @title Handles ERC20 deposits and deposit executions.
    @author ChainSafe Systems.
    @notice This contract is intended to be used with the Bridge contract.
 */
contract ERC20Handler is IDepositExecute, HandlerHelpers, ERC20Safe {
    event DepositERC20(address indexed tokenAddress, uint8 indexed destinationDomainID, address indexed sender, uint256 amount, uint256 fee, uint256 amountWithFee);
    IBridge private contractBridge;
    IDAO private contractDAO;
    address private treasuryAddress;

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
        @param _treasuryAddress Contract address of previously deployed Treasury.
     */
    constructor(address bridgeAddress, address _treasuryAddress) public HandlerHelpers(bridgeAddress) {
        contractBridge = IBridge(bridgeAddress);
        treasuryAddress = _treasuryAddress;
    }

    /**
        @notice Gets treasury address, which will receive fee from custom bridged ERC20 tokens
        @return Treasury address
    */
    function getTreasuryAddress() external view returns(address) {
        return treasuryAddress;
    }

    /**
        @notice Gets DAO address, which will change treasury address
        @return DAO address
    */
    function getDAOAddress() external view returns(address) {
        return address(contractDAO);
    }

    /**
        @notice Sets DAO contract address only once
        @param _address The DAO address
     */
    function setDAOContractInitial(address _address) external {
        require(address(contractDAO) == address(0), "already set");
        require(_address != address(0), "zero address");
        contractDAO = IDAO(_address);
    }

    /**
        @notice Gets DAO address, which will receive fee from custom bridged ERC20 tokens
        @return DAO address
    */
    function setTreasuryAddress(uint256 id) external returns(address) {
        address newTreasuryAddress = contractDAO.isSetTreasuryAvailable(id);
        treasuryAddress = newTreasuryAddress;
        require(contractDAO.confirmSetTreasuryRequest(id), "confirmed");
    }

    /**
        @notice A deposit is initiatied by making a deposit in the Bridge contract.
        @param destinationDomainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of token to be used for deposit.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data Consists of {amount} padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        amount                      uint256     bytes   0 - 32
        @dev Depending if the corresponding {tokenAddress} for the parsed {resourceID} is
        marked true in {_burnList}, deposited tokens will be burned, if not, they will be locked.
        @return an empty data.
     */
    function deposit(
        uint8 destinationDomainID,
        bytes32 resourceID,
        address depositer,
        bytes   calldata data
    ) external override onlyBridge returns (bytes memory) {
        uint256        amount;
        (amount) = abi.decode(data, (uint));

        address tokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[tokenAddress], "provided tokenAddress is not whitelisted");

        uint256 feeValue = evaluateFee(destinationDomainID, tokenAddress, amount);
        uint256 transferAmount = amount - feeValue;

        lockERC20(tokenAddress, depositer, treasuryAddress, feeValue);
        if (_burnList[tokenAddress]) {
            burnERC20(tokenAddress, depositer, transferAmount);
        } else {
            lockERC20(tokenAddress, depositer, address(this), transferAmount);
        }
        emit DepositERC20(tokenAddress, destinationDomainID, depositer, amount, feeValue, transferAmount);
    }

    /**
        @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
        by a relayer on the deposit's destination chain.
        @param destinationDomainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of token to be used for deposit.
        @param data Consists of {resourceID}, {amount}, {lenDestinationRecipientAddress},
        and {destinationRecipientAddress} all padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        amount                                 uint256     bytes  0 - 32
        destinationRecipientAddress length     uint256     bytes  32 - 64
        destinationRecipientAddress            bytes       bytes  64 - END
     */
    function executeProposal(uint8 destinationDomainID, bytes32 resourceID, bytes calldata data) external override onlyBridge {
        uint256       amount;
        uint256       lenDestinationRecipientAddress;
        bytes  memory destinationRecipientAddress;

        (amount, lenDestinationRecipientAddress) = abi.decode(data, (uint, uint));
        destinationRecipientAddress = bytes(data[64:64 + lenDestinationRecipientAddress]);

        bytes20 recipientAddress;
        address tokenAddress = _resourceIDToTokenContractAddress[resourceID];

        assembly {
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }

        require(_contractWhitelist[tokenAddress], "provided tokenAddress is not whitelisted");

        uint256 feeValue = evaluateFee(destinationDomainID, tokenAddress, amount);
        uint256 transferAmount = amount - feeValue;

        if (_burnList[tokenAddress]) {
            mintERC20(tokenAddress, address(recipientAddress), transferAmount);
        } else {
            releaseERC20(tokenAddress, address(recipientAddress), transferAmount);
        }
    }

    /**
        @notice Used to manually release ERC20 tokens from ERC20Safe.
        @param data Consists of {tokenAddress}, {recipient}, and {amount} all padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        tokenAddress                           address     bytes  0 - 32
        recipient                              address     bytes  32 - 64
        amount                                 uint        bytes  64 - 96
     */
    function withdraw(bytes memory data) external override onlyBridge {
        address tokenAddress;
        address recipient;
        uint amount;

        (tokenAddress, recipient, amount) = abi.decode(data, (address, address, uint));

        releaseERC20(tokenAddress, recipient, amount);
    }

    function evaluateFee(uint8 destinationDomainID, address tokenAddress, uint256 amount) private view returns (uint256 fee) {
        (uint256 basicFee, uint256 minAmount, uint256 maxAmount) = contractBridge.getFee(tokenAddress, destinationDomainID);
        require(minAmount <= amount, "amount < min amount");
        require(maxAmount >= amount, "amount > max amount");

        fee = amount * contractBridge.getFeePercent() / contractBridge.getFeeMaxValue();
        if(fee < basicFee) {
            fee = basicFee;
        }
    }
}