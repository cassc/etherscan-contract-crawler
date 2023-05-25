pragma solidity ^0.8.10;

import "./AccountantInterfaces.sol";

contract AccountantDelegator is
    AccountantInterface,
    AccountantDelegatorInterface
{
    /**
     * @param implementation_ implementation address (the AccountantDelegate)
     * @param admin_ admin address (Timelock)
     * @param cnoteAddress_ lending market address (CNote)
     * @param noteAddress_  note address (note erc20 contract)
     * @param comptrollerAddress_, address of Comptroller Delegator(Unitroller)
     * @param treasury_ treasury address (TreasuryDelegator)
     */
    constructor(
        address implementation_,
        address admin_,
        address cnoteAddress_,
        address noteAddress_,
        address comptrollerAddress_,
        address treasury_
    ) {
        require(admin_ != address(0));
        // Admin set to msg.sender for initialization
        admin = msg.sender;

        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                treasury_,
                cnoteAddress_,
                noteAddress_,
                comptrollerAddress_
            )
        );
        setImplementation(implementation_);

        admin = admin_;
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public override {
        require(
            msg.sender == admin,
            "AccountantDelegator::_setImplementation: admin only"
        );
        require(
            implementation_ != address(0),
            "AccountantDelegator::_setImplementation: invalid implementation address"
        );
        emit NewImplementation(implementation, implementation_);

        implementation = implementation_;
    }

    function _setPendingAdmin(address newPendingAdmin) external override {
        require(msg.sender == admin, "AccountantDelegator::admin only");
        delegateToImplementation(
            abi.encodeWithSignature("_setPendingAdmin(address)", newPendingAdmin)
        );
    }

    function _acceptAdmin() external override {
        require(
            msg.sender == pendingAdmin,
            "AccountantDelegator::sender not pendingAdmin"
        );
        delegateToImplementation(abi.encodeWithSignature("_acceptAdmin()"));
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
     * @param amount amount of Note Accountant is supplying to market
     */
    function supplyMarket(uint256 amount)
        external
        override
        returns (uint256)
    {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("supplyMarket(uint256)", amount)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
     * @param amount The address of the ERC-20 token to sweep
     */
    function redeemMarket(uint256 amount)
        external
        override
        returns (uint256)
    {
        bytes memory data = delegateToImplementation(
            abi.encodeWithSignature("redeemMarket(uint256)", amount)
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
     */
    function sweepInterest() external override {
        delegateToImplementation(abi.encodeWithSignature("sweepInterest()"));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     */
    function delegateTo(address callee, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data)
        public
        returns (bytes memory)
    {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data)
        public
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = address(this).staticcall(
            abi.encodeWithSignature("delegateToImplementation(bytes)", data)
        );
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return abi.decode(returnData, (bytes));
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external payable {
        require(
            msg.value == 0,
            "AccountantDelegator:fallback: cannot send value to fallback"
        );

        (bool success,) = implementation.delegatecall(msg.data); // delegate all other functions to current implementation

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }
}