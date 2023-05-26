// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IFalloutCrystal is IERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function phase1Mint(
        bytes calldata signature_,
        bytes32 salt_,
        uint256 jungle_,
        uint256[] calldata jfgIds_
    ) external payable;

    function phase2Mint(
        bytes calldata signature_,
        bytes32 salt_,
        uint256 jungle_,
        uint256 quantity_
    ) external payable;

    function startPhase1Mint() external;

    function startPhase2Mint() external;

    function endMint() external;

    function setPrimarySalesSplits() external;

    function holdersEthPrice(uint256 j_, uint256 q_)
        external
        pure
        returns (uint256);

    function setSignerAddress(address signerAddress_) external;

    function setRoyaltyReceiver(address royaltyReceiver_) external;

    function setRoyaltyBasisPoints(uint32 royaltyBasisPoints_) external;

    function transferOwnership(address newOwner) external;

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool isOperator);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}