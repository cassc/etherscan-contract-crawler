pragma solidity >=0.5.0;

interface IFee {
    function fee() external view returns (uint);
    function setFee(uint) external;

    function setFeeTo(address) external;
    function feeSetter() external view returns (address);
}