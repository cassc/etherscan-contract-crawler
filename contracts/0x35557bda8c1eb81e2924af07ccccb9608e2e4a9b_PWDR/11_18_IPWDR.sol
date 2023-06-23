// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPWDR {
    event EpochUpdated(address _address, uint256 _epoch, uint256 _phase);

    function MAX_SUPPLY() external view returns (uint256);
    function maxSupplyHit() external view returns (bool);
    function transferFee() external view returns (uint256);
    function currentEpoch() external view returns (uint256);
    function currentPhase() external view returns (uint256);
    function epochMaxSupply(uint _epoch) external view returns (uint256);
    function epochBaseRate(uint _epoch) external view returns (uint256);

    function accumulating() external view returns (bool);
    function currentMaxSupply() external view returns (uint256);
    function currentBaseRate() external view returns (uint256);
    // function incrementEpoch() external;
    // function incrementPhase() external;
    
    function updateEpoch(uint256 _epoch, uint256 _phase) external;
    function mint(address _to, uint256 _amount) external;
    function setTransferFee(uint256 _transferFee) external;
    function addToTransferWhitelist(bool _addToSenderWhitelist, address _address) external;
    function removeFromTransferWhitelist(bool _removeFromSenderWhitelist, address _address) external;
}