// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";

interface IRecoveryChildV1 is IERC165Upgradeable {
    function recoveryParentToken() external view returns (address, uint256);

    function recoveryParentTokenOwner() external view returns (address);
}

abstract contract RecoveryChildV1 is Initializable, ERC165Upgradeable, IRecoveryChildV1 {
    address internal recoveryParentTokenContract;
    uint256 internal recoveryParentTokenId;

    modifier onlyParentTokenOwner() {
        require(msg.sender == recoveryParentTokenOwner(), "RecoveryChildV1: caller is not the parent token owner");
        _;
    }

    function __RecoveryChildV1_init(address _recoveryParentTokenContract, uint256 _recoveryParentTokenId)
        internal
        onlyInitializing
    {
        recoveryParentTokenContract = _recoveryParentTokenContract;
        recoveryParentTokenId = _recoveryParentTokenId;
    }

    function recoveryParentToken() public view returns (address, uint256) {
        return (recoveryParentTokenContract, recoveryParentTokenId);
    }

    function recoveryParentTokenOwner() public view returns (address) {
        return IERC721Upgradeable(recoveryParentTokenContract).ownerOf(recoveryParentTokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IRecoveryChildV1).interfaceId || super.supportsInterface(interfaceId);
    }
}