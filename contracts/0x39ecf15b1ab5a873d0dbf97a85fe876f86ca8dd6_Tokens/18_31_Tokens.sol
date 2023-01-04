// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";

import {Emint1155} from "./tokens/Emint1155.sol";
import {Controllable} from "./abstract/Controllable.sol";
import {Pausable} from "./abstract/Pausable.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {IPausable} from "./interfaces/IPausable.sol";
import {ITokens} from "./interfaces/ITokens.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IRoyalties} from "./interfaces/IRoyalties.sol";
import {IEmint1155} from "./interfaces/IEmint1155.sol";

contract Tokens is ITokens, Controllable, Pausable {
    string public constant NAME = "Tokens";
    string public constant VERSION = "0.0.1";

    address public minter;
    address public deployer;
    address public metadata;
    address public royalties;

    address public emint1155;

    // tokenId => Emint1155 token address
    mapping(uint256 => address) public tokens;

    constructor(address _controller) Controllable(_controller) {
        Emint1155 tokenImplementation = new Emint1155();
        emint1155 = address(tokenImplementation);
    }

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert Forbidden();
        }
        _;
    }

    modifier onlyDeployer() {
        if (msg.sender != deployer) {
            revert Forbidden();
        }
        _;
    }

    function deploy() external override onlyDeployer whenNotPaused returns (address _token) {
        _token = Clones.clone(emint1155);
        IEmint1155(_token).initialize(address(this));
    }

    function register(uint256 id, address _token) external override onlyDeployer whenNotPaused {
        tokens[id] = _token;
    }

    function updateTokenImplementation(address implementation) external override onlyController {
        emit UpdateTokenImplementation(emint1155, implementation);
        emint1155 = implementation;
    }

    function token(uint256 id) public view override returns (IEmint1155) {
        return IEmint1155(tokens[id]);
    }

    /// @inheritdoc ITokens
    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        external
        override
        onlyMinter
        whenNotPaused
    {
        token(id).mint(to, id, amount, data);
    }

    /// @inheritdoc IPausable
    function pause() external override onlyController {
        _pause();
    }

    /// @inheritdoc IPausable
    function unpause() external override onlyController {
        _unpause();
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "minter") _setMinter(_contract);
        else if (_name == "deployer") _setDeployer(_contract);
        else if (_name == "metadata") _setMetadata(_contract);
        else if (_name == "royalties") _setRoyalties(_contract);
        else revert InvalidDependency(_name);
    }

    function _setMinter(address _minter) internal {
        emit SetMinter(minter, _minter);
        minter = _minter;
    }

    function _setDeployer(address _deployer) internal {
        emit SetDeployer(deployer, _deployer);
        deployer = _deployer;
    }

    function _setMetadata(address _metadata) internal {
        emit SetMetadata(metadata, _metadata);
        metadata = _metadata;
    }

    function _setRoyalties(address _royalties) internal {
        emit SetRoyalties(royalties, _royalties);
        royalties = _royalties;
    }
}