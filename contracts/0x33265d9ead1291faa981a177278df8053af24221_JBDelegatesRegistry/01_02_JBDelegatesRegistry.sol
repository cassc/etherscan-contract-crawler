// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IJBDelegatesRegistry } from './interfaces/IJBDelegatesRegistry.sol';

/**
 * @title   JBDelegatesRegistry
 *
 * @notice  This contract is used to register deployers of Juicebox Delegates
 *          It is the deployer responsability to register their
 *          delegates in this registry and make sure the delegate implements IERC165
 *
 * @dev     Mostly for front-end integration purposes. The delegate address is computed
 *          from the deployer address and the nonce used to deploy the delegate.
 *      
 */
contract JBDelegatesRegistry is IJBDelegatesRegistry {
    //////////////////////////////////////////////////////////////
    //                                                          //
    //                   ERRORS & EVENTS                        //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    /**
     * @notice Throws if the delegate is not compatible with the Juicebox protocol (based on ERC165)
     */
    error JBDelegatesRegistry_incompatibleDelegate();

    /**
     * @notice Emitted when a deployed delegate is added
     */
    event DelegateAdded(address indexed _delegate, address indexed _deployer);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          CONSTANTS                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice The previous registry, used for retrocompatibility
     */
    IJBDelegatesRegistry public immutable oldRegistry;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  INTERNAL STATE VARIABLES                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Track which deployer deployed a delegate, based on a
     *          proactive deployer update
     */
    mapping(address _delegate => address _deployer) internal _deployerOf;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          CONSTRUCTOR                     //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    constructor(IJBDelegatesRegistry _oldRegistry) {
        oldRegistry = _oldRegistry;
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                 EXTERNAL VIEW FUNCTIONS                  //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the deployer of a delegate
     *
     * @dev     This function prototype mimick the mapping getter from the previous
     *          registry, in order to keep the interface unchanged
     * @param   _delegate The delegate address
     * @return  _deployer The deployer address
     */
    function deployerOf(address _delegate) external view override returns (address _deployer) {
        _deployer = _deployerOf[_delegate];

        // Retrocompatibility: return the entry from the previous registry (if any), if none are found in this one
        if(_deployer == address(0) && oldRegistry != IJBDelegatesRegistry(address(0))) _deployer = oldRegistry.deployerOf(_delegate);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                     EXTERNAL METHODS                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice          Add a delegate to the registry (needs to implement erc165, a delegate type and deployed using create)
     * @param _deployer The address of the deployer of a given delegate
     * @param _nonce    The nonce used to deploy the delegate
     * @dev             frontend might retrieve the correct nonce, for both contract and eoa, using 
     *                  ethers provider.getTransactionCount(address) or web3js web3.eth.getTransactionCount just *before* the
     *                  delegate deployment (if adding a delegate at a later time, manual nonce counting might be needed)
     */
    function addDelegate(address _deployer, uint256 _nonce) external override {
        // Compute the _delegate address, as create1 deployed at _nonce
        address _delegate = _addressFrom(_deployer, _nonce);

        // Add the delegate based on the computed address
        _addDelegate(_delegate, _deployer);
    }

    /**
     * @notice          Add a delegate to the registry (needs to implement erc165, a delegate type and deployed using create2)
     * @param _deployer The address of the contract deployer
     * @param _salt     An unique salt used to deploy the delegate
     * @param _bytecode The *deployment* bytecode used to deploy the delegate (ie including constructor and its arguments)
     * @dev             _salt is based on the delegate deployer own internal logic while the deployment bytecode can be retrieved in
     *                  the deployment transaction (off-chain) or via
     *                  abi.encodePacked(type(delegateContract).creationCode, abi.encode(constructorArguments)) (on-chain)
     */
    function addDelegateCreate2(address _deployer, bytes32 _salt, bytes calldata _bytecode) external override {
        // Compute the _delegate address, based on create2 salt and deployment bytecode
        address _delegate = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            _deployer,
            _salt,
            keccak256(_bytecode)
        )))));

        // Add the delegate based on the computed address
        _addDelegate(_delegate, _deployer);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  INTERNAL FUNCTIONS                      //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice Add a delegate to the mapping
     * @param _delegate the delegate address
     * @param _deployer the deployer address
     */
    function _addDelegate(address _delegate, address _deployer) internal {
        // add it with the deployer
        _deployerOf[_delegate] = _deployer;

        emit DelegateAdded(_delegate, _deployer);
    }

    /**
     * @notice          Compute the address of a contract deployed using create1, by an address at a given nonce
     * @param _origin   The address of the deployer
     * @param _nonce    The nonce used to deploy the contract
     * @dev             Taken from https://ethereum.stackexchange.com/a/87840/68134 - this wouldn't work for nonce > 2**32,
     *                  if someone do reach that nonce please: 1) ping us, because wow 2) use another deployer
     */
    function _addressFrom(address _origin, uint _nonce) internal pure returns (address _address) {
        bytes memory data;
        if(_nonce == 0x00)          data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        else if(_nonce <= 0x7f)     data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        else if(_nonce <= 0xff)     data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        else if(_nonce <= 0xffff)   data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        else if(_nonce <= 0xffffff) data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        else                        data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            _address := mload(0)
        }
    }
}