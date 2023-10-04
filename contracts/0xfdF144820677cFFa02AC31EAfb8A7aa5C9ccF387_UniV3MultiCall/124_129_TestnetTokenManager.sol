// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";
import {DataTypesPeerToPool} from "../peer-to-pool/DataTypesPeerToPool.sol";
import {Errors} from "../Errors.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";

contract TestnetTokenManager is ERC20, Ownable2Step, IMysoTokenManager {
    uint8 internal _decimals;
    address internal _vaultCompartmentVictim;
    address internal _vaultAddr;
    uint256 internal _borrowerReward;
    uint256 internal _lenderReward;
    uint256 internal _vaultCreationReward;
    uint256 internal constant MAX_SUPPLY = 100_000_000 ether;

    constructor() ERC20("TYSO", "TYSO") {
        _decimals = 18;
        _borrowerReward = 1 ether;
        _lenderReward = 1 ether;
        _vaultCreationReward = 1 ether;
        _transferOwnership(msg.sender);
    }

    function processP2PBorrow(
        uint128[2] memory currProtocolFeeParams,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata /*borrowInstructions*/,
        DataTypesPeerToPeer.Loan calldata loan,
        address lenderVault
    ) external returns (uint128[2] memory applicableProtocolFeeParams) {
        applicableProtocolFeeParams = currProtocolFeeParams;
        if (totalSupply() + _borrowerReward + _lenderReward < MAX_SUPPLY) {
            _mint(loan.borrower, _borrowerReward);
            _mint(lenderVault, _lenderReward);
        }
    }

    function processP2PCreateVault(
        uint256 /*numRegisteredVaults*/,
        address /*vaultCreator*/,
        address newLenderVaultAddr
    ) external {
        _mint(newLenderVaultAddr, _vaultCreationReward);
    }

    // solhint-disable no-empty-blocks
    function processP2PCreateWrappedTokenForERC721s(
        address /*tokenCreator*/,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[]
            calldata /*tokensToBeWrapped*/,
        bytes calldata /*mysoTokenManagerData*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PCreateWrappedTokenForERC20s(
        address /*tokenCreator*/,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[]
            calldata /*tokensToBeWrapped*/,
        bytes calldata /*mysoTokenManagerData*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PoolDeposit(
        address /*fundingPool*/,
        address /*depositor*/,
        uint256 /*depositAmount*/,
        uint256 /*depositLockupDuration*/,
        uint256 /*transferFee*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PoolSubscribe(
        address /*fundingPool*/,
        address /*subscriber*/,
        address /*loanProposal*/,
        uint256 /*subscriptionAmount*/,
        uint256 /*subscriptionLockupDuration*/,
        uint256 /*totalSubscriptions*/,
        DataTypesPeerToPool.LoanTerms calldata /*loanTerms*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PoolLoanFinalization(
        address /*loanProposal*/,
        address /*fundingPool*/,
        address /*arranger*/,
        address /*borrower*/,
        uint256 /*grossLoanAmount*/,
        bytes calldata /*mysoTokenManagerData*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PoolCreateLoanProposal(
        address /*fundingPool*/,
        address /*proposalCreator*/,
        address /*collToken*/,
        uint256 /*arrangerFee*/,
        uint256 /*numLoanProposals*/
    ) external {}

    function setRewards(
        uint256 borrowerReward,
        uint256 lenderReward,
        uint256 vaultCreationReward
    ) external {
        _checkOwner();
        _borrowerReward = borrowerReward;
        _lenderReward = lenderReward;
        _vaultCreationReward = vaultCreationReward;
    }

    function transferOwnership(address _newOwnerProposal) public override {
        _checkOwner();
        if (
            _newOwnerProposal == address(0) ||
            _newOwnerProposal == address(this) ||
            _newOwnerProposal == pendingOwner() ||
            _newOwnerProposal == owner()
        ) {
            revert Errors.InvalidNewOwnerProposal();
        }
        super._transferOwnership(_newOwnerProposal);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}