// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ASSPLayer.sol";

contract ASSPLayerParent is ASSPLayer, FxBaseRootTunnel, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(address _checkpointManager, address _fxRoot) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function registerProject(address contractAddress) public override {
        _beforeProjectRegistration(contractAddress, msg.sender, block.chainid);
        try Ownable(contractAddress).owner() returns (address owner) {
            require(owner == msg.sender, "APP:409");
            _registerProject(contractAddress, owner);
        } catch {}
    }

    function registerToken(address contractAddress, uint256 tokenId) public override {
        require(registeredProjects[block.chainid][contractAddress] == true, "500");
        try ERC721(contractAddress).ownerOf(tokenId) returns (address owner) {
            bytes memory message = abi.encode(contractAddress, address(0), tokenId, owner);
            _sendMessageToChild(message);
            emit TokenRegistered(contractAddress, tokenId, owner, block.chainid);
        } catch {}
    }

    /// -----------------------------------------------------------------------
    /// Admin functions
    /// -----------------------------------------------------------------------

    function expelProject(uint256, address contractAddress) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        registeredProjects[block.chainid][contractAddress] = false;
        emit ProjectExpelled(block.chainid, contractAddress);
    }

    function expelTokens(
        uint256,
        address contractAddress,
        uint256[] calldata tokenIds
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = tokenIds.length;

        for (uint256 i = 0; i < length; ) {
            _onTokenRemoval(block.chainid, contractAddress, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function owner_registerProject(address contractAddress, address admin) external onlyRole(ADMIN_ROLE) {
        try Ownable(contractAddress).owner() returns (address owner) {
            _registerProject(contractAddress, owner);
        } catch {
            _registerProject(contractAddress, admin);
        }
    }

    function _registerProject(address contractAddress, address owner) internal {
        bytes memory message = abi.encode(contractAddress, owner, 0, address(0));
        _sendMessageToChild(message);
        registeredProjects[block.chainid][contractAddress] = true;
        emit ProjectRegistered(contractAddress, block.chainid);
    }

    function _processMessageFromChild(bytes memory data) internal virtual override {}

    function resetFxChildTunnel(address _fxChildTunnel) external onlyRole(ADMIN_ROLE) {
        fxChildTunnel = _fxChildTunnel;
    }
}