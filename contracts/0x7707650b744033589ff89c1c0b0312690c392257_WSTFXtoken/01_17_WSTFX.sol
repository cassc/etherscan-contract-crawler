// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";


interface ERC1363PARTIAL {
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes calldata _extraData) external;
    function tokenFallback(address _sender, uint256 _value, bytes calldata _extraData) external  returns (bool);
}

/* Token is a straight OpenZepplin implementation with the added features
    ApproveAndCall, TransferAndCall to facilitate better DeFi Interactions With compatible Contracts
*/
/// @custom:security-contact [email protected]
contract WSTFXtoken is ERC20, ERC20Burnable, Pausable, AccessControl, ERC20Permit {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


    constructor() ERC20("Wall Street FX Token", "WSTFX") ERC20Permit("Wall Street FX Token") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, 2000000000 * 10 ** decimals());
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {

        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {

        super.transferFrom(sender, recipient, amount);
        return true;
    }


    function approveAndCall(address _recipient, uint256 _value, bytes calldata _extraData) public returns (bool) {
        approve(_recipient, _value);
        ERC1363PARTIAL(_recipient).receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }

    function transferAndCall(address _recipient, uint256 _value, bytes calldata _extraData) public returns (bool) {
        transfer(_recipient, _value);
        require(ERC1363PARTIAL(_recipient).tokenFallback(msg.sender, _value, _extraData));
        return true;
    }
}