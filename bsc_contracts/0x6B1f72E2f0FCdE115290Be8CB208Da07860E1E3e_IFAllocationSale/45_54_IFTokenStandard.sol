// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';

import './ERC2771ContextUpdateable.sol';

contract IFTokenStandard is
    ERC20Burnable,
    ERC2771ContextUpdateable,
    ERC20Permit,
    ERC1363
{
    // constants
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    // constructor
    constructor(
        string memory _name,
        string memory _symbol,
        address admin
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
    }

    function mint(address to, uint256 amount) external {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Must have minter role');
        _mint(to, amount);
    }

    //// EIP2771 meta transactions

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771ContextUpdateable)
        returns (address)
    {
        return ERC2771ContextUpdateable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771ContextUpdateable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpdateable._msgData();
    }

    //// EIP1363 payable token

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1363)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}