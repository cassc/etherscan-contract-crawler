// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Sheepverse is ERC721A, Ownable, ReentrancyGuard {

    struct Reveal {
        uint16 from;
        uint16 to;
        string baseTokenURI;
    }

    /**
     * @dev Will be minted through _mintERC2309 on contract creation 
     * @notice Reserved amount of tokens for giveaways and airdrops
     */
    uint8 constant public RESERVED_FOR_TREASURY = 150;

    /**
     * @notice The max supply of the collection, can be changed as long as locked is false.
     * Will be increased over a period of time before being locked
     */
    uint16 public maxSupply = 200;

    /**
     * @notice The maximum amount of mints per wallet. Will be increased with maxSupply
     */
    uint8 public maxMintsPerWallet = 3;

    /**
     * @notice The maximum amount of free mints per wallet
     */
    uint8 public maxOgMintsPerWallet = 1;

    /**
     * @notice Locks/Unlocks the public sale
     */
    bool public isPublicSale = false;

    /**
     * @notice Locks/Unlocks the whitelist sale
     */
    bool public isWlSale = false;

    /**
     * @notice Current token price, will be increased over time
     */
    uint256 public price;

    /**
     * @notice MerkleTree root for whitelist
     */
    bytes32 public wlMerkleRoot;

    /**
     * @notice MerkleTree root for OG
     */
    bytes32 public ogMerkleRoot;
    
    /**
     * @notice The reveal stages are used to reveal part of the collection
     */
    Reveal[] public revealStages;

    /**
     * @dev If the basteTokenURI is set the revealStages will be ignored (full collection reveal)
     * @notice The reveal stages are used to reveal part of the collection
     */
    string public baseTokenURI;

    /**
     * @notice The unrevealed URI is the default URI that will be returned if no reveal stage
     * matched the tokenID or no baseTokenURI is set.
     */
    string public unrevealedURI;

    /**
     * @notice Locks the contract, if true none of the important fields can be updated
     */
    bool public locked = false;

    modifier onlyWallet() {
        require(tx.origin == msg.sender, "Mint can't be called by another contract");
        _;
    }

    modifier notIfLocked() {
        require(!locked, "Contract is locked");
        _;
    }

    // ================================================== //
    // Constructor                                        //
    // ================================================== //
    
    /**
     * @param name Contract name
     * @param symbol Contract symbol
     * @param treasury Treasury address which will receive the reserved tokens
     * @param _price The initial price of the token
     * @param _unrevealedURI The unrevealedURI
     */
    constructor(
        string memory name,
        string memory symbol,
        address treasury,
        uint256 _price,
        string memory _unrevealedURI
    )
        ERC721A(name, symbol)
    {
        price = _price;
        unrevealedURI = _unrevealedURI;
        _mintERC2309(treasury, RESERVED_FOR_TREASURY);
    }

    // ================================================== //
    // External                                           //
    // ================================================== //

    /**
     * @notice Public Mint
     * @param quantity Amount of tokens to be minted
     */
    function mint(uint256 quantity) external payable onlyWallet {
        require(isPublicSale, 'Public sale not active');
        require(quantity > 0, 'Mint at least 1');
        require(totalSupply() + quantity <= maxSupply, 'Amount of tokens requested exceeds max supply');
        require(_numberMinted(msg.sender) + quantity <= maxMintsPerWallet, "Amount of tokens exceeds allowed mints per wallet");
        require(msg.value >= price * quantity, 'Not enough ether provided');

        _mint(msg.sender, quantity);
    }

    /**
     * @notice Whitelist Mint
     * @param quantity Amount of tokens to be minted
     * @param merkleProof Merkle Proof for either WL or OG wallet
     */
    function wlMint(
        uint256 quantity,
        bytes32[] calldata merkleProof
    )
        external payable onlyWallet
    {
        (bool isOg, bool isWl) = validate(msg.sender, merkleProof);

        require(isWlSale, 'Whitelist sale not active');
        require(quantity > 0, 'Mint at least 1');
        require(isOg || isWl, 'Not on the Whitelist');
        require(totalSupply() + quantity <= maxSupply, 'Amount of tokens requested exceeds max supply');
        require(_numberMinted(msg.sender) + quantity <= maxMintsPerWallet, "Amount of tokens exceeds allowed mints per wallet");

        uint64 ogUsed = _getAux(msg.sender);

        // Check if sender has free mint available
        uint64 deduct = 0;
        if (isOg && ogUsed < maxOgMintsPerWallet) {
            deduct = maxOgMintsPerWallet - ogUsed;
            if (deduct > quantity) {
                deduct = uint64(quantity);
            }

            _setAux(msg.sender, ogUsed + deduct);
        }

        require(msg.value >= (price * (quantity - deduct)), 'Not enough ether provided');

        _mint(msg.sender, quantity);
    }

    /**
     * @notice Updates the mint conditions
     * @param _maxSupply The new maxSupply
     * @param _maxMintsPerWallet The new max amount of mints per wallet
     * @param _maxOgMintsPerWallet The new max amount of free mints per wallet
     * @param _price The new price for a token
     */
    function updateMint(
        uint16 _maxSupply,
        uint8 _maxMintsPerWallet,
        uint8 _maxOgMintsPerWallet,
        uint256 _price
    )
        external onlyOwner notIfLocked
    {
        maxSupply = _maxSupply;
        maxMintsPerWallet = _maxMintsPerWallet;
        maxOgMintsPerWallet = _maxOgMintsPerWallet;
        price = _price;
    }

    /**
     * @notice Set the new WL Merkle Tree root
     * @param merkleRoot The new Merkle Tree root for the WL
     */
    function setWlMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        wlMerkleRoot = merkleRoot;
    }

    /**
     * @notice Set the new OG Merkle Tree root
     * @param merkleRoot The new Merkle Tree root for OG
     */
    function setOgMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        ogMerkleRoot = merkleRoot;
    }

    /**
     * @notice Adds a new reveal stage to partially reveal the collection
     * @param from The first tokenID that should use the _baseTokenURI
     * @param to The last tokenID that should use the _baseTokenURI
     * @param _baseTokenURI The baseTokenURI to be used for tokenID from - to
     */
    function addRevealStage(uint16 from, uint16 to, string memory _baseTokenURI) external onlyOwner {
        revealStages.push(Reveal({
            from: from,
            to: to,
            baseTokenURI: _baseTokenURI
        }));
    }

    /**
     * @notice Deletes the last added mintStage in case something went wrong
     */
    function deleteRevealStage() external onlyOwner {
        revealStages.pop();
    }

    /**
     * @notice Sets the baseTokenURI, will be used for all tokens when set
     */
    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner notIfLocked {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @notice Toggle public sale on/off
     */
    function setIsPublicSale(bool _isPublicSale) external onlyOwner {
        isPublicSale = _isPublicSale;
    }

    /**
     * @notice Toggle WL public sale on/off
     */
    function setIsWlSale(bool _isWlSale) external onlyOwner {
        isWlSale = _isWlSale;
    }

    /**
     * @notice Lock the Contract
     */
    function lockContract() external onlyOwner {
        require(bytes(baseTokenURI).length != 0, 'baseTokenURI has to be set');
        locked = true;
    }

    /**
     * @notice Helper function to check how many mints a certain address has left
     * @param owner The address to be checked
     * @return ogMintsLeft The amount of og mints that are left
     * @return regularMintsLeft The amount of "regular" mints that are left
     */
    function mintsLeft(address owner) external view returns (uint256 ogMintsLeft, uint256 regularMintsLeft) {
        return (
            uint64(maxOgMintsPerWallet) - _getAux(owner),
            maxMintsPerWallet - _numberMinted(owner)
        );
    }

    /**
     * @notice Helper function to get all reveal stages
     * @return Reveal[]
     */
    function getRevealStages() external view returns (Reveal[] memory) {
        return revealStages;
    }

    /**
     * @notice Withdraw contract funds to caller wallet
     */
    function withdraw(address receiver) external onlyOwner nonReentrant {
        (bool success, ) = receiver.call{ value: address(this).balance }('');
        require(success, 'Transfer failed.');
    }

    // ================================================== //
    // Public                                             //
    // ================================================== //

    /**
     * @notice Returns the tokenURI.
     * @dev If baseTokenURI is set that value should be returned, if not it will search for
     * a revealStage and return the baseTokenURI in that struct. If nothing can be found
     * if will return unrevealURI.
     * @return The baseTokenURI/tokenId or the unrevealedURI
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        // Return final baseTokenURI if set
        if (bytes(baseTokenURI).length != 0) {
            return string(abi.encodePacked(baseTokenURI, _toString(tokenId)));
        }

        // Find baseTokenURI for tokenID
        string memory stageBaseTokenURI = getStageBaseTokenURI(tokenId);

        // If baseTokenURI was found, return it, else leave unrevealed
        if (bytes(stageBaseTokenURI).length != 0) {
            return string(abi.encodePacked(stageBaseTokenURI, _toString(tokenId)));
        }

        return unrevealedURI;
    }

    /**
     * @param owner The owner address to be validated
     * @param merkleProof The merkle proof to be validated
     * @return isOg bool, isWl bool
     */
    function validate(
        address owner,
        bytes32[] calldata merkleProof
    )
        public view returns (bool isOg, bool isWl)
    {
        bytes32 leaf = keccak256(abi.encodePacked(owner));
        return (
            MerkleProof.verify(merkleProof, ogMerkleRoot, leaf),
            MerkleProof.verify(merkleProof, wlMerkleRoot, leaf)
        );
    }

    // ================================================== //
    // Private                                            //
    // ================================================== //

    /**
     * @notice Finds the stage for tokenId and returns the baseTokenURI or an empty string if not found
     * @param tokenId The tokenId to find the stage
     * @return stageBaseTokenURI string
     */
    function getStageBaseTokenURI(uint256 tokenId) private view returns (string memory stageBaseTokenURI) {
        for (uint256 i = 0; i < revealStages.length; i++) {
            if (tokenId >= revealStages[i].from && tokenId <= revealStages[i].to) {
                return revealStages[i].baseTokenURI;
            }
        }

        return '';
    }

}