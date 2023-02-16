// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SignersRegistry is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    event PublicSignerAdded(address indexed signer);
    event PublicSignerRemoved(address indexed signer);
    event PrivateSignersSet(address signerAdmin, address[] signers);

    mapping(address => bool) public publicSigners;
    // signerAdmin -> privateSigners
    mapping(address => address[]) public privateSigners;
    mapping(address => bool) public privateSignerAdmin;

    modifier onlySignerAdmin() {
        if (!privateSignerAdmin[msg.sender]) {
            revert("Caller is not the signer admin");
        }
        _;
    }

    /**
     * @dev no constructor in upgradable contracts. Instead we have initializers
     */
    function initialize(address _owner) public initializer {
        __Ownable_init();
        _transferOwnership(_owner);
    }

    /**
     * @dev required by the OZ UUPS module
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function addPublicSigner(address signer) public onlyOwner {
        publicSigners[signer] = true;
        emit PublicSignerAdded(signer);
    }

    function removePublicSigner(address signer) public onlyOwner {
        delete publicSigners[signer];
        emit PublicSignerRemoved(signer);
    }

    function addPrivateSignerAdmin(address signerAdmin) public onlyOwner {
        privateSignerAdmin[signerAdmin] = true;
    }

    function removePrivateSignerAdmin(address signerAdmin) public onlyOwner {
        delete privateSignerAdmin[signerAdmin];
        delete privateSigners[signerAdmin];
        // call event with empty array
        emit PrivateSignersSet(signerAdmin, new address[](0));
    }

    function setPrivateSigners(address[] memory signers) public onlySignerAdmin {
        privateSigners[msg.sender] = signers;
        emit PrivateSignersSet(msg.sender, signers);
    }

    function isPublicWhitelisted(address signer) public view returns (bool) {
        return publicSigners[signer];
    }

    function isPrivateWhitelisted(address signerAdmin, address signer) public view returns (bool) {
        for (uint256 i = 0; i < privateSigners[signerAdmin].length; i++) {
            if (privateSigners[signerAdmin][i] == signer) {
                return true;
            }
        }
        return false;
    }
}