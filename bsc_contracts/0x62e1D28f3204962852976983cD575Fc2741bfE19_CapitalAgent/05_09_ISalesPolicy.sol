// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISalesPolicy {
    function setPremiumPool(address _premiumPool) external;

    function setExchangeAgent(address _exchangeAgent) external;

    function setCapitalAgent(address _capitalAgent) external;

    function setBuyPolicyMaxDeadline(uint256 _maxDeadline) external;

    function approvePremium(address _premiumCurrency) external;

    function setProtocolURI(string memory newURI) external;

    function setSigner(address _signer) external;

    function updatePolicyExpired(uint256 _policyId) external;

    function markToClaim(uint256 _policyId) external;

    function allPoliciesLength() external view returns (uint256);

    function getPolicyData(uint256 _policyId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}