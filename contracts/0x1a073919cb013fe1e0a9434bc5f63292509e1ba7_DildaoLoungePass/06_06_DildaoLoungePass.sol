// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "node_modules/erc721a/contracts/ERC721A.sol";
import "lib/solmate/src/auth/Owned.sol";
import "lib/solmate/src/utils/ReentrancyGuard.sol";
import "lib/solmate/src/utils/MerkleProofLib.sol";

/// @title Dildao Lounge Pass
/// @author SKU @iamsku_ & Gooltoe @gooltoe
contract DildaoLoungePass is ERC721A, Owned, ReentrancyGuard {
    string public baseURI;

    uint256 public mintPrice;
    uint256 public maxSupply;

    bool public claimActive;
    bool public transfersLocked;
    bool public freeClaim;

    bytes32 public merkleRoot;

    mapping (address => bool) public claimedPass;

    modifier StockCount(uint256 _amount) {
        require(totalSupply() + _amount <= maxSupply, "Sorry Sold Out!");
        _;
    }

    constructor(bytes32 _root, uint256 _supply, uint256 _mintprice) ERC721A("DILDAO Lounge Pass", "DLP") Owned(msg.sender) {
        merkleRoot = _root;
        maxSupply = _supply;
        mintPrice = _mintprice;
        freeClaim = true;
        transfersLocked = true;
    }

    function claimLoungePass(address _sendTo, bytes32[] calldata _proof) external payable nonReentrant StockCount(1) {
        // If ever we decide to set a mint price it will require the caller to pay.
        if (!freeClaim) require(msg.value == mintPrice, "Please send the exact amount of ether in order to mint a lounge pass.");

        // Ensures Wallets can only claim one pass.
        require(!claimedPass[msg.sender], "You have already claimed your pass.");
        
        // If the claim has not commeced, revert.
        require(claimActive, "Claim has not started or has been closed.");
        
        // Ensures this function can not be called by another contract.
        require(tx.origin == msg.sender);
        
        // If the users proof is invalid, revert.
        require(MerkleProofLib.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid Proof");

        // Initate the mint after checks.
        _mint(_sendTo, 1);

        // Logging of the user that has successfully claimed the pass. 
        claimedPass[msg.sender] = true;
    }

    function burnPass(uint256[] calldata _tokenIds) external onlyOwner {
        // List at 69 E or get smoked. 
        for (uint256 i; i < _tokenIds.length;) {
            uint256 tokenId = _tokenIds[i];
            _burn(tokenId);
            unchecked {
                ++i;
            }
        }
    }

    function printLoungePass(uint256 _amount, address _sendTo) external onlyOwner StockCount(_amount) {
        // Allows us to print Lounge Passes for marketing, partnerships/collabs as long as the supply is respected.
        _mint(_sendTo, _amount);
    }
 
    function lockTransfers() external onlyOwner {
        // Locks or unlocks transfers of all passes. 
        transfersLocked = !transfersLocked;
    }

    function toggleClaim() external onlyOwner {
        // Opens or closes the claim for passes.
        claimActive = !claimActive;
    }

    function toggleFreeClaim() external onlyOwner {
        // Lets users claim their passes for free if on, if off it will require users to pay.
        freeClaim = !freeClaim;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        // Sets the new supply of passes.
        maxSupply = _maxSupply;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        // Updates the merkle root incase of adding or removing from allowlist. 
        merkleRoot = _root;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        // Updates the URI incase of art changes or needs to change metadata.
        baseURI = _newURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        // Allows Owner to withdraw funds if funds are ever raised.
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        // Override the URI.
        return baseURI;
    }
 
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {

        // If a transfer is initiated from the owner of the contract or null for mints it will allow the transfer to happen even if locked.
        if (from == owner || from == address(0) || to == address(0)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);   
        }
        else {
            // We check to see if transfers are locked if caller is not operator or null address or being burnt.
            require(!transfersLocked, "Transfers are currently locked.");

            // If transfers are not locked it will proceed with the transfer if caller is not operator or null address.
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        // Start first tokenID at 1 instead of 0
        return 1;
    }
}