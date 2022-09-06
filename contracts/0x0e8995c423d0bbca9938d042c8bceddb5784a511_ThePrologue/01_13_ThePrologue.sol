// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155Guardable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/** ******************************************************************************************************
** __________.__                 __     ________   _____    ___ ___                                     **
** \______   \  |   ____   ____ |  | __ \_____  \_/ ____\  /   |   \  __________________  ___________   **
** |    |  _/  |  /  _ \_/ ___\|  |/ /  /   |   \   __\  /    ~    \/  _ \_  __ \_  __ \/  _ \_  __ \   **
** |    |   \  |_(  <_> )  \___|    <  /    |    \  |    \    Y    (  <_> )  | \/|  | \(  <_> )  | \/   **
** |______  /____/\____/ \___  >__|_ \ \_______  /__|     \___|_  / \____/|__|   |__|   \____/|__|      **
** \/                 \/     \/         \/               \/                                             **
** @dev by quit                                                                                         **
*********************************************************************************************************/ 

contract ThePrologue is ERC1155Guardable, Ownable {

    string public constant name = "Block of Horror: The Prologue";
    string public constant symbol = "BOHP";

    uint256 constant MAX_SUPPLY = 750;
    uint256 CURRENT_SUPPLY;
    uint256 public maxPerWallet;
    bytes32 private merkleRoot;

    constructor() ERC1155("BOH") {
        maxPerWallet = 1;
    }

    error ExceedMaxSupply();
    error AlreadyClaimed();
    error InvalidProof(bytes32[] proof);

    mapping(address => uint256) public bloodlistClaimed;

    function mintTo(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function mintBloodlist(bytes32[] calldata _proof) public {
        if (bloodlistClaimed[_msgSender()] >= maxPerWallet) {
            revert AlreadyClaimed();
        }

        bytes32 leaf = keccak256((abi.encodePacked(_msgSender())));

        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
            revert InvalidProof(_proof);
        }

        unchecked {
            bloodlistClaimed[_msgSender()]++;
        }

        _mint(_msgSender(), 1);
    }

    function mintAndLock(bytes32[] calldata _proof, address guardian)
        external
    {
        lockApprovals(guardian);
        mintBloodlist(_proof);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setPostWhitelistMax() external onlyOwner {
        maxPerWallet = 2;
    }

    function _mint(address to, uint256 amount) internal {
        unchecked {
            CURRENT_SUPPLY += amount;
        }

        if (CURRENT_SUPPLY > MAX_SUPPLY) {
            revert ExceedMaxSupply();
        }

        super._mint(to, 0, amount, "0x");
    }

    function currentSupply() public view returns (uint256) {
        return CURRENT_SUPPLY;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
}