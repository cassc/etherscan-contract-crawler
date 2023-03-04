// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";

abstract contract OmniumStakeableERC1155Upgradeable is Initializable, ERC1155Upgradeable, OwnableUpgradeable {
    
    mapping (uint256 => uint256) private _tokenStakeCoeficient;

    function __OmniumStakeableERC1155Upgradeable_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained( uri_);
        __Ownable_init_unchained();
    }

    function setTokenStakeCoeficient( uint256 _tokenId, uint256 _StakeCoeficient) public virtual onlyOwner() {
        _tokenStakeCoeficient[_tokenId] = _StakeCoeficient;
    }

    function getTokenStakeCoeficient( uint256 _tokenId) public virtual returns (uint256) {
        return _tokenStakeCoeficient[_tokenId];
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual  returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
   function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

}