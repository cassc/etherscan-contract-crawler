//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/Ownable.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketBridgeBase} from "../interfaces/ISocketBridgeBase.sol";

/**
 * @dev In the constructor, set up the initialization code for socket
 * contracts as well as the keccak256 hash of the given initialization code.
 * that will be used to deploy any transient contracts, which will deploy any
 * socket contracts that require the use of a constructor.
 *
 * Socket contract initialization code (29 bytes):
 *
 *       0x5860208158601c335a63aaf10f428752fa158151803b80938091923cf3
 *
 * Description:
 *
 * pc|op|name         | [stack]                                | <memory>
 *
 * ** set the first stack item to zero - used later **
 * 00 58 getpc          [0]                                       <>
 *
 * ** set second stack item to 32, length of word returned from staticcall **
 * 01 60 push1
 * 02 20 outsize        [0, 32]                                   <>
 *
 * ** set third stack item to 0, position of word returned from staticcall **
 * 03 81 dup2           [0, 32, 0]                                <>
 *
 * ** set fourth stack item to 4, length of selector given to staticcall **
 * 04 58 getpc          [0, 32, 0, 4]                             <>
 *
 * ** set fifth stack item to 28, position of selector given to staticcall **
 * 05 60 push1
 * 06 1c inpos          [0, 32, 0, 4, 28]                         <>
 *
 * ** set the sixth stack item to msg.sender, target address for staticcall **
 * 07 33 caller         [0, 32, 0, 4, 28, caller]                 <>
 *
 * ** set the seventh stack item to msg.gas, gas to forward for staticcall **
 * 08 5a gas            [0, 32, 0, 4, 28, caller, gas]            <>
 *
 * ** set the eighth stack item to selector, "what" to store via mstore **
 * 09 63 push4
 * 10 aaf10f42 selector [0, 32, 0, 4, 28, caller, gas, 0xaaf10f42]    <>
 *
 * ** set the ninth stack item to 0, "where" to store via mstore ***
 * 11 87 dup8           [0, 32, 0, 4, 28, caller, gas, 0xaaf10f42, 0] <>
 *
 * ** call mstore, consume 8 and 9 from the stack, place selector in memory **
 * 12 52 mstore         [0, 32, 0, 4, 0, caller, gas]             <0xaaf10f42>
 *
 * ** call staticcall, consume items 2 through 7, place address in memory **
 * 13 fa staticcall     [0, 1 (if successful)]                    <address>
 *
 * ** flip success bit in second stack item to set to 0 **
 * 14 15 iszero         [0, 0]                                    <address>
 *
 * ** push a third 0 to the stack, position of address in memory **
 * 15 81 dup2           [0, 0, 0]                                 <address>
 *
 * ** place address from position in memory onto third stack item **
 * 16 51 mload          [0, 0, address]                           <>
 *
 * ** place address to fourth stack item for extcodesize to consume **
 * 17 80 dup1           [0, 0, address, address]                  <>
 *
 * ** get extcodesize on fourth stack item for extcodecopy **
 * 18 3b extcodesize    [0, 0, address, size]                     <>
 *
 * ** dup and swap size for use by return at end of init code **
 * 19 80 dup1           [0, 0, address, size, size]               <>
 * 20 93 swap4          [size, 0, address, size, 0]               <>
 *
 * ** push code position 0 to stack and reorder stack items for extcodecopy **
 * 21 80 dup1           [size, 0, address, size, 0, 0]            <>
 * 22 91 swap2          [size, 0, address, 0, 0, size]            <>
 * 23 92 swap3          [size, 0, size, 0, 0, address]            <>
 *
 * ** call extcodecopy, consume four items, clone runtime code to memory **
 * 24 3c extcodecopy    [size, 0]                                 <code>
 *
 * ** return to deploy final code in memory **
 * 25 f3 return         []                                        *deployed!*
 */
contract SocketDeployFactory is Ownable {
    using SafeTransferLib for ERC20;
    address public immutable disabledRouteAddress;

    mapping(address => address) _implementations;
    mapping(uint256 => bool) isDisabled;
    mapping(uint256 => bool) isRouteDeployed;
    mapping(address => bool) canDisableRoute;

    event Deployed(address _addr);
    event DisabledRoute(address _addr);
    event Destroyed(address _addr);
    error ContractAlreadyDeployed();
    error NothingToDestroy();
    error AlreadyDisabled();
    error CannotBeDisabled();
    error OnlyDisabler();

    constructor(address _owner, address disabledRoute) Ownable(_owner) {
        disabledRouteAddress = disabledRoute;
        canDisableRoute[_owner] = true;
    }

    modifier onlyDisabler() {
        if (!canDisableRoute[msg.sender]) {
            revert OnlyDisabler();
        }
        _;
    }

    function addDisablerAddress(address disabler) external onlyOwner {
        canDisableRoute[disabler] = true;
    }

    function removeDisablerAddress(address disabler) external onlyOwner {
        canDisableRoute[disabler] = false;
    }

    /**
     * @notice Deploys a route contract at predetermined location
     * @notice Caller must first deploy the route contract at another location and pass its address as implementation.
     * @param routeId route identifier
     * @param implementationContract address of deployed route contract. Its byte code will be copied to predetermined location.
     */
    function deploy(
        uint256 routeId,
        address implementationContract
    ) external onlyOwner returns (address) {
        // assign the initialization code for the socket contract.

        bytes memory initCode = (
            hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );

        // determine the address of the socket contract.
        address routeContractAddress = _getContractAddress(routeId);

        if (isRouteDeployed[routeId]) {
            revert ContractAlreadyDeployed();
        }

        isRouteDeployed[routeId] = true;

        //first we deploy the code we want to deploy on a separate address
        // store the implementation to be retrieved by the socket contract.
        _implementations[routeContractAddress] = implementationContract;
        address addr;
        assembly {
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode) // load init code's length.
            addr := create2(0, encoded_data, encoded_size, routeId) // routeId is used as salt
        }
        require(
            addr == routeContractAddress,
            "Failed to deploy the new socket contract."
        );
        emit Deployed(addr);
        return addr;
    }

    /**
     * @notice Destroy the route deployed at a location.
     * @param routeId route identifier to be destroyed.
     */
    function destroy(uint256 routeId) external onlyDisabler {
        // determine the address of the socket contract.
        _destroy(routeId);
    }

    /**
     * @notice Deploy a disabled contract at destroyed route to handle it gracefully.
     * @param routeId route identifier to be disabled.
     */
    function disableRoute(
        uint256 routeId
    ) external onlyDisabler returns (address) {
        return _disableRoute(routeId);
    }

    /**
     * @notice Destroy a list of routeIds
     * @param routeIds array of routeIds to be destroyed.
     */
    function multiDestroy(uint256[] calldata routeIds) external onlyDisabler {
        for (uint32 index = 0; index < routeIds.length; ) {
            _destroy(routeIds[index]);
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Deploy a disabled contract at list of routeIds.
     * @param routeIds array of routeIds to be disabled.
     */
    function multiDisableRoute(
        uint256[] calldata routeIds
    ) external onlyDisabler {
        for (uint32 index = 0; index < routeIds.length; ) {
            _disableRoute(routeIds[index]);
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev External view function for calculating a socket contract address
     * given a particular routeId.
     */
    function getContractAddress(
        uint256 routeId
    ) external view returns (address) {
        // determine the address of the socket contract.
        return _getContractAddress(routeId);
    }

    //those two functions are getting called by the socket Contract
    function getImplementation()
        external
        view
        returns (address implementation)
    {
        return _implementations[msg.sender];
    }

    function _disableRoute(uint256 routeId) internal returns (address) {
        // assign the initialization code for the socket contract.
        bytes memory initCode = (
            hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );

        // determine the address of the socket contract.
        address routeContractAddress = _getContractAddress(routeId);

        if (!isRouteDeployed[routeId]) {
            revert CannotBeDisabled();
        }

        if (isDisabled[routeId]) {
            revert AlreadyDisabled();
        }

        isDisabled[routeId] = true;

        //first we deploy the code we want to deploy on a separate address
        // store the implementation to be retrieved by the socket contract.
        _implementations[routeContractAddress] = disabledRouteAddress;
        address addr;
        assembly {
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode) // load init code's length.
            addr := create2(0, encoded_data, encoded_size, routeId) // routeId is used as salt.
        }
        require(
            addr == routeContractAddress,
            "Failed to deploy the new socket contract."
        );
        emit Deployed(addr);
        return addr;
    }

    function _destroy(uint256 routeId) internal {
        // determine the address of the socket contract.
        address routeContractAddress = _getContractAddress(routeId);

        if (!isRouteDeployed[routeId]) {
            revert NothingToDestroy();
        }
        ISocketBridgeBase(routeContractAddress).killme();
        emit Destroyed(routeContractAddress);
    }

    /**
     * @dev Internal view function for calculating a socket contract address
     * given a particular routeId.
     */
    function _getContractAddress(
        uint256 routeId
    ) internal view returns (address) {
        // determine the address of the socket contract.

        bytes memory initCode = (
            hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );
        return
            address(
                uint160( // downcast to match the address type.
                    uint256( // convert to uint to truncate upper digits.
                        keccak256( // compute the CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                hex"ff", // start with 0xff to distinguish from RLP.
                                address(this), // this contract will be the caller.
                                routeId, // the routeId is used as salt.
                                keccak256(abi.encodePacked(initCode)) // the init code hash.
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Rescues the ERC20 token to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param token address of the ERC20 token being rescued
     * @param userAddress address to which ERC20 is to be rescued
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice Rescues the native balance to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param userAddress address to which native-balance is to be rescued
     * @param amount amount of native-balance being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external onlyOwner {
        userAddress.transfer(amount);
    }
}