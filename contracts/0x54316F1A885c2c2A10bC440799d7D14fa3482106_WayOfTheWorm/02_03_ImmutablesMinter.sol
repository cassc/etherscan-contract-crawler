// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/proxy/Clones.sol";

interface IImmutablesArt {
    function anyoneMintProjectEdition(uint256) external payable;

    function artistUpdateProjectArtistAddress(uint256, address) external;

    function currentTokenId() external view returns (uint256);

    function projectIdToRoyaltyAddress(
        uint256
    ) external view returns (IRoyaltyManager);

    function safeTransferFrom(address, address, uint256) external;
}

interface IRoyaltyManager {
    function release() external;
}

contract ImmutablesMinter {
    /// @notice The ImmutablesArt contract
    IImmutablesArt public immutable immutablesArt;
    address private immutable base;

    bool private initialized = true;

    /// @notice The owner address
    address public owner;

    /// @notice Query if an account is approved to mint
    mapping(address => bool) public isApproved;

    event Approval(address indexed operator, bool approved);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    error NotApproved();
    error NotOwner();

    constructor(IImmutablesArt immutablesArt_) {
        immutablesArt = immutablesArt_;
        base = address(this);

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice A function for intializing a cloned copy of this contract
    function initialize(address owner_) external {
        require(!initialized);

        initialized = true;
        owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /// @notice A function that allows you to clone this contract
    function clone() external returns (ImmutablesMinter) {
        ImmutablesMinter newMinter = ImmutablesMinter(
            payable(Clones.clone(base))
        );
        newMinter.initialize(msg.sender);
        return newMinter;
    }

    // OPERATOR FUNCTIONS

    /// @notice Mint an edition from a project
    function mint(
        uint256 projectId,
        address to
    ) external payable returns (uint256 tokenId) {
        if (!isApproved[msg.sender] && msg.sender != owner)
            revert NotApproved();

        immutablesArt.anyoneMintProjectEdition(projectId);
        tokenId = immutablesArt.currentTokenId();
        immutablesArt.safeTransferFrom(address(this), to, tokenId);
    }

    // OWNER FUNCTIONS

    /// @notice Approve an account to mint
    function setApproval(address operator, bool approved) external {
        if (msg.sender != owner) revert NotOwner();
        isApproved[operator] = approved;
        emit Approval(operator, approved);
    }

    /// @notice Transfer ownership of this contract to a new address
    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /// @notice Set the artist on a project to this contract's owner
    function relinquishProject(uint256 projectId) external {
        if (msg.sender != owner) revert NotOwner();
        immutablesArt.artistUpdateProjectArtistAddress(projectId, owner);
    }

    /// @notice Send any royalties and the contract balance to the owner
    function release(uint256 projectId) external returns (bytes memory) {
        if (msg.sender != owner) revert NotOwner();
        immutablesArt.projectIdToRoyaltyAddress(projectId).release();
        (bool success, bytes memory returndata) = owner.call{
            value: address(this).balance
        }("");
        require(success);
        return returndata;
    }

    /// @notice Transfer ERC-20 tokens to the owner
    function withdrawl(
        address erc20,
        uint256 value
    ) external returns (bytes memory) {
        if (msg.sender != owner) revert NotOwner();
        // "0xa9059cbb" is the selector for ERC-20 transfer.
        (bool success, bytes memory returndata) = erc20.call(
            abi.encodeWithSelector(0xa9059cbb, owner, value)
        );
        require(success);
        return returndata;
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