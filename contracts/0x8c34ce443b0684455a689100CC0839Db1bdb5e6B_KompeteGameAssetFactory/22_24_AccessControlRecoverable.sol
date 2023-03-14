// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Recoverable.sol";

contract AccessControlRecoverable is AccessControl, Recoverable {
    bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");

    modifier onlyRecover() {
        require(hasRole(RECOVER_ROLE, _msgSender()), "Recoverable: recover role required");
        _;
    }

    function recoverERC721Token(
        address _to,
        address _token,
        uint256 _tokenId
    ) external onlyRecover {
        _recoverERC721Token(_to, _token, _tokenId);
    }

    function recoverERC1155Token(
        address _to,
        address _token,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyRecover {
        _recoverERC1155Token(_to, _token, _tokenId, _amount);
    }

    function recoverERC20Token(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyRecover {
        _recoverERC20Token(_to, _token, _amount);
    }

    function recoverEth(address payable _to, uint256 _amount) external onlyRecover {
        _recoverEth(_to, _amount);
    }
}