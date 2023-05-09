// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interface/IDatabase.sol";

/// @title   Developer Wallet
/// @notice  Contract that a developer is deployed upon minting of Proof of Developer NFT
/// @author  Hyacinth
contract DeveloperWallet {
    /// EVENTS ///

    /// @notice                 Emitted after bounty has been added to
    /// @param auditedContract  Address of contract bounty is being added to
    /// @param totalBounty      Total amount of bounty
    event AddedToBounty(address indexed auditedContract, uint256 indexed totalBounty);

    /// ERRORS ///

    /// @notice Error for if contract is not being audited
    error NotBeingAudited();
    /// @notice Error for if msg.sender is not database
    error NotDatabase();
    /// @notice Error for if contrac was not developed by developer
    error NotDeveloper();
    /// @notice Error for if bounty has been paid out already
    error BountyPaid();

    /// STATE VARIABLES ///

    /// @notice Address of developer
    address public immutable owner;
    /// @notice Address of USDC
    address public immutable USDC;
    /// @notice Address of database contract
    address public immutable database;

    /// @notice Bounty amount on contract
    mapping(address => uint256) public bountyOnContract;
    /// @notice Bool if bounty has been paid out
    mapping(address => bool) public bountyPaidOut;

    /// CONSTRUCTOR ///

    constructor(address owner_, address database_) {
        owner = owner_;
        database = database_;
        USDC = IDatabase(database_).USDC();
    }

    /// EXTERNAL FUNCTION ///

    /// @notice           Add to bounty of `contract_`
    /// @param contract_  Address of contract to add bounty to
    /// @param amount_    Amount of stable to add to bounty
    function addToBounty(address contract_, uint256 amount_) external {
        (, address developer_, , , ) = IDatabase(database).audits(contract_);
        if (developer_ != owner || developer_ != msg.sender) revert NotDeveloper();
        (, , IDatabase.STATUS status_, , ) = IDatabase(database).audits(contract_);
        if (status_ != IDatabase.STATUS.PENDING) revert NotBeingAudited();
        IERC20(USDC).transferFrom(msg.sender, address(this), amount_);
        bountyOnContract[contract_] += amount_;

        emit AddedToBounty(contract_, bountyOnContract[contract_]);
    }

    /// DATABASE FUNCTION ///

    /// @notice                   Pays out bounty of `contract_`
    /// @param contract_          Contract to pay bounty out for
    /// @param collaborators_     Array of collaborators for `contract_`
    /// @param percentsOfBounty_  Array of corresponding percents of bounty for `collaborators_` 
    /// @return level_            Level of bounty
    function payOutBounty(
        address contract_,
        address[] calldata collaborators_,
        uint256[] calldata percentsOfBounty_
    ) external returns (uint256 level_) {
        if (msg.sender != database) revert NotDatabase();
        if (bountyPaidOut[contract_]) revert BountyPaid();

        bountyPaidOut[contract_] = true;

        (address auditor_, , , , ) = IDatabase(database).audits(contract_);

        (level_,) = currentBountyLevel(contract_);
        uint256 bounty_ = bountyOnContract[contract_];
        bountyOnContract[contract_] = 0;
        uint256 bountyToDistribute_ = ((bounty_ * (100 - IDatabase(database).HYACINTH_FEE())) / 100);
        uint256 hyacinthReceives_ = bounty_ - bountyToDistribute_;
        IERC20(USDC).transfer(IDatabase(database).hyacinthWallet(), hyacinthReceives_);

        uint256 collaboratorsReceived_;
        for (uint256 i; i < collaborators_.length; ++i) {
            uint256 collaboratorsReceives_ = (bountyToDistribute_ * percentsOfBounty_[i]) / 100;
            IERC20(USDC).transfer(collaborators_[i], collaboratorsReceives_);
            collaboratorsReceived_ += collaboratorsReceives_;
        }

        uint256 auditorReceives_ = bountyToDistribute_ - collaboratorsReceived_;
        IERC20(USDC).transfer(auditor_, auditorReceives_);
    }

    /// @notice           Rolls over bounty of `previous_` to `new_`
    /// @param previous_  Address of roll overed contract
    /// @param new_       Address of new contract after roll over
    function rollOverBounty(address previous_, address new_) external {
        if (msg.sender != database) revert NotDatabase();
        uint256 bounty_ = bountyOnContract[previous_];

        bountyOnContract[previous_] = 0;
        bountyOnContract[new_] = bounty_;
    }

    /// VIEW FUNCTIONS ///

    /// @notice          Returns current `level_` and `bounty_` of `contract_`
    /// @param contract_ Contract to check bounty for
    /// @return level_   Current level of `contract_` bounty
    /// @return bounty_  Current bouty of `contract_`
    function currentBountyLevel(address contract_) public view returns (uint256 level_, uint256 bounty_) {
        bounty_ = bountyOnContract[contract_];

        uint256 decimals_ = 10**IERC20Metadata(USDC).decimals();
        if (bounty_ >= 1000 * decimals_) {
            if (bounty_ < 10000 * decimals_) level_ = 1;
            else if (bounty_ < 100000 * decimals_) level_ = 2;
            else level_ = 3;
        }
    }
}