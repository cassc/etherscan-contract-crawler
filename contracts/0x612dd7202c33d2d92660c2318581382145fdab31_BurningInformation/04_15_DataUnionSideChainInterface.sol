pragma solidity 0.8.6;

interface DataUnionSideChainInterface {
    function activeMemberCount() external view returns(uint256);
    function transferToMemberInContract(address recipient, uint amount) external;
    function withdrawAll(address member, bool sendToMainnet) external returns (uint256);
}