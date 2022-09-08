// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/proxy/Clones.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./NoDecimalsERC20Alpha.sol";

/// @title NoDecimalsFactoryClone
/// @notice This contract deploys an initial NoDecimalsERC20Alpha and with createToken creates
/// clones of NoDecimalsERC20Alpha
contract NoDecimalsFactoryClone {
    address immutable tokenImplementation;
    address public immutable vaultAddress;
    address public immutable lbpCreateProxyAddress;
    address public immutable instantMintSwapProxyAddress;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _tokens;

    event ERC20Deployed(
        address clone,
        string name,
        string symbol,
        address operator,
        uint256 initialSupply,
        address vaultAddress,
        address lbpCreateProxyAddress,
        address instantMintSwapProxyAddress,
        address nftAddress
    );

    constructor(
        address initialVaultAddress,
        address initialLbpCreateProxyAddress,
        address initialInstantMintSwapProxyAddress
    ) {
        vaultAddress = initialVaultAddress;
        lbpCreateProxyAddress = initialLbpCreateProxyAddress;
        instantMintSwapProxyAddress = initialInstantMintSwapProxyAddress;
        tokenImplementation = address(new NoDecimalsERC20Alpha());
    }

    /**
     * @dev Checks if the token address was created in this smart contract
     */
    function isToken(address token) external view returns (bool valid) {
        return _tokens.contains(token);
    }

    /**
     * @dev Returns the total amount of tokens created in the contract
     */
    function tokenCount() external view returns (uint256 count) {
        return _tokens.length();
    }

    /**
     * @dev Returns all the token values
     */
    function getTokens() external view returns (address[] memory tokens) {
        return _tokens.values();
    }

    /**
     * @dev creates a clone of the implementation token
     */
    function createToken(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply,
        address nftAddress
    ) external returns (address) {
        address clone = Clones.clone(tokenImplementation);
        NoDecimalsERC20Alpha(clone).initialize(
            name,
            symbol,
            msg.sender,
            initialSupply,
            vaultAddress,
            lbpCreateProxyAddress,
            instantMintSwapProxyAddress,
            nftAddress
        );

        _tokens.add(address(clone));
        emit ERC20Deployed(
            clone,
            name,
            symbol,
            msg.sender,
            initialSupply,
            vaultAddress,
            lbpCreateProxyAddress,
            instantMintSwapProxyAddress,
            nftAddress
        );
        return clone;
    }
}