pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMosNftPool {
    function getSuperior(address account) external view returns (address);

    function nftOwner(address account) external view returns (uint);
}