// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// artist: Steve Aoki x Stoopid Buddy Stoodios
/// title: ReplicantX
/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./ERC721CollectionBase.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//     ____                    ___                                __        __   __         //
//    /\  _`\                 /\_ \    __                        /\ \__    /\ \ /\ \        //
//    \ \ \L\ \     __   _____\//\ \  /\_\    ___     __      ___\ \ ,_\   \ `\`\/'/'       //
//     \ \ ,  /   /'__`\/\ '__`\\ \ \ \/\ \  /'___\ /'__`\  /' _ `\ \ \/    `\/ > <         //
//      \ \ \\ \ /\  __/\ \ \L\ \\_\ \_\ \ \/\ \__//\ \L\.\_/\ \/\ \ \ \_      \/'/\`\      //
//       \ \_\ \_\ \____\\ \ ,__//\____\\ \_\ \____\ \__/.\_\ \_\ \_\ \__\     /\_\\ \_\    //
//        \/_/\/ /\/____/ \ \ \/ \/____/ \/_/\/____/\/__/\/_/\/_/\/_/\/__/     \/_/ \/_/    //
//                         \ \_\                                                            //
//                          \/_/                                                            //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////

contract ReplicantXPublicSale is ERC721CollectionBase, AdminControl {

    address private immutable REPLICANTX_ADDRESS;

    constructor(address replicantXAddress, address signingAddress) {
        require(!ERC721CollectionBase(replicantXAddress).active());
        REPLICANTX_ADDRESS = replicantXAddress;
        _initialize(
            // Total supply
            4000,
            // Purchase price (0.05 ETH)
            50000000000000000,
            // Purchase limit
            0,
            // Transaction limit
            10,
            // Presale purchase price
            0,
            // Presale purchase limit
            0,
            signingAddress,
            false
        );
        purchaseCount = ERC721CollectionBase(replicantXAddress).purchaseCount();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CollectionBase, AdminControl) returns (bool) {
        return ERC721CollectionBase.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        require(false, "premint not allowed");

        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses) external override adminRequired {
        require(false, "premint not allowed");

        _premint(addresses);
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override (ERC721CollectionBase) returns (uint256) {
        return ERC721CollectionBase(REPLICANTX_ADDRESS).balanceOf(owner);
    }

    function purchase(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) public payable virtual override {
        _validatePurchaseRestrictions();

        require(amount <= purchaseRemaining() && (transactionLimit == 0 || amount <= transactionLimit), "Too many requested");

        // Make sure we are not over purchaseLimit
        _validatePrice(amount);
        _validatePurchaseRequest(message, signature, nonce);
        address[] memory receivers = new address[](amount);
        for (uint i = 0; i < amount;) {
            receivers[i] = msg.sender;
            unchecked {
                i++;
            }
        }
        purchaseCount += amount;
        IERC721Collection(REPLICANTX_ADDRESS).premint(receivers);
    }

    /**
     * @dev mint implementation
     */
    function _mint(address to, uint256) internal override {
        purchaseCount++;
        address[] memory receivers = new address[](1);
        receivers[0] = to;
        IERC721Collection(REPLICANTX_ADDRESS).premint(receivers);
    }
}