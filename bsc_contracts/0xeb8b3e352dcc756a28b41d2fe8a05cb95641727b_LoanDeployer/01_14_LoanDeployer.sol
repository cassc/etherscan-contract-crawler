// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Loan.sol";
import "./Interface/ILoan.sol";

contract LoanDeployer is UUPSUpgradeable, OwnableUpgradeable {

    address public governance;

    modifier onlyGovernance() {
        require(governance == msg.sender, "Caller is not governance");
        _;
    }

    function initialize (address _governance) public initializer
    {
        governance = _governance;
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementaion) internal override onlyOwner {}

    function createLoan(
        address _owner,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint64 _duration,
        uint64 _paymentPeriod,
        uint8 _interestRate,
        address _teamWallet
    ) external onlyGovernance returns (address loan){
        
        bytes memory bytecode = type(Loan).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(governance, msg.sender, _tokenAddress, _tokenAmount, _duration, _paymentPeriod, _interestRate, _teamWallet));
        assembly {
            loan := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ILoan(loan).initialize(governance, _owner, _tokenAddress, _tokenAmount, _duration, _paymentPeriod, _interestRate, _teamWallet);
    }

    function setGovernance(address _governance) public onlyOwner {
        require(governance != _governance, "Same value");
        governance = _governance;
    }

}