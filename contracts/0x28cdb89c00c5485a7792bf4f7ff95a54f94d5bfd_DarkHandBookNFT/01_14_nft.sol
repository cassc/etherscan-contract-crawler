// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

contract DarkHandBookNFT is Ownable, ERC721Pausable {


    /* ============ State Variables ============ */

    // Total Token Supply
    uint256 public totalSupply;

    // Max Token Supply
    uint256 public maxSupply = 137;

    // Whitelist Signer
    address public signer;
    
    // Base URI
    string internal baseURI;


    /* ============ Events ============ */

    // Modify the signer address
    event NewSigner(address oldSigner, address newSigner);

    // Modify the baseURI
    event SetBaseURI(string oldBaseURI, string newBaseURI);


    /* ============ Function ============ */

    /**
     * @dev Initializes the contract
     * @param name Token name
     * @param symbol Token symbol
     * @param newOwner The new owner of the contract
     * @param newSigner The new signer of the contract
     */
    constructor(string memory name, string memory symbol, address newOwner, address newSigner) ERC721(name, symbol){
        _transferOwnership(newOwner);
        _pause();
        signer = newSigner;
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner returns(bool) {
        _pause();
        return true;
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner returns(bool) {
        _unpause();
        return true;
    }

    /**
     * @dev Get the baseURi
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Set the baseURi
     */
    function setBaseURI(string memory newURI) external onlyOwner returns(bool) {
        emit SetBaseURI(baseURI, newURI);
        baseURI = newURI;
        return true;
    }

    /**
     * @dev Modify the signer address
     * @param newSigner New signer address
     */
    function setSigner(address newSigner) external onlyOwner returns(bool) {
        emit NewSigner(signer, newSigner);
        signer = newSigner;
        return true;
    }

    /**
     * @dev Whitelist user mint specifies tokenId
     * @param tokenId Minted tokenId
     * @param signature Signature data for the signer role
     */
    function mint(uint256 tokenId, bytes memory signature) external returns(bool) {
        require(msg.sender == tx.origin, "The caller must be an EOA");
        require(totalSupply + 1 <= maxSupply, "Total token supply cannot exceed 1024");
        bytes32 hash = keccak256(abi.encode("\x19Ethereum Signed Message:\n", msg.sender, tokenId));
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        require(error == ECDSA.RecoverError.NoError && recovered == signer);
        _safeMint(msg.sender, tokenId);
        totalSupply+=1;
        return true;
    }

    /**
     * @dev Override _beforeTokenTransfer
     * 
     * Requirements: 
     *
     * - When the contract is suspended, users cannot perform transfer operation
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (from != address(0)) {
            require(!paused(), "ERC721Pausable: token transfer while paused");
        }
    }

    /**
     * @dev Override approve 
     * 
     * Requirements: 
     *
     * - When the contract is suspended, users cannot perform the approval operation
     */
    function approve(address to, uint256 tokenId) public whenNotPaused override {
        super.approve(to, tokenId);
    }

    /**
     * @dev Override setApprovalForAll
     * 
     * Requirements: 
     *
     * - When the contract is suspended, users cannot perform the approval operation
     */
    function setApprovalForAll(address operator, bool approved) public whenNotPaused override {
        super.setApprovalForAll(operator, approved);
    }
}