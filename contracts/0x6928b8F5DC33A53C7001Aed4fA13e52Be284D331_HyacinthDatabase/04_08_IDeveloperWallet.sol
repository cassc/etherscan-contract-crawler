pragma solidity ^0.8.0;

interface IDeveloperWallet {
    function payOutBounty(
        address contract_,
        address[] calldata collaborators_,
        uint256[] calldata percentsOfBounty_
    ) external returns (uint256 level_);

    function rollOverBounty(address previous_, address new_) external;
    function currentBountyLevel(address contract_) external view returns (uint256 level_, uint256 bounty_);
}