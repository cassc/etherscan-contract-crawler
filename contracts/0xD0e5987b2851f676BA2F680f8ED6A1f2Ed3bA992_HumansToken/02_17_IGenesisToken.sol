// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IGenesisToken {
    function mint(
        address account,
        uint256 category,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function redeem(address _account, uint256 _category) external;

    function privateMintBatch(
        address _account,
        uint256 _amountToMint,
        uint256 _category,
        bytes memory _data
    ) external;
}