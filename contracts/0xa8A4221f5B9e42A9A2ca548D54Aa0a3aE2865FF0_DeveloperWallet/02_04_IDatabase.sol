pragma solidity ^0.8.0;

interface IDatabase {
    enum STATUS {
        NOTAUDITED,
        PENDING,
        PASSED,
        FAILED
    }

    function HYACINTH_FEE() external view returns (uint256);

    function USDC() external view returns (address);

    function audits(address contract_)
        external
        view
        returns (
            address,
            address,
            STATUS,
            string memory,
            bool
        );

    function auditors(address auditor_)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function approvedAuditor(address auditor_) external view returns (bool isAuditor_);

    function hyacinthWallet() external view returns (address);

    function beingAudited(address previous_) external;

    function mintPOD() external returns (uint256 id_, address developerWallet_);

    function addApprovedAuditor(address[] calldata auditors_) external;

    function removeApprovedAuditor(address[] calldata auditors_) external;

    function giveAuditorFeedback(address contract_, bool positive_) external;

    function pickUpAudit(address contract_) external;

    function submitResult(
        address contract_,
        STATUS result_,
        string memory description_
    ) external;

    function rollOverExpired(address contract_) external;

    function proposeCollaboration(
        address contract_,
        address collaborator_,
        uint256 timeLive_,
        uint256 percentOfBounty_
    ) external;

    function acceptCollaboration(address contract_) external;

    function levelsCompleted(address auditor_) external view returns (uint256[4] memory);
}