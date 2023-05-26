pragma solidity 0.5.17;

import "./PeakDeFiFund.sol";

contract PeakDeFiProxy {
    address payable public peakdefiFundAddress;

    event UpdatedFundAddress(address payable _newFundAddr);

    constructor(address payable _fundAddr) public {
        peakdefiFundAddress = _fundAddr;
        emit UpdatedFundAddress(_fundAddr);
    }

    function updatePeakDeFiFundAddress() public {
        require(msg.sender == peakdefiFundAddress, "Sender not PeakDeFiFund");
        address payable nextVersion = PeakDeFiFund(peakdefiFundAddress)
            .nextVersion();
        require(nextVersion != address(0), "Next version can't be empty");
        peakdefiFundAddress = nextVersion;
        emit UpdatedFundAddress(peakdefiFundAddress);
    }
}