pragma solidity ^0.8.0;

interface IStonksVotingToken {

    function burn(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}
