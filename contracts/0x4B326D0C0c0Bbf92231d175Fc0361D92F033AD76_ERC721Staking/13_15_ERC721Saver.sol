// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract ERC721Saver is AccessControlEnumerable {
    bytes32 public constant TOKEN_SAVER_ROLE = keccak256("TOKEN_SAVER_ROLE");

    event ERC721Saved(address indexed by, address indexed receiver, address indexed token, uint256 tokenId);

    modifier onlyTokenSaver() {
        require(hasRole(TOKEN_SAVER_ROLE, _msgSender()), "ERC721Saver.onlyTokenSaver: permission denied");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function saveToken(address _token, address _receiver, uint256 _tokenId) external onlyTokenSaver {
        IERC721(_token).safeTransferFrom(address(this), _receiver, _tokenId);
        emit ERC721Saved(_msgSender(), _receiver, _token, _tokenId);
    }
}