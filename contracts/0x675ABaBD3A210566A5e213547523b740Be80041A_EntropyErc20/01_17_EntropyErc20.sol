//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../interface/IERC1363.sol";
import "../interface/IERC1363Receiver.sol";
import "../interface/IERC1363Spender.sol";

contract EntropyErc20 is ERC20Burnable, AccessControlEnumerable, ERC1363 {
    bytes32 private BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    constructor(address owner) ERC20("Entropy", "ENT") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);

    }

    function setBridge(address bridgeAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(BRIDGE_ROLE, bridgeAddress);
    }

    function burn(uint256 amount) public override onlyRole(BRIDGE_ROLE) {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyRole(BRIDGE_ROLE) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) public onlyRole(BRIDGE_ROLE) {
        _mint(account, amount);
    }

    function transferAndCall(address to, uint256 amount) public virtual override returns (bool) {
        return transferAndCall(to, amount, "");
    }

    function transferAndCall(
        address to,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bool) {
        transfer(to, amount);
        require(_checkOnTransferReceived(_msgSender(), to, amount, data), "ERC1363: receiver returned wrong data");
        return true;
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        return transferFromAndCall(from, to, amount, "");
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bool) {
        transferFrom(from, to, amount);
        require(_checkOnTransferReceived(from, to, amount, data), "ERC1363: receiver returned wrong data");
        return true;
    }

    function approveAndCall(address spender, uint256 amount) public virtual override returns (bool) {
        return approveAndCall(spender, amount, "");
    }

  
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bool) {
        approve(spender, amount);
        require(_checkOnApprovalReceived(spender, amount, data), "ERC1363: spender returned wrong data");
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkOnTransferReceived(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!isContract(recipient)) {
            revert("ERC1363: transfer to non contract address");
        }

        try ERC1363Receiver(recipient).onTransferReceived(_msgSender(), sender, amount, data) returns (bytes4 retval) {
            return retval == ERC1363Receiver.onTransferReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC1363: transfer to non ERC1363Receiver implementer");
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }


    function _checkOnApprovalReceived(
        address spender,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!isContract(spender)) {
            revert("ERC1363: approve a non contract address");
        }

        try ERC1363Spender(spender).onApprovalReceived(_msgSender(), amount, data) returns (bytes4 retval) {
            return retval == ERC1363Spender.onApprovalReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC1363: approve a non ERC1363Spender implementer");
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

}