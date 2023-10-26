//  _____  __ __  _____  _____  _____  _____  _____ 
// /   __\/  |  \/  ___>/  ___>/   __\/  _  \/  ___>
// |   __||  |  ||___  ||___  ||   __||  _  <|___  |
// \__/   \_____/<_____/<_____/\_____/\__|\_/<_____/
                                                 

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


pragma solidity ^0.8.21;
/**
 * @title A contract for creating a limited supply of ERC721 tokens with a whitelist and public minting functionality.
 * @dev Inherits ERC721A.
 */
contract Fussers is Ownable(msg.sender), ERC721A  {

    address internal withdrawAddress = 0x3674cF2305B045998dD55122231504f527d9D511; // Address where funds will be withdrawn to

    uint256 public maxFreeSupply = 0; // Maximum supply of free tokens
    uint256 public maxSupply = 1888; // Maximum supply of tokens

    bool public isPublicMintEnabled = false; // Flag to enable or disable public minting
    bool public isWLmintEnabled = false; // Flag to enable or disable whitelist minting
    uint256 public freePerWallet = 0; // Number of free tokens per wallet
    uint256 public costPublic = 0.015 ether; // Cost to mint a token for the public
    uint256 public maxMintPublic = 10; // Maximum number of tokens a user can mint
    uint256 public costWL = 0.013 ether; // Cost to mint a token for a whitelisted user
    uint256 public maxMintWL = 10; // Maximum number of tokens a whitelisted user can mint

    string public baseURI = "ipfs://bafybeih3h5ovwd3t5eyshjvwybs2b4dxtuesvjpenhppfiv4o2s3ik7oni/"; // Base URI for token metadata
    bytes32 public whitelistRoot; // Merkle root for the whitelist
    mapping(address => uint256) public mintedByAddressWL; // Mapping to keep track of the number of tokens minted by a whitelisted address
    mapping(address => uint256) public mintedByAddress; // Mapping to keep track of the number of tokens minted by an address

    constructor() ERC721A("Fussers", "FSR") {}

    /**
     * @notice Allows a user to mint tokens.
     * @param _quantity - The number of tokens to mint.
     * @dev User must send the correct amount of ether. Can only be called by a wallet (not a contract). Public minting must be enabled.
     */
    function mint(uint _quantity) external payable {
        uint256 _cost = getCost(msg.sender, _quantity);
        require(tx.origin == msg.sender, "No contracts");
        require(isPublicMintEnabled, "Not yet");
        require(totalSupply() + _quantity <= maxSupply, "Too late");
        require(_quantity <= maxMintPublic, "Too many");
        require(msg.value == _cost, "Ether sent is incorrect");
        mintedByAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Allows a whitelisted user to mint tokens.
     * @param _quantity - The number of tokens to mint.
     * @param _merkleProof - Merkle proof that the user is whitelisted.
     * @dev User must send the correct amount of ether. Can only be called by a wallet (not a contract). Whitelist minting must be enabled. User must be whitelisted.
     */
    function mintWL(uint _quantity, bytes32[] calldata _merkleProof) external payable {
        require(isWLmintEnabled, "Whitelist minting not enabled");
        require(tx.origin == msg.sender, "No contracts");
        require(isWhitelisted(msg.sender, _merkleProof), "Not whitelisted");
        require(totalSupply() + _quantity <= maxSupply, "Too late");
        require(mintedByAddressWL[msg.sender] + _quantity <= maxMintWL, "Too many");
        require(msg.value == costWL * _quantity, "Ether sent is incorrect");

        mintedByAddressWL[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice Defines the starting token ID.
     * @return The starting token ID.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Allows the owner to airdrop tokens to a recipient.
     * @param _quantity - The number of tokens to airdrop.
     * @param _recipient - The address of the recipient.
     * @dev Only the owner can call this function. Cannot mint more tokens than the maximum supply.
     */
    function airdrop(uint256 _quantity, address _recipient) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Too many");
        _mint(_recipient, _quantity);
    }

    /**
     * @notice Allows the owner to mint tokens.
     * @param _quantity - The number of tokens to mint.
     * @dev Only the owner can call this function. Cannot mint more tokens than the maximum supply.
     */
    function devMint(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Too many");
        _mint(msg.sender, _quantity);
    }

    /**
     * @notice Checks if an address can claim a free token.
     * @param _address - The address to check.
     * @return True if the address can claim a free token, false otherwise.
     */
    function canClaim(address _address) public view returns (bool) {
        return mintedByAddress[_address] < freePerWallet && totalSupply() < maxFreeSupply;
    }

    /**
     * @notice Returns the cost to mint a number of tokens for a specific address.
     * @param _address - The address that wants to mint the tokens.
     * @param _count - The number of tokens to mint.
     * @return The cost to mint the tokens.
     */
    function getCost(address _address, uint256 _count) public view returns (uint256) {
        if (canClaim(_address)) {
            uint256 freeCount = freePerWallet - mintedByAddress[_address];
            if (_count <= freeCount) {
                return 0;
            }
            return costPublic * (_count - freeCount);
        }
        return costPublic * _count;
    }

    /**
     * @notice Checks if an address is whitelisted.
     * @param _wallet - The address to check.
     * @param _merkleProof - The Merkle proof that the address is whitelisted.
     * @return True if the address is whitelisted, false otherwise.
     */
    function isWhitelisted(address _wallet, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_wallet));
        return MerkleProof.verify(_merkleProof, whitelistRoot, leaf);
    }

    /**
     * @notice Allows the owner to set the Merkle root for the whitelist.
     * @param _merkleRoot - The new Merkle root for the whitelist.
     * @dev Only the owner can call this function.
     */
    function setWhitelistRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistRoot = _merkleRoot;
    }

   /**
     * @notice Allows the owner to enable or disable whitelist minting.
     * @dev Only the owner can call this function. Public minting must be disabled before enabling whitelist minting.
     */
    function setWLmintEnabled() public onlyOwner {
        require(!isPublicMintEnabled, "Public minting is enabled, disable it first");
        isWLmintEnabled = !isWLmintEnabled;
    }

    /**
     * @notice Allows the owner to enable or disable public minting.
     * @dev Only the owner can call this function. Whitelist minting must be disabled before enabling public minting.
     */
    function setPublicMintEnabled() public onlyOwner {
        require(!isWLmintEnabled, "Whitelist minting is enabled, disable it first");
        isPublicMintEnabled = !isPublicMintEnabled;
    }

    /**
     * @notice Allows the owner to set the base URI.
     * @param _baseURI - The new base URI.
     * @dev Only the owner can call this function.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Allows the owner to set the cost of public minting.
     * @param _newCostPublic - The new cost of public minting.
     * @dev Only the owner can call this function.
     */
    function setCostPublic(uint256 _newCostPublic) public onlyOwner {
        costPublic = _newCostPublic;
    }

    /**
     * @notice Allows the owner to set the cost of whitelist minting.
     * @param _newCostWL - The new cost of whitelist minting.
     * @dev Only the owner can call this function.
     */
    function setCostWL(uint256 _newCostWL) public onlyOwner {
        costWL = _newCostWL;
    }

    /**
     * @notice Allows the owner to set the maximum number of tokens that can be minted publicly at once.
     * @param _newMaxMintPublic - The new maximum number of tokens that can be minted publicly at once.
     * @dev Only the owner can call this function.
     */
    function setMaxMintPublic(uint256 _newMaxMintPublic) public onlyOwner {
        maxMintPublic = _newMaxMintPublic;
    }

    /**
     * @notice Allows the owner to set the maximum number of tokens that can be minted by a whitelisted user at once.
     * @param _newMaxMintWL - The new maximum number of tokens that can be minted by a whitelisted user at once.
     * @dev Only the owner can call this function.
     */
    function setMaxMintWL(uint256 _newMaxMintWL) public onlyOwner {
        maxMintWL = _newMaxMintWL;
    }

    /**
     * @notice Sets the amount of free tokens each wallet can receive
     * @param _newFreePerWallet The new amount of free tokens each wallet can receive
     * @dev Can only be called by the contract owner
     */
    function setFreePerWallet(uint256 _newFreePerWallet) public onlyOwner {
        freePerWallet = _newFreePerWallet;
    }

    /**
     * @notice Sets the maximum supply of free tokens
     * @param _maxFreeSupply The new maximum supply of free tokens
     * @dev Can only be called by the contract owner
     */
    function setMaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
        maxFreeSupply = _maxFreeSupply;
    }

    /**
    * @notice Allows the owner to withdraw all collected funds to withdrawAddress without deducting any fees
    * @dev Can only be called by the contract owner.
    */
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance; 
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = payable(withdrawAddress).call{value: balance}("");
        require(success, "Failed to transfer to withdrawal address");
    }

    /**
     * @notice Returns the token URI for a given token
     * @param _tokenId The ID of the token
     * @return The full URI of the token
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not found");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), ".json"));
    }

    /**
     * @notice Reduces the maximum supply of tokens
     * @param _newMaxSupply The new maximum supply of tokens
     * @dev Can only be called by the contract owner. The new maximum supply must be less than the current maximum supply and greater than or equal to the current supply
     */
    function decreaseMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply < maxSupply, "Supply can only decrease");
        require(_newMaxSupply >= totalSupply(), "Can't be less than current supply");
        maxSupply = _newMaxSupply;
    }

    /**
     * @notice Returns all the tokens owned by a particular address
     * @param _address The address to look up
     * @return An array of token IDs owned by the address
     */
    function tokensOfOwner(address _address) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(_address);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == _address) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }
}