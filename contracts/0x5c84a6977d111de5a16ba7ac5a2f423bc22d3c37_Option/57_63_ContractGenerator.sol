// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {OptionToken} from "../token/OptionToken.sol";
import {CloneFactory} from "./CloneFactory.sol";
import {Option} from "../option/Option.sol";

/**
 * @title ContractGenerator
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev A factory contract that is responsible for generating and cloning various contracts related to options.
 *      These contracts include the OptionToken contracts and the Option contracts.
 */
contract ContractGenerator is CloneFactory, Ownable {
    using SafeMath for uint256;

    /**
     * @notice The address of the optionFactory contract.
     * @dev This address is used for access control in the ContractGenerator contract.
     *      Any functions with the 'onlyFactory' modifier can only be called by this address.
     */
    address public optionFactory;

    /**
     * @dev A private constant that sets the multiplier for calculations in the contract.
     */
    uint256 private constant MULTIPLIER = 10**18;

    /**
     * @dev A private variable used to track if the contract is initiated.
     */
    bool private initiated = false;

    /**
     * @notice Function modifier to restrict access to functions.
     * @dev This modifier only allows the function to be called by the address stored in optionFactory.
     */
    modifier onlyFactory() {
        require(msg.sender == optionFactory, "ContractGenerator: caller is not the optionFactory");
        _;
    }

    /**
     * @notice Returns the code hash of the OptionToken contract creation code.
     * @dev Function to get the keccak256 hash of the bytecode of the OptionToken contract.
     * @return The code hash of the OptionToken contract creation code.
     */
    function optionTokenCodeHash() external pure returns (bytes32) {
        return keccak256(type(OptionToken).creationCode);
    }

    /**
     * @notice Initializes the ContractGenerator contract.
     * @dev Sets the address of the OptionFactory during deployment.
     * @param _factory The address of the optionFactory contract.
     */
    constructor(address _factory) {
        require(_factory != address(0), "ContractGenerator: zero address");
        optionFactory = _factory;
    }

    /**
     * @notice Creates a pair of OptionToken contracts for a given option.
     * @dev This function uses the create2 assembly function to create two new OptionToken contracts.
     * @param _optionId The ID of the option.
     * @param _optionAddress The address of the option contract.
     * @return bullet The address of the bullet OptionToken contract.
     * @return sniper The address of the sniper OptionToken contract.
     */
    function createToken(uint256 _optionId, address _optionAddress)
        external
        onlyFactory
        returns (address bullet, address sniper)
    {
        bytes32 bulletSalt = keccak256(abi.encodePacked(_optionId, _optionAddress, "bullet"));
        bytes32 sniperSalt = keccak256(abi.encodePacked(_optionId, _optionAddress, "sniper"));
        bytes memory bulletBytecode = type(OptionToken).creationCode;
        bytes memory sniperBytecode = type(OptionToken).creationCode;

        assembly {
            bullet := create2(0, add(bulletBytecode, 32), mload(bulletBytecode), bulletSalt)
        }
        assembly {
            sniper := create2(0, add(sniperBytecode, 32), mload(sniperBytecode), sniperSalt)
        }
        OptionToken(bullet).initialize(_optionAddress);
        OptionToken(sniper).initialize(_optionAddress);
    }

    /**
     * @notice Clones an existing pair of OptionToken contracts.
     * @dev This function uses the CloneFactory contract to clone two existing OptionToken contracts.
     * @param _optionAddress The address of the option contract.
     * @param _bulletSource The address of the source bullet OptionToken contract.
     * @param _sniperSource The address of the source sniper OptionToken contract.
     * @return bullet The address of the cloned bullet OptionToken contract.
     * @return sniper The address of the cloned sniper OptionToken contract.
     */
    function cloneToken(
        address _optionAddress,
        address _bulletSource,
        address _sniperSource
    ) external onlyFactory returns (address bullet, address sniper) {
        bullet = createClone(_bulletSource);
        sniper = createClone(_sniperSource);
        OptionToken(bullet).initialize(_optionAddress);
        OptionToken(sniper).initialize(_optionAddress);
    }

    /**
     * @notice Clones an existing option contract.
     * @dev This function uses the CloneFactory contract to clone an existing Option contract.
     * @param _targetAddress The address of the target option contract to be cloned.
     * @param _optionFactory The address of the option factory contract.
     * @return option The address of the cloned option contract.
     */
    function cloneOptionPool(address _targetAddress, address _optionFactory) external onlyFactory returns (address option) {
        option = createClone(_targetAddress);
        Option(option).clone_initialize(_optionFactory);
    }

    /**
     * @notice Creates a new option contract.
     * @dev This function uses the create2 assembly function to create a new Option contract.
     * @param _strikePrice The strike price of the option.
     * @param _exerciseTimestamp The exercise timestamp of the option.
     * @param _optionType The type of the option.
     * @param _optionFactory The address of the option factory contract.
     * @return option The address of the newly created option contract.
     */
    function createOptionContract(
        uint256 _strikePrice,
        uint256 _exerciseTimestamp,
        uint8 _optionType,
        address _optionFactory
    ) external onlyFactory returns (address option) {
        bytes32 optionSalt = keccak256(abi.encodePacked(_strikePrice, _exerciseTimestamp, _optionType));

        bytes memory optionBytecode = abi.encodePacked(type(Option).creationCode, abi.encode(_optionFactory));
        assembly {
            option := create2(0, add(optionBytecode, 32), mload(optionBytecode), optionSalt)
        }
    }
}