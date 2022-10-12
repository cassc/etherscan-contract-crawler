// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//
// __________                  __________                   .___
// \______   \_______   ____   \______   \_______  ____   __| _/
//  |     ___/\_  __ \_/ __ \   |     ___/\_  __ \/  _ \ / __ | 
//  |    |     |  | \/\  ___/   |    |     |  | \(  <_> ) /_/ | 
//  |____|     |__|    \___  >  |____|     |__|   \____/\____ | 
//                        \/                                \/ 
//

/**
 * @title MPP01A Contract
 * @notice This contract handles minting and distribution of tokens.
 */
contract MPP01A is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 constant MAX_MINTS = 1;
    uint256 constant MAX_SUPPLY = 12;
    uint256 constant MINT_RATE = 0 ether;

    bool public isPaused = true;
    bool public isPublicMint = false;
    
    string public baseURI = "";
    string public baseExtension = ".json";

    address constant WITHDRAW_ADDRESS = 0x0c7d0B28AbfEA8273c7B12A6e1FD466dc4D2A825;

    bytes32 public root;
 
    /**
     * @notice Construct a contract instance.
     */
    constructor(string memory _uri, bytes32 _merkleRoot)
        ERC721A("MPP01A", "MP01A")
        ReentrancyGuard()
    {
        setBaseURI(_uri);
        root = _merkleRoot;
    }

    /**
     * @notice Read the base token URI. (Override)
     */
    function _baseURI() override internal view virtual returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Set start token id from 0 to 1. (Override)
     */
    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @notice Take a token ID as its only argument and returns a URI which points to metadata about that specific token. (Override)
    **/
    function tokenURI(uint256 _tokenId) override public view virtual returns (string memory) {        
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory currentBaseURI = _baseURI();
        
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
            : "";
    }

    /**
     * @notice Whitelist Minting. Allow an address on the allow list to mint a single token. Allow to mint one token per address.
     */
    function whitelistMint(bytes32[] calldata _proof) external payable isValidMerkleProof(_proof) nonReentrant onlyAccounts {
        require(!isPaused, "Cannot mint. Please try it later.");

        uint256 quantity = MAX_MINTS;
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "1 Mint per Wallet, DON'T be greedy.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Minting ended. All sold out.");
        require(msg.value >= (MINT_RATE * quantity), "Not enough Ethers sent.");

        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Public Minting. Allow an address to mint a single token. Allow to mint one token per address.
     */
    function publicMint() external payable nonReentrant onlyAccounts {
        require(!isPaused, "Cannot mint. Please try it later.");
        require(isPublicMint, "Public minting is not yet started");
        
        uint256 quantity = MAX_MINTS;
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "1 Mint per Wallet, DON'T be greedy.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Minting ended. All sold out.");
        require(msg.value >= (MINT_RATE * quantity), "Not enough Ethers sent.");

        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Allow withdrawing funds to the Withdraw Address.
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is zero. Nothing to withdraw.");
        require(payable(WITHDRAW_ADDRESS).send(balance));
    }

    /**
     * @notice Update the base token URI.
     */
    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    /**
     * @notice Modifier: onlyAccounts.
     */
    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin.");
        _;
    }

    /**
     * @notice Modifier: Check merkle proof is valid or not.
     */
    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender))) == true, "Not allowed address for minting.");
        _;
    }
    
    /**
     * @notice Set merkle root for whitelist.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        root = _merkleRoot;
    }

    /**
     * @notice Toggle the contract pause or unpause.
     */
    function togglePause() public onlyOwner {
        isPaused = !isPaused;
    }

    /**
     * @notice Toggle the public sale enable or disable.
     */
    function togglePublicSale() public onlyOwner {
        isPublicMint = !isPublicMint;
    }

}