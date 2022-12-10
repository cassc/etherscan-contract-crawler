// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./TrusteeReplacement.propo.sol";

/** @title FirstTrusteeElection
 * A proposal to elect the first cohort of trustees, set the voteReward per vote,
 * and fund the TrustedNodes contract to pay them out.
 */
contract FirstTrusteeElection is TrusteeReplacement {
    /**
     * The address of the switcher contract for TrustedNodes contract
     */
    address public immutable switcherTrustedNodes;

    /**
     * The new vote reward per vote that trustees get
     */
    uint256 public immutable voteReward;

    constructor(
        address[] memory _newTrustees,
        address _switcherTrustedNodes,
        uint256 _voteReward
    ) TrusteeReplacement(_newTrustees) {
        switcherTrustedNodes = _switcherTrustedNodes;
        voteReward = _voteReward;
    }

    function name() public pure override returns (string memory) {
        return "The First Trustee Elections";
    }

    function description() public pure override returns (string memory) {
        return
            "Eco Trustees are responsible for governing monetary policy in the Economy. We propose to elect 22 highly qualified candidates as the first group of Eco Trustees; they have been previously introduced to the community and are listed in the proposal URL linked below. This proposal would register their respective wallet addresses to a whitelist for accessing the monetary governance process. This proposal would also fund the Trustee compensation contract with 5,500,000 ECOx, intended to compensate each Trustee with up to 250,000 ECOx over an initial one-year term (~9,615 ECOx per Trustee per successful vote submission). Elected Trustees would begin enacting monetary policy during the system generation proceeding between January 7-21, 2023.";
    }

    /** A URL where more details can be found.
     */
    function url() public pure override returns (string memory) {
        return
            "https://forums.eco.org/t/egp-003-first-eco-trustee-election/101";
    }

    function enacted(address _self) public override {
        bytes32 _trustedNodesId = keccak256("TrustedNodes");
        bytes32 _ecoXID = keccak256("ECOx");

        TrustedNodes _trustedNodes = TrustedNodes(policyFor(_trustedNodesId));
        ECOx ecoX = ECOx(policyFor(_ecoXID));

        //set the new trustees in the TrustedNodes contract
        address[] memory _newTrustees = TrusteeReplacement(_self)
            .returnNewTrustees();
        _trustedNodes.newCohort(_newTrustees);

        //set the new voteReward in the TrustedNodes contract
        Policed(_trustedNodes).policyCommand(
            address(switcherTrustedNodes),
            abi.encodeWithSignature("setVoteReward(uint256)", voteReward)
        );

        //fund the TrustedNodes contract with the voting rewards
        uint256 firstYearFunding = _newTrustees.length *
            voteReward *
            _trustedNodes.GENERATIONS_PER_YEAR();
        ecoX.transfer(address(_trustedNodes), firstYearFunding);
    }
}