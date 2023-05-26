// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

import "./ImmutablesMinter.sol";

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
}

contract WayOfTheWorm {
    IERC721 private immutable edworm =
        IERC721(0xACd3CF818EFe8ddce84C585ddCB147c4C844D3b3);
    IERC721 private immutable edwone =
        IERC721(0xf65D6475869F61c6dce6aC194B6a7dbE45a91c63);
    ImmutablesMinter private immutable minter;
    uint256 private immutable projectId;

    uint256 public mintLimit = 1;
    mapping(address => uint256) public minted;

    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    error LimitReached();
    error NotDisciple();
    error NotOwner();

    constructor(ImmutablesMinter minter_, uint256 projectId_) {
        require(
            minter_.owner() == msg.sender || minter_.isApproved(address(this))
        );

        minter = minter_;
        projectId = projectId_;

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // PUBLIC FUNCTIONS

    function mint() external {
        address disciple = msg.sender;
        if (!isDisciple(disciple)) {
            revert NotDisciple();
        } else if (minted[disciple] >= mintLimit) {
            revert LimitReached();
        }

        minted[disciple]++;
        minter.mint(projectId, disciple);
    }

    // OWNER FUNCTIONS

    /// @notice Update the amount of mints allowed per disciple
    function updateMintLimit(uint256 newLimit) external {
        if (msg.sender != owner) revert NotOwner();
        mintLimit = newLimit;
    }

    /// @notice Transfer ownership of this contract to a new address
    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /// @notice Call a contract with the specified data
    function call(
        address contractAddress,
        bytes calldata data
    ) external payable returns (bytes memory) {
        if (msg.sender != owner) revert NotOwner();
        (bool success, bytes memory returndata) = contractAddress.call{
            value: msg.value
        }(data);
        require(success);
        return returndata;
    }

    // VIEW AND PURE FUNCTIONS

    /// @notice Query if an address is a Worm disciple
    function isDisciple(address disciple) public view returns (bool) {
        return
            edwone.balanceOf(disciple) != 0 || edworm.balanceOf(disciple) != 0;
    }

    /// @notice Query if an address can mint
    function canMint(address disciple) public view returns (bool) {
        return minted[disciple] < mintLimit && isDisciple(disciple);
    }

    /// @notice Query if this contract implements an interface
    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC-165
            interfaceId == 0x7f5828d0; // ERC-173
    }

    receive() external payable {}

    fallback() external payable {}
}