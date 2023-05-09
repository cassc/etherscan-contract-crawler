// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// Contracts
import { ERC165, IERC165 } from "../introspection/ERC165.sol";
import { UERC20 } from "../token/UERC20.sol";
import { Ownable } from "../../common/utils/Ownable.sol";

// Interfaces
import { IBridge } from "../interfaces/IBridge.sol";
import { IOERC20 } from "../../common/interfaces/IOERC20.sol";
import { IERC20 } from "../../common/interfaces/IERC20.sol";

abstract contract OERC20 is IOERC20, ERC165, UERC20, Ownable {
    // Storage Variables: follow storage slot restrictions
    mapping(address => bool) public transferPrivileges;
    mapping(address => mapping(uint16 => bool)) public routes;

    error Paused();

    function sendFrom(
        address _bridgeAddress,
        address payable _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount
    ) public payable virtual override returns (uint64 sequence) {
        if (!transferPrivileges[_bridgeAddress] || !routes[_bridgeAddress][_dstChainId]) {
            revert Paused();
        }
        _debitFrom(_from, _dstChainId, _toAddress, _amount);

        sequence = IBridge(_bridgeAddress).sendMessage{ value: msg.value }(_from, _dstChainId, _toAddress, _amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOERC20).interfaceId || interfaceId == type(IERC20).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function circulatingSupply() public view virtual override returns (uint256) {
        return totalSupply;
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `amount`.
     * Does not update the allowance amount in case of infinite allowance.
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance.");
            unchecked {
                allowance[owner][spender] = currentAllowance - amount;
            }
        }
    }

    function _debitFrom(address _from, uint16, bytes memory, uint256 _amount) internal {
        address spender = _msgSender();
        if (_from != spender) {
            _spendAllowance(_from, spender, _amount);
        }
        _burn(_from, _amount);
    }

    /* ****************************************************************************
    **
    **  Admin Functions
    **
    ******************************************************************************/

    /**
     * @dev Manages cross-chain transfer privileges for each message passing protocol.
     * @param _bridgeAddresses - An array of supported bridge IDs; the order must match `_privilges` array.
     * @param _privileges - An array of protocol privileges; the order must match `_bridgeIds` array.
     */
    function manageCrossChainTransfers(address[2] calldata _bridgeAddresses, bool[2] calldata _privileges)
        public
        onlyOwner
    {
        require(_bridgeAddresses.length == _privileges.length, "Arrays must be equal length.");

        for (uint256 i; i < _bridgeAddresses.length; i++) {
            transferPrivileges[_bridgeAddresses[i]] = _privileges[i];
        }
    }

    /**
     * @dev Manages privileges for bridge-specific routes.
     * @param _bridgeAddress - Bridge contract address.
     * @param _dstChainIds - An array of bridge-specific destination chain IDs; the order must match `_privileges` array.
     * @param _privileges - An array of route privileges (boolean); the order must match `_dstChainIds` array.
     */
    function manageRoutes(address _bridgeAddress, uint16[] calldata _dstChainIds, bool[] calldata _privileges)
        public
        onlyOwner
    {
        require(_dstChainIds.length == _privileges.length, "Arrays must be equal length.");

        for (uint256 i; i < _dstChainIds.length; i++) {
            routes[_bridgeAddress][_dstChainIds[i]] = _privileges[i];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage slots in the inheritance chain.
     * Storage slot management is necessary, as we're using an upgradable proxy contract.
     * For details, see: https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}