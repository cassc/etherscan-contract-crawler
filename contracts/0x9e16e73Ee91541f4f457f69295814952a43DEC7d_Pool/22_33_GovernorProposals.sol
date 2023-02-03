// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./Governor.sol";
import "./GovernanceSettings.sol";
import "../interfaces/IPool.sol";
import "../interfaces/governor/IGovernorProposals.sol";
import "../interfaces/IService.sol";
import "../interfaces/registry/IRecordsRegistry.sol";
import "../interfaces/ITGE.sol";
import "../interfaces/IToken.sol";
import "../libraries/ExceptionsLibrary.sol";

abstract contract GovernorProposals is
    Initializable,
    Governor,
    GovernanceSettings,
    IGovernorProposals
{
    // STORAGE

    /// @dev Service address
    IService public service;

    /// @notice Storage gap (for future upgrades)
    uint256[50] private __gap;

    // MODIFIERS

    modifier onlyValidProposer() {
        require(
            _getCurrentVotes(msg.sender) >= proposalThreshold,
            ExceptionsLibrary.THRESHOLD_NOT_REACHED
        );
        _;
    }

    // INITIALIZER

    function __GovernorProposals_init(IService service_)
        internal
        onlyInitializing
    {
        service = service_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Propose transfer of assets
     * @param asset Asset to transfer (address(0) for ETH transfers)
     * @param recipients Transfer recipients
     * @param amounts Transfer amounts
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeTransfer(
        address asset,
        address[] memory recipients,
        uint256[] memory amounts,
        string memory description,
        string memory metaHash
    ) external onlyValidProposer returns (uint256 proposalId) {
        // Check lengths
        require(
            recipients.length == amounts.length,
            ExceptionsLibrary.INVALID_VALUE
        );

        // Prepare proposal actions
        address[] memory targets = new address[](recipients.length);
        uint256[] memory values = new uint256[](recipients.length);
        bytes[] memory callDatas = new bytes[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            if (asset == address(0)) {
                targets[i] = recipients[i];
                callDatas[i] = "";
                values[i] = amounts[i];
            } else {
                targets[i] = asset;
                callDatas[i] = abi.encodeWithSelector(
                    IERC20Upgradeable.transfer.selector,
                    recipients[i],
                    amounts[i]
                );
                values[i] = 0;
            }
        }

        // Create proposal
        return
            _propose(
                ProposalCoreData({
                    targets: targets,
                    values: values,
                    callDatas: callDatas,
                    quorumThreshold: quorumThreshold,
                    decisionThreshold: decisionThreshold,
                    executionDelay: _getDelay(
                        IRecordsRegistry.EventType.Transfer
                    )
                }),
                ProposalMetaData({
                    proposalType: IRecordsRegistry.EventType.Transfer,
                    description: description,
                    metaHash: metaHash
                }),
                votingDuration
            );
    }

    /**
     * @dev Proposal to launch a new token generation event (TGE), can be created only if the maximum supply threshold value for an existing token has not been reached or if a new token is being created, in which case, a new token contract will be deployed simultaneously with the TGE contract.
     * @param tgeInfo TGE parameters
     * @param tokenInfo Token parameters
     * @param metadataURI TGE metadata URI
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeTGE(
        ITGE.TGEInfo memory tgeInfo,
        IToken.TokenInfo memory tokenInfo,
        string memory metadataURI,
        string memory description,
        string memory metaHash
    ) external onlyValidProposer returns (uint256 proposalId) {
        // Get cap and supply data
        uint256 totalSupply = 0;
        IToken token = IPool(address(this)).getToken(tokenInfo.tokenType);
        if (tokenInfo.tokenType == IToken.TokenType.Governance) {
            tokenInfo.cap = token.cap();
            totalSupply = token.totalSupply();
        } else if (tokenInfo.tokenType == IToken.TokenType.Preference) {
            if (address(token) != address(0)) {
                if (token.isPrimaryTGESuccessful()) {
                    tokenInfo.cap = token.cap();
                    totalSupply = token.totalSupply();
                }
            }
        }

        // Validate TGE info
        service.validateTGEInfo(
            tgeInfo,
            tokenInfo.cap,
            totalSupply,
            tokenInfo.tokenType
        );

        // Prepare proposal action
        address[] memory targets = new address[](1);
        targets[0] = address(service);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = abi.encodeWithSelector(
            IService.createSecondaryTGE.selector,
            tgeInfo,
            tokenInfo,
            metadataURI
        );

        // Propose
        return
            _propose(
                ProposalCoreData({
                    targets: targets,
                    values: values,
                    callDatas: callDatas,
                    quorumThreshold: quorumThreshold,
                    decisionThreshold: decisionThreshold,
                    executionDelay: _getDelay(IRecordsRegistry.EventType.TGE)
                }),
                ProposalMetaData({
                    proposalType: IRecordsRegistry.EventType.TGE,
                    description: description,
                    metaHash: metaHash
                }),
                votingDuration
            );
    }

    /**
     * @notice A proposal that changes the governance settings. First of all, the percentage of the total number of free votes changes, the achievement of which within the framework of voting leads to the achievement of a quorum (the vote will be considered to have taken place, that is, one of the conditions for a positive decision on the propositional is fulfilled). Further, the Decision Threshold can be changed, which is set as a percentage of the sum of the votes "for" and "against" for a specific proposal, at which the sum of the votes "for" ensures a positive decision-making. In addition, a set of delays (measured in blocks) is set, used for certain features of transactions submitted to the proposal. The duration of all subsequent votes is also set (measured in blocks) and the number of Governance tokens required for the address to create a proposal. All parameters are set in one transaction. To change one of the parameters, it is necessary to send the old values of the other settings along with the changed value of one setting.
     * @param settings New governance settings
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeGovernanceSettings(
        NewGovernanceSettings memory settings,
        string memory description,
        string memory metaHash
    ) external onlyValidProposer returns (uint256 proposalId) {
        // Validate settings
        _validateGovernanceSettings(settings);

        // Prepare proposal action
        address[] memory targets = new address[](1);
        targets[0] = address(this);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = abi.encodeWithSelector(
            IGovernanceSettings.setGovernanceSettings.selector,
            settings
        );

        // Propose
        return
            _propose(
                ProposalCoreData({
                    targets: targets,
                    values: values,
                    callDatas: callDatas,
                    quorumThreshold: quorumThreshold,
                    decisionThreshold: decisionThreshold,
                    executionDelay: _getDelay(IRecordsRegistry.EventType.GovernanceSettings)
                }),
                ProposalMetaData({
                    proposalType: IRecordsRegistry.EventType.GovernanceSettings,
                    description: description,
                    metaHash: metaHash
                }),
                votingDuration
            );
    }

    // INTERNAL VIEW FUNCTIONS

    /**
     * @notice Gets execution delay for given proposal type
     * @param proposalType Proposal type
     * @return Execution delay
     */
    function _getDelay(IRecordsRegistry.EventType proposalType)
        internal
        view
        returns (uint256)
    {
        return
            MathUpgradeable.max(
                executionDelays[IRecordsRegistry.EventType.None],
                executionDelays[proposalType]
            );
    }

    // ABSTRACT FUNCTIONS

    /**
     * @dev Function that gets amount of votes for given account
     * @param account Account's address
     * @return Amount of votes
     */
    function _getCurrentVotes(address account)
        internal
        view
        virtual
        returns (uint256);
}