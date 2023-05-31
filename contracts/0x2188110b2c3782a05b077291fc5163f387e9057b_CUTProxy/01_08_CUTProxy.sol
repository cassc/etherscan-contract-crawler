// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/**
 * The CUT ERC-20 Contract.
 *
 * To implement public interface, and store the location of the CUT Stateless
 * lib in order to proxy function calls to the current live implementation.
 *
 * The public interface is ERC-20 compatible.
 */

import "../vendor/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../vendor/openzeppelin-contracts/contracts/GSN/Context.sol";
import "../vendor/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "../vendor/openzeppelin-contracts/contracts/utils/Address.sol";

import "./interfaces/ICUTLib.sol";


contract CUTProxy is Context, AccessControl, ICUTLib {

    using SafeMath for uint256;
    using Address for address;

    bytes32 public constant LOGGER_ROLE = keccak256("LOGGER_ROLE");

    address private productionLibrary;
    uint8 private _decimals;

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _decimals = 5;
    }

    function setProductionLibrary(address newLibrary) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "C:ADMIN");

        productionLibrary = newLibrary;
    }

    function getProductionLibrary() public
    view
    returns (address) {
        return productionLibrary;
    }

    /**
     * Announce the retirement of some CUT to the ERC20 token.
     * This work is performed, and balances are adjusted behind the scenes,
     * but the event should be emitted to help wallets and explorers track
     * the flow of tokens.
     *
     * This emits a Transfer from the contributor to the 0x0 address,
     * similar to a burn.
     */
    function announceRetirement(address contributor, uint256 amount) public
    returns (bool) {
        require(hasRole(LOGGER_ROLE, _msgSender()), "C:LOG");
        emit Transfer(contributor, address(0), amount);
        return true;
    }

    /**
     * Announce that some CUT has been dispersed to the ERC20 token.
     *
     * This emits a Transfer from the CUT source (productionLibrary) to the
     * recipient of the number of unmatched tokens spread to the account.
     */
    function announceDispersed(address recipient, uint256 amount) public
    returns (bool) {
        require(hasRole(LOGGER_ROLE, _msgSender()), "C:LOG");
        emit Transfer(productionLibrary, recipient, amount);
        return true;
    }


    function name() public view override
    returns (string memory) {
        return ICUTImpl(productionLibrary).name();
    }

    function symbol() public view override
    returns (string memory) {
        return ICUTImpl(productionLibrary).symbol();
    }

    function decimals() public view override
    returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override
    returns (uint256) {
        return ICUTImpl(productionLibrary).totalSupply();
    }

    function balanceOf(address account) public view override
    returns (uint256) {
        return ICUTImpl(productionLibrary).balanceOf(account);
    }

    function allowance(address owner, address spender) public view override
    returns (uint256) {
        return ICUTImpl(productionLibrary).allowance(owner, spender);
    }

    function transfer(address recipient, uint256 amount) public override
    returns (bool) {
        ICUTImpl(productionLibrary).transfer(_msgSender(), recipient, amount);

        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override
    returns (bool) {
        ICUTImpl(productionLibrary).approve(_msgSender(), spender, amount);

        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address recipient, uint256 amount) public override
    returns (bool) {
        ICUTImpl(productionLibrary).transferFrom(_msgSender(), from, recipient, amount);

        emit Transfer(from, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override
    returns (bool) {
        uint256 newAllowance = ICUTImpl(productionLibrary).increaseAllowance(
            _msgSender(), spender, addedValue);

        emit Approval(_msgSender(), spender, newAllowance);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override
    returns (bool) {
        uint256 newAllowance = ICUTImpl(productionLibrary).decreaseAllowance(
            _msgSender(), spender, subtractedValue);

        emit Approval(_msgSender(), spender, newAllowance);
        return true;
    }

    function signalRetireIntent(uint256 retirementAmount) public override {
        return ICUTImpl(productionLibrary).signalRetireIntent(_msgSender(), retirementAmount);
    }
}