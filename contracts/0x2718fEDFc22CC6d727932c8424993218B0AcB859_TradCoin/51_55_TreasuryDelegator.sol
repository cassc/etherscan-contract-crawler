pragma solidity ^0.8.10;

import "./TreasuryInterfaces.sol"; 

contract TreasuryDelegator is TreasuryDelegatorInterface, TreasuryInterface{

    /**
    *@param note_ address of Note ERC20 Contract to receive funds from
    *@param implementation_, address of current implementation to delegate calls to
    *@param admin_, administrator of contract, generally speaking, will be Timelock
    */	
    constructor(address note_, address implementation_, address admin_) {
        require(admin_ != address(0));
        require(note_.code.length > 0); //Ensure that this is a contract
        // Admin set to msg.sender for initialization
        admin = msg.sender;

        delegateTo(implementation_, abi.encodeWithSignature("initialize(address)", note_));

        setImplementation(implementation_);

		admin = admin_;
	}

    
	/**
     * @notice Method called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) override public {

        require(msg.sender == admin, "GovernorBravoDelegator::setImplementation: admin only");
        require(implementation_ != address(0), "GovernorBravoDelegator::setImplementation: invalid implementation address");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation_);
    }

    function _setPendingAdmin(address newPendingAdmin) override external {
        require(msg.sender == admin, "TreasuryDelegator::admin only");
        delegateToImplementation(abi.encodeWithSignature("_setPendingAdmin(address)", newPendingAdmin));
    }

    function _acceptAdmin() override external {
        require(msg.sender == pendingAdmin, "TreasuryDelegator::sender not pendingAdmin");
        delegateToImplementation(abi.encodeWithSignature("_acceptAdmin()"));
    }

    /**
     * @notice Method to query current balance of CANTO in the treasury using a DELEGATECALL
     * @return uint the canto balance
     */
    function queryCantoBalance() override external view returns(uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("queryCantoBalance()"));
        return abi.decode(data, (uint));
    }
    
    /**
     * @notice Method to query current balance of NOTE in the treasury using a DELEGATECALL
     * @return uint the note balance 
     */
    function queryNoteBalance() override external view returns(uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("queryNoteBalance()"));
        return abi.decode(data, (uint));
    }
    /**
    * @notice Method to send funds to recipient using DELEGATECALL
    * @param recipient recipient of funds
    * @param amount amount of funds to send to recipient
    * @param denom denomination of funds to send
     */
    function sendFund(address recipient, uint amount, string calldata denom) override external {
        delegateToImplementation(abi.encodeWithSignature("sendFund(address,uint256,string)", recipient, amount, denom));
    }

    function redeem(address cNote, uint cTokens) external override {
        delegateToImplementation(abi.encodeWithSignature("redeem(address,uint256)", cNote, cTokens));
    }
 
    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the impledmentation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return bytes returned bytes from the delegater 
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return bytes returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return abi.decode(returnData, (bytes));
    }


    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns(bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

	/**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() external payable override {
        require(msg.value == 0, "TreasuryDelegator::fallback:cannot send value to fallback");
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize() )

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }

    receive() external payable override {
        emit Received(msg.sender, msg.value);
    }
}