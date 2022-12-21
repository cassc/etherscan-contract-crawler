// SPDX-License-Identifier: MIT
// Author: Daniel Von Fange (@DanielVF)

interface IDividedFactory {
    function pools(address collection) external returns (address);
    function deployNftContract() external view returns (address);
    function POOL_BYTECODE_HASH() external view returns (bytes32);
    function deploy(address collection) external returns (address);
}