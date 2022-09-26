// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Faucet} from "./ERC20Faucet.sol";
import {ETHFaucet} from "./ETHFaucet.sol";
import {IFaucetFactory} from "./IFaucetFactory.sol";
import {IFaucet} from "./IFaucet.sol";

/// @title A Factory to create faucets. Faucets are vesting NFTs that allow funds to be remitted on a fixed schedule.
/// @author tbtstl <[email protected]>
contract FaucetFactory is IFaucetFactory {
    using Clones for address;
    address public erc20FaucetImplementation;
    address public ethFaucetImplementation;
    mapping(address => address) public deployedFaucetsForToken;

    constructor(address _erc20FaucetImplementation, address _ethFaucetImplementation) {
        erc20FaucetImplementation = _erc20FaucetImplementation;
        ethFaucetImplementation = _ethFaucetImplementation;

        // Deploy the ETH faucet by default
        _deployFaucet(address(0));
    }

    /// @notice Get the faucet address for a given token. If the faucet does not exist, it is deployed
    /// @param _tokenAddress The address of the underlying ERC-20 for the faucet, or address(0) for ETH
    /// @return faucetAddr The address of the faucet
    /// @return deployed Whether or not the faucet was just deployed
    function faucetForToken(address _tokenAddress) external returns (address faucetAddr, bool deployed) {
        if (deployedFaucetsForToken[_tokenAddress] == address(0)) {
            address deployedFaucet = _deployFaucet(_tokenAddress);
            return (deployedFaucet, true);
        } else {
            return (deployedFaucetsForToken[_tokenAddress], false);
        }
    }

    /// @notice Get the faucet address for a given token. If the faucet does not exist, address(0) is returned
    /// @param _tokenAddress The address of the underlying ERC-20 for the faucet, or address(0) for ETH
    /// @return faucetAddr The address of the faucet
    function faucetForTokenView(address _tokenAddress) external view returns (address faucetAddr) {
        return deployedFaucetsForToken[_tokenAddress];
    }

    function _deployFaucet(address _tokenAddress) internal returns (address) {
        address deployedFaucetAddress;
        if (_tokenAddress == address(0)) {
            deployedFaucetAddress = ethFaucetImplementation.clone();
            ETHFaucet(deployedFaucetAddress).initialize("Ethereum Faucet", "FCT-ETH");
        } else {
            string memory name = string(abi.encodePacked(_getTokenName(_tokenAddress), " Faucet"));
            string memory symbol = string(abi.encodePacked("FCT-", _getTokenSymbol(_tokenAddress)));
            deployedFaucetAddress = erc20FaucetImplementation.clone();
            ERC20Faucet(deployedFaucetAddress).initialize(name, symbol, IERC20(_tokenAddress));
        }

        deployedFaucetsForToken[_tokenAddress] = deployedFaucetAddress;
        return deployedFaucetAddress;
    }

    function _toBytes(address a) private pure returns (bytes32 b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function _getTokenName(address _tokenAddress) private view returns (string memory) {
        try IERC20Metadata(_tokenAddress).name() returns (string memory n) {
            return n;
        } catch {
            bytes memory s = new bytes(40);
            for (uint256 i = 0; i < 20; i++) {
                bytes1 b = bytes1(uint8(uint256(uint160(_tokenAddress)) / (2**(8 * (19 - i)))));
                bytes1 hi = bytes1(uint8(b) / 16);
                bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
                s[2 * i] = char(hi);
                s[2 * i + 1] = char(lo);
            }
            return string(abi.encodePacked("0x", s));
        }
    }

    function _getTokenSymbol(address _tokenAddress) private view returns (string memory) {
        try IERC20Metadata(_tokenAddress).symbol() returns (string memory n) {
            return n;
        } catch {
            return "???";
        }
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}