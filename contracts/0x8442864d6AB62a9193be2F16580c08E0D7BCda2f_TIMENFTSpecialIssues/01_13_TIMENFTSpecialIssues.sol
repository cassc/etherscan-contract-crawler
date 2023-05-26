// SPDX-License-Identifier: MIT

/**
*   @title TIME NFT Special Issues
*   @author Transient Labs
*/

/*
  _____ ___ __  __ _____   _   _ _____ _____                    
 |_   _|_ _|  \/  | ____| | \ | |  ___|_   _|                   
   | |  | || |\/| |  _|   |  \| | |_    | |                     
   | |  | || |  | | |___  | |\  |  _|   | |                     
  _|_| |___|_|  |_|_____| |_| \_|_| ___ |_|                     
 / ___| _ __   ___  ___(_) __ _| | |_ _|___ ___ _   _  ___  ___ 
 \___ \| '_ \ / _ \/ __| |/ _` | |  | |/ __/ __| | | |/ _ \/ __|
  ___) | |_) |  __/ (__| | (_| | |  | |\__ \__ \ |_| |  __/\__ \
 |____/| .__/ \___|\___|_|\__,_|_| |___|___/___/\__,_|\___||___/
       |_|                                                      
   ___                            __  __          ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / /  __ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _ \/ // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /_.__/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./EIP2981MultiToken.sol";

contract TIMENFTSpecialIssues is ERC1155, EIP2981MultiToken, Ownable {

    struct TokenDetails {
        bool created;
        bool mintStatus;
        uint64 availableSupply;
        uint256 price;
        string uri;
        bytes32 merkleRoot;
        mapping(address => bool) hasMinted;
    }

    mapping(uint256 => TokenDetails) private _tokenDetails;

    address public adminAddress;
    address payable public payoutAddress;

    string public constant name = "TIME NFT Special Issues";

    modifier isAdminOrOwner {
        require(msg.sender == adminAddress || msg.sender == owner(), "Address not allowed to execute airdrop");
        _;
    }

    constructor(address admin, address payoutAddr) ERC1155("") EIP2981MultiToken() Ownable() {
        adminAddress = admin;
        payoutAddress = payable(payoutAddr);
    }

    /**
    *   @notice function to create a token
    *   @dev requires owner
    *   @param tokenId must be a new token id
    *   @param supply is the total supply of the new token
    *   @param mintStatus is a bool representing initial mint status
    *   @param price is a uint256 representing mint price in wei
    *   @param uri_ is the new token uri
    *   @param merkleRoot is the token merkle root
    *   @param royaltyRecipient is an address that is the royalty recipient for this token
    *   @param royaltyPerc is the percentage for royalties, in basis (out of 10,000)
    */
    function createToken(uint256 tokenId, uint64 supply, bool mintStatus, uint256 price, string memory uri_, bytes32 merkleRoot, address royaltyRecipient, uint256 royaltyPerc) external onlyOwner {
        require(_tokenDetails[tokenId].created == false, "Token ID already exists");
        require(royaltyRecipient != address(0), "Royalty recipient can't be the 0 address");
        require(royaltyPerc < 10000, "Royalty percent can't be more than 10,000");
        _tokenDetails[tokenId].created = true;
        _tokenDetails[tokenId].availableSupply = supply;
        _tokenDetails[tokenId].mintStatus = mintStatus;
        _tokenDetails[tokenId].price = price;
        _tokenDetails[tokenId].uri = uri_;
        _tokenDetails[tokenId].merkleRoot = merkleRoot;
        _royaltyAddr[tokenId] = royaltyRecipient;
        _royaltyPerc[tokenId] = royaltyPerc;
    }

    /**
    *   @notice function to set available supply for a certain token
    *   @dev requires owner of contract
    *   @param tokenId is the token id
    *   @param supply is the new available supply for that token
    */
    function setTokenSupply(uint256 tokenId, uint64 supply) external onlyOwner {
        require(_tokenDetails[tokenId].created, "Token ID not valid");
        _tokenDetails[tokenId].availableSupply = supply;
    }

    /**
    *   @notice sets the URI for individual tokens
    *   @dev requires owner
    *   @dev emits URI event per the ERC 1155 standard
    *   @param newURI is the base URI set for each token
    *   @param tokenId is the token id
    */
    function setURI(uint256 tokenId, string memory newURI) external onlyOwner {
        require(_tokenDetails[tokenId].created, "Token ID not valid");
        _tokenDetails[tokenId].uri = newURI;
        emit URI(newURI, tokenId);
    }

    /**
    *   @notice set token mint status
    *   @dev requires owner
    *   @param tokenId is the token id
    *   @param status is the desired status
    */
    function setMintStatus(uint256 tokenId, bool status) external onlyOwner {
        require(_tokenDetails[tokenId].created, "Token ID not valid");
        _tokenDetails[tokenId].mintStatus = status;
    }

    /**
    *   @notice set token price
    *   @dev requires owner
    *   @param tokenId is the token id
    *   @param price is the new price
    */
    function setTokenPrice(uint256 tokenId, uint256 price) external onlyOwner {
        require(_tokenDetails[tokenId].created, "Token ID not valid");
        _tokenDetails[tokenId].price = price;
    }

    /**
    *   @notice set token merkle root
    *   @dev requires owner
    *   @param tokenId is the token id
    *   @param root is the new merkle root
    */
    function setMerkleRoot(uint256 tokenId, bytes32 root) external onlyOwner {
        require(_tokenDetails[tokenId].created, "Token ID not valid");
        _tokenDetails[tokenId].merkleRoot = root;
    }

    /**
    *   @notice function to set the admin address on the contract
    *   @dev requires owner of the contract
    *   @param newAdmin is the new admin address
    */
    function setNewAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        adminAddress = newAdmin;
    }

    /**
    *   @notice function to set the payout address
    *   @dev requires owner of the contract
    *   @param payoutAddr is the new payout address
    */
    function setPayoutAddress(address payoutAddr) external onlyOwner {
        require(payoutAddr != address(0), "Payout address cannot be the zero address");
        payoutAddress = payable(payoutAddr);
    }

    /**
    *   @notice function to change the royalty recipient
    *   @dev requires owner
    *   @dev this is useful if an account gets compromised or anything like that
    *   @param tokenId is the token id to assign this address to
    *   @param newRecipient is the new royalty recipient
    */
    function setRoyaltyRecipient(uint256 tokenId, address newRecipient) external onlyOwner {
        require(_tokenDetails[tokenId].created, "Token ID not valid");
        require(newRecipient != address(0), "New recipient is the zero address");
        _royaltyAddr[tokenId] = newRecipient;
    }

    /**
    *   @notice function to change the royalty percentage
    *   @dev requires owner
    *   @dev this is useful if the amount was set improperly at contract creation.
    *   @param tokenId is the token id
    *   @param newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function setRoyaltyPercentage(uint256 tokenId, uint256 newPerc) external onlyOwner {
        require(_tokenDetails[tokenId].created, "Token ID not valid");
        require(newPerc < 10000, "New percentage must be less than 10,0000");
        _royaltyPerc[tokenId] = newPerc;
    }

    /**
    *   @notice function for batch minting the token to many addresses
    *   @dev requires owner or admin
    *   @param tokenId is the token id to airdrop
    *   @param addresses is an array of addresses to mint to
    */
    function airdrop(uint256 tokenId, address[] calldata addresses) external isAdminOrOwner {
        require(_tokenDetails[tokenId].created, "Token not created");
        require(_tokenDetails[tokenId].availableSupply >= addresses.length, "Not enough token supply available");

        _tokenDetails[tokenId].availableSupply -= uint64(addresses.length);
        
        for (uint256 i; i < addresses.length; i++) {
            _mint(addresses[i], tokenId, 1, "");
        }
    }

    /**
    *   @notice function for users to mint
    *   @dev requires payment
    *   @param tokenId is the token id to mint
    *   @param merkleProof is the has for merkle proof verification
    */
    function mint(uint256 tokenId, bytes32[] calldata merkleProof) external payable {
        TokenDetails storage token = _tokenDetails[tokenId];
        require(token.availableSupply > 0, "Not enough token supply available");
        require(token.mintStatus == true, "Mint not open");
        require(msg.value >= token.price, "Not enough ether attached to the transaction");
        require(token.hasMinted[msg.sender] == false, "Sender has already minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, token.merkleRoot, leaf), "Not on allowlist");

        token.hasMinted[msg.sender] = true;
        token.availableSupply --;

        _mint(msg.sender, tokenId, 1, "");
    }

    /**
    *   @notice function to withdraw ether from the contract
    *   @dev requires owner
    */
    function withdrawEther() external onlyOwner {
        payoutAddress.transfer(address(this).balance);
    }

    /**
    *   @notice function to return available token supply
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return uint64 representing available supply
    */
    function getTokenSupply(uint256 tokenId) external view returns(uint64) {
        return _tokenDetails[tokenId].availableSupply;
    }

    /**
    *   @notice function to see if an address has minted a certain token
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @param addr is the address to check
    *   @return boolean indicating status
    */
    function getHasMinted(uint256 tokenId, address addr) external view returns (bool) {
        return _tokenDetails[tokenId].hasMinted[addr];
    }

    /**
    *   @notice function to see the mint status for a token
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return boolean indicating mint status
    */
    function getMintStatus(uint256 tokenId) external view returns (bool) {
        return _tokenDetails[tokenId].mintStatus;
    }

    /**
    *   @notice function to see the price for a token
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return uint256 with price in Wei
    */
    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        return _tokenDetails[tokenId].price;
    }

    /**
    *   @notice function to see the merkle root for a token
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return bytes32 with merkle root
    */
    function getMerkleRoot(uint256 tokenId) external view returns (bytes32) {
        return _tokenDetails[tokenId].merkleRoot;
    }

    /**
    *   @notice overrides supportsInterface function
    *   @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, EIP2981MultiToken) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    *   @notice function to return uri for a specific token type
    *   @param tokenId is the uint256 representation of a token ID
    *   @return string representing the uri for the token id
    */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenDetails[tokenId].uri;
    }   
}