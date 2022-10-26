// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../vault/IVault.sol";
import "../platform/IPlatform.sol";
import "../project/IProject.sol";
import "../project/PledgeEvent.sol";
import "../utils/InitializedOnce.sol";


contract CommonGoodVault is IVault, ERC165Storage, InitializedOnce {

    event PTokPlacedInVault( uint sum);

    event PTokTransferredToTeamWallet( uint sumToTransfer_, address indexed teamWallet_, uint platformCut_, address indexed platformAddr_);

    event PTokTransferredToPledger( uint sumToTransfer_, address indexed pledgerAddr_);

    error VaultOwnershipCannotBeTransferred( address _owner, address newOwner);

    error VaultOwnershipCannotBeRenounced();
    //----

    uint public numTokensInVault; // all deposits from all pledgers

    constructor() {
        _initialize();
    }

    function initialize(address owner_) external override onlyIfNotInitialized { //@PUBFUNC called by platform //@CLONE
        markAsInitialized(owner_);
        _initialize();
    }

    function _initialize() private {
        _registerInterface( type(IVault).interfaceId);
        numTokensInVault = 0;
    }

    function increaseBalance( uint numPaymentTokens_) external override onlyOwner {
        verifyInitialized();
        numTokensInVault += numPaymentTokens_;
        emit PTokPlacedInVault( numPaymentTokens_);
    }

    function transferPaymentTokensToPledger( address pledgerAddr_, uint numPaymentTokens_)
                                                    external override onlyOwner returns(uint) {
        // can only be invoked by connected project
        // @PROTECT: DoS, Re-entry
        verifyInitialized();

        uint actuallyRefunded_ = _transferFromVaultTo( pledgerAddr_, numPaymentTokens_);

        emit PTokTransferredToPledger( numPaymentTokens_, pledgerAddr_);

        return actuallyRefunded_;
    }


    function _totalNumOwnedTokens() private view returns(uint) {
        address paymentTokenAddress_ = getPaymentTokenAddress();
        return IERC20( paymentTokenAddress_).balanceOf( address(this));
    }


    function transferPaymentTokenToTeamWallet (uint totalSumToTransfer_, uint platformCut_, address platformAddr_)
                                                external override onlyOwner { //@PUBFUNC
        verifyInitialized();

        // can only be invoked by connected project
        // @PROTECT: DoS, Re-entry
        address teamWallet_ = getTeamWallet();

        require( numTokensInVault >= totalSumToTransfer_, "insufficient numTokensInVault");
        require( _totalNumOwnedTokens() >= totalSumToTransfer_, "insufficient totalOwnedTokens");

        uint teamCut_ = totalSumToTransfer_ - platformCut_;


        // transfer from vault to team
        _transferFromVaultTo( teamWallet_, teamCut_);

        _transferFromVaultTo( platformAddr_, platformCut_);

        emit PTokTransferredToTeamWallet( teamCut_, teamWallet_, platformCut_, platformAddr_);
    }


    function _transferFromVaultTo( address receiverAddr_, uint numTokensToTransfer) private returns(uint) {
        uint actuallyTransferred_ = numTokensToTransfer;

        if (actuallyTransferred_ > numTokensInVault) {
            actuallyTransferred_ = numTokensInVault;
        }

        numTokensInVault -= actuallyTransferred_;

        address paymentTokenAddress_ = getPaymentTokenAddress();

        bool ok = IERC20( paymentTokenAddress_).transfer( receiverAddr_, actuallyTransferred_);
        require( ok, "Failed to transfer payment tokens");

        return actuallyTransferred_;
    }

    //----


    function getPaymentTokenAddress() private view returns(address) {
        address project_ = getOwner();
        return IProject(project_).getPaymentTokenAddress();
    }

    function getTeamWallet() private view returns(address) {
        address project_ = getOwner();
        return IProject(project_).getTeamWallet();
    }


    function changeOwnership( address newOwner) public override( InitializedOnce, IVault) onlyOwnerOrNull {
        return InitializedOnce.changeOwnership( newOwner);
    }

    function vaultBalance() public view override returns(uint) {
        return numTokensInVault;
    }

    function totalAllPledgerDeposits() public view override returns(uint) {
        return numTokensInVault;
    }


    function decreaseTotalDepositsOnPledgerGraceExit(PledgeEvent[] calldata pledgerEvents) external override onlyOwner {
        verifyInitialized();

        uint totalForPledger_ = 0 ;
        for (uint i = 0; i < pledgerEvents.length; i++) {
            totalForPledger_ += pledgerEvents[i].sum;
        }
        numTokensInVault -= totalForPledger_;
    }

    function getOwner() public override( InitializedOnce, IVault) view returns (address) {
        return InitializedOnce.getOwner();
    }


    //------ retain connected project ownership (behavior declaration)

    function renounceOwnership() public view override onlyOwner {
        revert VaultOwnershipCannotBeRenounced();
    }
}