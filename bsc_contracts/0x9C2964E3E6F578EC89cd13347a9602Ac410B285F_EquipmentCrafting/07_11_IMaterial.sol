//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMaterial {
    struct MaterialData {
        string name;
        uint mined;
    }

    event MaterialCreated(uint indexed materialId, string name);

    /**
     * @notice Create a material.
     */
    function createMaterial(string memory name) external;

    /**
     * @notice Mint a material.
     */
    function mint(address account, uint materialId, uint amount) external;

    /**
     * @notice Burn a list of materials.
     */
    function burn(address account, uint materialId, uint amount) external;

    /**
     * @notice Get material balance of an address.
     */
    function getBalance(address account, uint materialId) external view returns (uint);

    /**
     * @notice Get material data.
     */
    function getMaterialData(uint materialId) external view returns (MaterialData memory);
}