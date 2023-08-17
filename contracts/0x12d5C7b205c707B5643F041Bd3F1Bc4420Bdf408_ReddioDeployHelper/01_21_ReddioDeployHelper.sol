// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Reddio20General} from "./ERC20General.sol";
import {Reddio721} from "./Reddio721.sol";
import {Reddio721CustomURI} from "./Reddio721CustomURI.sol";

interface IRegisterProxy {
    function registerToken(
        address token,
        Asset asset,
        uint256 decimals,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 totalSupply,
        address from,
        bool newDeployed
    ) external;
}

enum Asset {
    ERC20,
    ERC721,
    ERC721Mintable,
    ERC721MintableCustomURI
}

error InvalidAsset();

contract ReddioDeployHelper {
    address public registerProxy;
    mapping(address deployer => uint256 counter) public counter;

    event NewERC20(address deployer, address token);
    event NewERC721(address deployer, address token);

    constructor(address _registerProxy) {
        registerProxy = _registerProxy;
    }

    function deployERC20AndRegister(
        string memory name_,
        string memory symbol_,
        uint256 amount
    ) external returns (address token) {
        // 1. deploy erc20
        bytes memory bytecode = type(Reddio20General).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, counter[msg.sender]++)
        );
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode(name_, symbol_, amount)
        );
        assembly {
            token := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        uint256 amountInWei = amount * 1 ether;
        IERC20(token).transfer(msg.sender, amountInWei);
        // 2. register token
        _registerToken(
            token,
            Asset.ERC20,
            name_,
            symbol_,
            "",
            18,
            amountInWei,
            true
        );
        emit NewERC20(msg.sender, token);
    }

    function _registerToken(
        address token,
        Asset asset,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 decimals,
        uint256 totalSupply,
        bool newDeployed
    ) internal {
        IRegisterProxy(registerProxy).registerToken(
            token,
            asset,
            decimals,
            name,
            symbol,
            baseURI,
            totalSupply,
            msg.sender,
            newDeployed
        );
    }

    function registerToken(address token, Asset asset) external {
        if (asset != Asset.ERC20 && asset != Asset.ERC721) {
            revert InvalidAsset();
        }
        bool erc20Token = asset == Asset.ERC20;
        string memory name = erc20Token
            ? IERC20Metadata(token).name()
            : IERC721Metadata(token).name();
        string memory symbol = erc20Token
            ? IERC20Metadata(token).symbol()
            : IERC721Metadata(token).symbol();
        uint256 decimals = erc20Token ? IERC20Metadata(token).decimals() : 0;
        uint256 totalSupply = erc20Token
            ? IERC20(token).totalSupply()
            : IERC721Enumerable(token).totalSupply();
        _registerToken(
            token,
            asset,
            name,
            symbol,
            "",
            decimals,
            totalSupply,
            false
        );
    }

    function deployERC721AndRegister(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        Asset asset
    ) external returns (address token) {
        // 1. deploy erc721
        bytes memory bytecode;
        if (asset == Asset.ERC721 || asset == Asset.ERC721Mintable) {
            bytecode = type(Reddio721).creationCode;
        } else if (asset == Asset.ERC721MintableCustomURI) {
            bytecode = type(Reddio721CustomURI).creationCode;
        } else {
            revert InvalidAsset();
        }
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, counter[msg.sender]++)
        );
        bool _mintable = asset == Asset.ERC721Mintable ||
            asset == Asset.ERC721MintableCustomURI;
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode(name_, symbol_, baseURI_, _mintable)
        );
        assembly {
            token := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        Ownable(token).transferOwnership(msg.sender);
        // 2. register token
        _registerToken(token, asset, name_, symbol_, baseURI_, 0, 0, true);
        emit NewERC721(msg.sender, token);
    }
}