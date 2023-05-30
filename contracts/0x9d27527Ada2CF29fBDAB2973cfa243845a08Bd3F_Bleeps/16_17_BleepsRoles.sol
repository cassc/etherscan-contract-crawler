// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ReverseRegistrar {
    function setName(string memory name) external returns (bytes32);
}

interface ENS {
    function owner(bytes32 node) external view returns (address);
}

contract BleepsRoles {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event TokenURIAdminSet(address newTokenURIAdmin);
    event RoyaltyAdminSet(address newRoyaltyAdmin);
    event MinterAdminSet(address newMinterAdmin);
    event GuardianSet(address newGuardian);
    event MinterSet(address newMinter);

    bytes32 internal constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
    ENS internal immutable _ens;

    ///@notice the address of the current owner, that is able to set ENS names and withdraw ERC20 owned by the contract.
    address public owner;

    /// @notice tokenURIAdmin can update the tokenURI contract, this is intended to be relinquished once the tokenURI has been heavily tested in the wild and that no modification are needed.
    address public tokenURIAdmin;

    /// @notice address allowed to set royalty parameters
    address public royaltyAdmin;

    /// @notice minterAdmin can update the minter. At the time being there is 576 Bleeps but there is space for extra instrument and the upper limit is 1024.
    /// could be given to the DAO later so instrument can be added, the sale of these new bleeps could benenfit the DAO too and add new members.
    address public minterAdmin;

    /// @notice address allowed to mint, allow the sale contract to be separated from the token contract that can focus on the core logic
    /// Once all 1024 potential bleeps (there could be less, at minimum there are 576 bleeps) are minted, no minter can mint anymore
    address public minter;

    /// @notice guardian has some special vetoing power to guide the direction of the DAO. It can only remove rights from the DAO. It could be used to immortalize rules.
    /// For example: the royalty setup could be frozen.
    address public guardian;

    constructor(
        address ens,
        address initialOwner,
        address initialTokenURIAdmin,
        address initialMinterAdmin,
        address initialRoyaltyAdmin,
        address initialGuardian
    ) {
        _ens = ENS(ens);
        owner = initialOwner;
        tokenURIAdmin = initialTokenURIAdmin;
        royaltyAdmin = initialRoyaltyAdmin;
        minterAdmin = initialMinterAdmin;
        guardian = initialGuardian;
        emit OwnershipTransferred(address(0), initialOwner);
        emit TokenURIAdminSet(initialTokenURIAdmin);
        emit RoyaltyAdminSet(initialRoyaltyAdmin);
        emit MinterAdminSet(initialMinterAdmin);
        emit GuardianSet(initialGuardian);
    }

    function setENSName(string memory name) external {
        require(msg.sender == owner, "NOT_AUTHORIZED");
        ReverseRegistrar reverseRegistrar = ReverseRegistrar(_ens.owner(ADDR_REVERSE_NODE));
        reverseRegistrar.setName(name);
    }

    function withdrawERC20(IERC20 token, address to) external {
        require(msg.sender == owner, "NOT_AUTHORIZED");
        token.transfer(to, token.balanceOf(address(this)));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external {
        address oldOwner = owner;
        require(msg.sender == oldOwner);
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice set the new tokenURIAdmin that can change the tokenURI
     * Can only be called by the current tokenURI admin.
     */
    function setTokenURIAdmin(address newTokenURIAdmin) external {
        require(
            msg.sender == tokenURIAdmin || (msg.sender == guardian && newTokenURIAdmin == address(0)),
            "NOT_AUTHORIZED"
        );
        tokenURIAdmin = newTokenURIAdmin;
        emit TokenURIAdminSet(newTokenURIAdmin);
    }

    /**
     * @notice set the new royaltyAdmin that can change the royalties
     * Can only be called by the current royalty admin.
     */
    function setRoyaltyAdmin(address newRoyaltyAdmin) external {
        require(
            msg.sender == royaltyAdmin || (msg.sender == guardian && newRoyaltyAdmin == address(0)),
            "NOT_AUTHORIZED"
        );
        royaltyAdmin = newRoyaltyAdmin;
        emit RoyaltyAdminSet(newRoyaltyAdmin);
    }

    /**
     * @notice set the new minterAdmin that can set the minter for Bleeps
     * Can only be called by the current minter admin.
     */
    function setMinterAdmin(address newMinterAdmin) external {
        require(
            msg.sender == minterAdmin || (msg.sender == guardian && newMinterAdmin == address(0)),
            "NOT_AUTHORIZED"
        );
        minterAdmin = newMinterAdmin;
        emit MinterAdminSet(newMinterAdmin);
    }

    /**
     * @notice set the new guardian that can freeze the other admins (except owner).
     * Can only be called by the current guardian.
     */
    function setGuardian(address newGuardian) external {
        require(msg.sender == guardian, "NOT_AUTHORIZED");
        guardian = newGuardian;
        emit GuardianSet(newGuardian);
    }

    /**
     * @notice set the new minter that can mint Bleeps (up to 1024).
     * Can only be called by the minter admin.
     */
    function setMinter(address newMinter) external {
        require(msg.sender == minterAdmin, "NOT_AUTHORIZED");
        minter = newMinter;
        emit MinterSet(newMinter);
    }
}