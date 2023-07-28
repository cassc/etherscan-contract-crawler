// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";

import "./Z3roIdentity.sol";

contract Z3roOwnership is Ownable, ERC721A, ReentrancyGuard {
    address private immutable multiSig;
    address public z3roIdentity;

    uint256 public mintCost;

    string private baseTokenURI;

    constructor(address identity, address _multiSig)
        ERC721A("z3rocollective", "Z3RO")
    {
        z3roIdentity = identity;
        transferOwnership(tx.origin);
        multiSig = _multiSig;
    }

    /* EVENTS & MODIFIERS*/
    event ownershipMinted(address to, uint256 qty);

    modifier isZ3ro() {
        require(
            _msgSenderERC721A() == z3roIdentity,
            "The caller is not Z3RO, must be Z3roIdentity contract"
        );
        _;
    }

    modifier isEligibleMint(uint256 batchQty) {
        require(
            IERC721A(z3roIdentity).balanceOf(tx.origin) > 0,
            "You need to own Z3RO's Identity."
        );
        _;
    }

    /* FUNCTIONS */

    /* external */
    function identifyZ3ro(uint256 qty)
        external
        payable
        nonReentrant
        isZ3ro
        isEligibleMint(qty)
    {
        //mint Ownership
        _safeMint(tx.origin, qty);
        emit ownershipMinted(tx.origin, qty);
    }

    function genesisMint(address receiver, uint256 qty) external isZ3ro {
        _safeMint(receiver, qty);
    }

    /* GETTERS AND SETTERS */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function withdrawFunds() external nonReentrant onlyOwner {
        (bool success, ) = payable(multiSig).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    /* Sets the z3ro identity contract */
    function setZ3roIdentity(address identity) external onlyOwner {
        z3roIdentity = identity;
    }

}