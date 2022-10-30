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

    uint public numPToksInVault; // all deposits from all pledgers

    constructor() {
        _initialize();
    }

    function initialize(address owner_) external override onlyIfNotInitialized { //@PUBFUNC called by platform //@CLONE
        markAsInitialized(owner_);
        _initialize();
    }

    function _initialize() private {
        _registerInterface( type(IVault).interfaceId);
        numPToksInVault = 0;
    }


    function increaseBalance( uint numPaymentTokens_) external override onlyOwner {
        verifyInitialized();
        _addToBalance( numPaymentTokens_);
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


    function transferPToksToTeamWallet( uint totalSumToTransfer_, uint platformCutPromils_, address platformAddr_)
                                         external override onlyOwner returns(uint,uint) { //@PUBFUNC
        // called by project on successful milestone
        // @PROTECT: DoS, Re-entry
        verifyInitialized();

        uint actuallyTransferred_ = calcActualPTokNumAvailableForTransfer( totalSumToTransfer_);

        address teamWallet_ = getTeamWallet();

        uint platformCut_ = (actuallyTransferred_ * platformCutPromils_) / 1000;

        uint teamCut_ = actuallyTransferred_ - platformCut_;


        // transfer from vault to team
        _transferFromVaultTo( teamWallet_, teamCut_);

        _transferFromVaultTo( platformAddr_, platformCut_);

        emit PTokTransferredToTeamWallet( teamCut_, teamWallet_, platformCut_, platformAddr_);

        return (teamCut_, platformCut_);
    }


    function _transferFromVaultTo( address receiverAddr_, uint numPToksToTransfer_) private returns(uint) {
        uint actuallyTransferred_ = calcActualPTokNumAvailableForTransfer( numPToksToTransfer_);

        _subtractFromBalance( actuallyTransferred_);

        address paymentTokenAddress_ = getPaymentTokenAddress();

        bool transferred_ = IERC20( paymentTokenAddress_).transfer( receiverAddr_, actuallyTransferred_);
        require( transferred_, "Failed to transfer payment tokens");

        return actuallyTransferred_;
    }



    function calcActualPTokNumAvailableForTransfer( uint shouldBeTranserred_) private view returns(uint) {

        uint actuallyTransferred_ = shouldBeTranserred_;

        // 1. correct by num PToks in vault
        if (actuallyTransferred_ > numPToksInVault) {
            actuallyTransferred_ = numPToksInVault;
        }

        // 2. correct by num PToks actually owned by vault
        uint totalPToksOwnedByVault_ = _totalNumPToksOwnedByVault();
        if (actuallyTransferred_ > totalPToksOwnedByVault_) {
            actuallyTransferred_ = totalPToksOwnedByVault_;
        }

        return actuallyTransferred_;
    }


    function _totalNumPToksOwnedByVault() private view returns(uint) {
        address paymentTokenAddress_ = getPaymentTokenAddress();
        return IERC20( paymentTokenAddress_).balanceOf( address(this));
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
        return numPToksInVault;
    }

    function totalAllPledgerDeposits() public view override returns(uint) {
        return numPToksInVault;
    }


    function getOwner() public override( InitializedOnce, IVault) view returns (address) {
        return InitializedOnce.getOwner();
    }


    //------ retain connected project ownership (behavior declaration)

    function renounceOwnership() public view override onlyOwner {
        revert VaultOwnershipCannotBeRenounced();
    }

    function _addToBalance( uint toAdd_) private {
        numPToksInVault += toAdd_;
    }

    function _subtractFromBalance( uint toSubtract_) private {
        numPToksInVault -= toSubtract_;
    }

}