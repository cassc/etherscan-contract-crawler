// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./registry/IRegistry.sol";
import "./governor/IGovernanceSettings.sol";
import "./governor/IGovernorProposals.sol";

interface IPool is IGovernorProposals {
    function initialize(
        address owner_,
        string memory trademark_,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        IRegistry.CompanyInfo memory companyInfo_
    ) external;

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function cancelProposal(uint256 proposalId) external;

    function owner() external view returns (address);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function paused() external view returns (bool);

    function getToken(IToken.TokenType tokenType_)
        external
        view
        returns (IToken);
}