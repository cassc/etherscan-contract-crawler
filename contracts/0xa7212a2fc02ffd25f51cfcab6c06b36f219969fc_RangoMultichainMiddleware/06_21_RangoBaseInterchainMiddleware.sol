// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibInterchain.sol";

// @title The base contract to be used as a parent of middleware classes
// @author George
// @dev Note that this is not a facet and should be extended and deployed separately.
contract RangoBaseInterchainMiddleware {
    /// @dev keccak256("exchange.rango.middleware.base")
    bytes32 internal constant BASE_MIDDLEWARE_CONTRACT_NAMESPACE = hex"ad914d4300c64e1902ca499875cd8a76ae717047bcfaa9e806ff7ea4f6911268";

    struct BaseInterchainMiddlewareStorage {
        address rangoDiamond;
        address owner;
    }

    struct whitelistRequest {
        address contractAddress;
        bytes4[] methodIds;
    }

    constructor(){updateOwnerInternal(tx.origin);}

    function initBaseMiddleware(
        address _owner,
        address _rangoDiamond,
        address _weth
    ) public onlyOwner {
        require(_owner != address(0));
        updateOwnerInternal(_owner);
        updateRangoDiamondInternal(_rangoDiamond);
        LibSwapper.setWeth(_weth);
    }


    /// Events
    /// @notice Emits when the rango diamond address is updated
    /// @param oldAddress The previous address
    /// @param newAddress The new address
    event RangoDiamondAddressUpdated(address oldAddress, address newAddress);
    /// @notice Emits when the weth address is updated
    /// @param oldAddress The previous address
    /// @param newAddress The new address
    event WethAddressUpdated(address oldAddress, address newAddress);
    /// @notice Emits when the owner is updated
    /// @param previousOwner The previous owner
    /// @param newOwner The new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);
    /// @notice Notifies that a new contract is whitelisted
    /// @param _address The address of the contract
    event ContractWhitelisted(address _address);
    /// @notice Notifies that a new contract is whitelisted
    /// @param contractAddress The address of the contract
    /// @param methods The method signatures that are whitelisted for a contractAddress
    event ContractAndMethodsWhitelisted(address contractAddress, bytes4[] methods);
    /// @notice Notifies that a new contract is blacklisted
    /// @param _address The address of the contract
    event ContractBlacklisted(address _address);
    /// @notice Notifies that a contract is blacklisted and the given methods are removed
    /// @param contractAddress The address of the contract
    /// @param methods The method signatures that are blacklisted for the given contractAddress
    event ContractAndMethodsBlacklisted(address contractAddress, bytes4[] methods);
    /// @notice Notifies that a new contract is whitelisted
    /// @param _dapp The address of the contract
    event MessagingDAppWhitelisted(address _dapp);
    /// @notice Notifies that a new contract is blacklisted
    /// @param _dapp The address of the contract
    event MessagingDAppBlacklisted(address _dapp);

    /// @notice used to limit access only to owner
    modifier onlyOwner() {
        require(msg.sender == getBaseInterchainMiddlewareStorage().owner, "should be called only by owner");
        _;
    }

    /// @notice used to limit access only to rango diamond
    modifier onlyDiamond() {
        require(msg.sender == getBaseInterchainMiddlewareStorage().rangoDiamond, "should be called only from diamond");
        _;
    }

    /// @notice Enables the contract to receive native ETH token from other contracts including WETH contract
    receive() external payable {}

    /// Administration & Control

    /// @notice Updates the address of rango diamond contract
    /// @param newAddress The new address of diamond contract
    function updateRangoDiamondAddress(address newAddress) external onlyOwner {
        updateRangoDiamondInternal(newAddress);
    }
    /// @notice Updates the address of weth contract
    /// @param newAddress The new address of weth contract
    function updateWethAddress(address newAddress) external onlyOwner {
        LibSwapper.setWeth(newAddress);
    }
    /// @notice Updates the address of owner
    /// @param newAddress The new address of owner
    function updateOwner(address newAddress) external onlyOwner {
        updateOwnerInternal(newAddress);
    }

    /// @notice Transfers an ERC20 token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _tokenAddress The address of ERC20 token to be transferred
    /// @param _amount The amount of money that should be transfered
    function refund(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 ercToken = IERC20(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, 'Insufficient balance');

        SafeERC20.safeTransfer(IERC20(_tokenAddress), msg.sender, _amount);
        emit Refunded(_tokenAddress, _amount);
    }

    /// @notice Transfers the native token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _amount The amount of native token that should be transferred
    function refundNative(uint256 _amount) external onlyOwner {
        uint balance = address(this).balance;
        require(balance >= _amount, 'Insufficient balance');

        (bool sent,) = msg.sender.call{value : _amount}("");
        require(sent, "failed to send native");

        emit Refunded(LibSwapper.ETH, _amount);
    }

    /// @notice Adds a list of contracts to the whitelisted DEXes that can be called
    /// @param req The requests for whitelisting contracts and methods
    function addWhitelistContractMiddleWare(whitelistRequest[] calldata req) external onlyOwner {
        for (uint i = 0; i < req.length; i++) {
            LibSwapper.addMethodWhitelists(req[i].contractAddress, req[i].methodIds);
            emit ContractAndMethodsWhitelisted(req[i].contractAddress, req[i].methodIds);
            emit ContractWhitelisted(req[i].contractAddress);
        }
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param contractAddress The address of the DEX or dApp
    function removeWhitelistMiddleWare(address contractAddress) external onlyOwner {
        LibSwapper.removeWhitelist(contractAddress);
        emit ContractBlacklisted(contractAddress);
    }

    /// @notice Removes a contract and given method ids
    /// @param contractAddress The address of the contract
    /// @param methodIds The methods to be removed alongside the given contract
    function removeContractAndMethodIdsFromWhitelist(
        address contractAddress,
        bytes4[] calldata methodIds
    ) external onlyOwner {
        LibSwapper.removeWhitelist(contractAddress);
        emit ContractBlacklisted(contractAddress);
        for (uint i = 0; i < methodIds.length; i++) {
            LibSwapper.removeMethodWhitelist(contractAddress, methodIds[i]);
        }
        if (methodIds.length > 0) {
            emit ContractAndMethodsBlacklisted(contractAddress, methodIds);
        }
    }

    /// @notice Adds a list of contracts to the whitelisted messaging dApps that can be called
    /// @param _dapps The addresses of dApps
    function addMessagingDAppsMiddleWare(address[] calldata _dapps) external onlyOwner {
        address dapp;
        for (uint i = 0; i < _dapps.length; i++) {
            dapp = _dapps[i];
            LibInterchain.addMessagingDApp(dapp);
            emit MessagingDAppWhitelisted(dapp);
        }
    }

    /// @notice Removes a contract from dApps that can be called
    /// @param _dapp The address of dApp
    function removeMessagingDAppContractMiddleWare(address _dapp) external onlyOwner {
        LibInterchain.removeMessagingDApp(_dapp);
        emit MessagingDAppBlacklisted(_dapp);
    }


    /// Internal and Private functions
    function updateRangoDiamondInternal(address newAddress) private {
        BaseInterchainMiddlewareStorage storage s = getBaseInterchainMiddlewareStorage();
        address oldAddress = s.rangoDiamond;
        s.rangoDiamond = newAddress;
        emit RangoDiamondAddressUpdated(oldAddress, newAddress);
    }

    function updateOwnerInternal(address newAddress) private {
        BaseInterchainMiddlewareStorage storage s = getBaseInterchainMiddlewareStorage();
        address oldAddress = s.owner;
        s.owner = newAddress;
        emit OwnershipTransferred(oldAddress, newAddress);
    }

    /// @dev fetch local storage
    function getBaseInterchainMiddlewareStorage() private pure returns (BaseInterchainMiddlewareStorage storage s) {
        bytes32 namespace = BASE_MIDDLEWARE_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}