// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./CudosAccessControls.sol";

contract CudosToken is ERC20("CudosToken", "CUDOS") {

    /// @notice Contract that defines access controls for the CUDO ecosystem
    CudosAccessControls public accessControls;

    /// @notice defines whether a non-whitelisted token holder can move their tokens
    bool public transfersEnabled = false;

    /// @notice initial supply which needs to be multiplied by 10 ^ 18
    uint256 constant internal TEN_BILLION = 10_000_000_000;

    /**
     @dev 10 Billion will be minted to _initialSupplyRecipient
     @param _accessControls Address of the CUDO access control contract
     @param _initialSupplyRecipient Address of the initial 10bn token supply
     */
    constructor (CudosAccessControls _accessControls, address _initialSupplyRecipient) public {
        require(_initialSupplyRecipient != address(0), "CudosToken: Invalid recipient of the initial supply");
        accessControls = _accessControls;
        _mint(_initialSupplyRecipient, TEN_BILLION * (10 ** uint256(decimals())));
    }

    /**
     @notice Overrides the `transfer()` method to include transfer conditions
     @dev Transfers are possible when either transfers are enabled or the sender is whitelisted
     @param _recipient Address receiving the amount of tokens being transferred
     @param _amount Value being transferred
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        require(transfersEnabled || accessControls.hasWhitelistRole(_msgSender()), "CudosToken.transfer: Caller can not currently transfer");

        return super.transfer(_recipient, _amount);
    }

    /**
     @notice Overrides the `transferFrom()` method to include transfer conditions
     @dev Transfers are possible when either transfers are enabled or the sender is whitelisted
     @param _sender Address that currently owns the tokens
     @param _recipient Address receiving the amount of tokens being transferred
     @param _amount Value being transferred
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        require(transfersEnabled || accessControls.hasWhitelistRole(_msgSender()), "CudosToken.transferFrom: Caller can not currently transfer");

        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     @notice Admin function for toggling transfers on
     @dev The sender must have the admin role to call this method
     */
    function toggleTransfers() external {
        require(accessControls.hasAdminRole(_msgSender()), "CudosToken.toggleTransfers: Only admin");
        require(transfersEnabled == false, "CudosToken.toggleTransfers: Only can be toggled on once");
        transfersEnabled = true;
    }

    /**
     @notice Admin function for withdrawing any Ether accidentally sent to the contract
     @dev The sender must have the admin role to call this method
     @param _withdrawalAccount where the Ether needs to be sent to
     */
    function withdrawStuckEther(address payable _withdrawalAccount) external {
        require(accessControls.hasAdminRole(_msgSender()), "CudosToken.withdrawStuckEther: Only admin");
        require(_withdrawalAccount != address(0), "CudosToken.withdrawStuckEther: Invalid address provided");
        _withdrawalAccount.transfer(address(this).balance);
    }

    /**
     @notice Admin function for updating the access control contract used by the token
     @dev The sender must have the admin role to call this method
     @param _accessControls Address of the new access controls contract
     */
    function updateAccessControls(CudosAccessControls _accessControls) external {
        require(accessControls.hasAdminRole(_msgSender()), "CudosToken.updateAccessControls: Only admin");
        require(address(_accessControls) != address(0), "CudosToken.updateAccessControls: Invalid address provided");
        accessControls = _accessControls;
    }
}