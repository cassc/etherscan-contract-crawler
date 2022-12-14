// SPDX-License-Identifier: MIT

/**
*   @title ERC-1155 TL Core
*   @notice ERC-1155 contract with owner/admin roles, merkle claim, airdrops, and owner mint functionality
*   @author transientlabs.xyz
*/

/*
   ___       _ __   __  ___  _ ______                 __ 
  / _ )__ __(_) /__/ / / _ \(_) _/ _/__ _______ ___  / /_
 / _  / // / / / _  / / // / / _/ _/ -_) __/ -_) _ \/ __/
/____/\_,_/_/_/\_,_/ /____/_/_//_/ \__/_/  \__/_//_/\__/                                                          
 ______                  _          __    __        __     
/_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/ 
*/

pragma solidity 0.8.14;

import "ERC1155.sol";
import "IERC20.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";
import "EIP2981MultiToken.sol";

contract ERC1155TLCore is ERC1155, EIP2981MultiToken, Ownable, ReentrancyGuard {

    struct TokenDetails {
        bool created;
        bool mintStatus;
        bool frozen;
        uint64 availableSupply;
        uint16 mintAllowance;
        uint256 price;
        string uri;
        bytes32 merkleRoot;
        mapping(address => uint16) numMinted;
    }

    mapping(uint256 => TokenDetails) internal _tokenDetails;

    address public adminAddress;
    address payable public payoutAddress;

    string public name;

    modifier adminOrOwner {
        require(msg.sender == adminAddress || msg.sender == owner(), "ERC1155TLCore: Address not admin or owner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == adminAddress, "ERC1155TLCore: Address not admin");
        _;
    }

    /**
    *   @param admin is the admin address
    *   @param payout is the payout address
    *   @param contractName is the name of the contract
    */
    constructor(address admin, address payout, string memory contractName)
        ERC1155("")
        Ownable() 
        ReentrancyGuard()
    {
        adminAddress = admin;
        payoutAddress = payable(payout);
        name = contractName;
    }

    /**
    *   @notice function to create a token
    *   @dev requires owner or admin
    *   @param tokenId must be a new token id
    *   @param supply is the total supply of the new token
    *   @param mintStatus is a bool representing initial mint status
    *   @param mintAllowance is a uint16 representing the number someone is able to mint
    *   @param price is a uint256 representing mint price in wei
    *   @param uri_ is the new token uri
    *   @param merkleRoot is the token merkle root
    *   @param royaltyRecipient is an address that is the royalty recipient for this token
    *   @param royaltyPerc is the percentage for royalties, in basis (out of 10,000)
    */
    function createToken(
        uint256 tokenId,
        uint64 supply,
        bool mintStatus,
        uint16 mintAllowance,
        uint256 price,
        string memory uri_,
        bytes32 merkleRoot,
        address royaltyRecipient,
        uint256 royaltyPerc
    )
        external
        virtual
        adminOrOwner 
    {
        require(_tokenDetails[tokenId].created == false, "ERC1155TLCore: Token ID already exists");
        _tokenDetails[tokenId].created = true;
        _tokenDetails[tokenId].availableSupply = supply;
        _tokenDetails[tokenId].mintAllowance = mintAllowance;
        _tokenDetails[tokenId].mintStatus = mintStatus;
        _tokenDetails[tokenId].price = price;
        _tokenDetails[tokenId].uri = uri_;
        _tokenDetails[tokenId].merkleRoot = merkleRoot;
        _setRoyaltyInfo(tokenId, royaltyRecipient, royaltyPerc);
    }

    /**
    *   @notice function to set mint allowance for a token
    *   @dev requires admin or owner
    *   @param tokenId is the token id
    *   @param allowance is the new available mint allowance for that token
    */
    function setMintAllowance(uint256 tokenId, uint16 allowance) external virtual adminOrOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        _tokenDetails[tokenId].mintAllowance = allowance;
    }

    /**
    *   @notice freezes the metadata for the token
    *   @dev requires admin or owner
    *   @param tokenId is the token id
    */
    function freezeToken(uint256 tokenId) external virtual adminOrOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        _tokenDetails[tokenId].frozen = true;
    }

    /**
    *   @notice sets the URI for individual tokens
    *   @dev requires admin or owner
    *   @dev emits URI event per the ERC 1155 standard
    *   @param newURI is the base URI set for each token
    *   @param tokenId is the token id
    */
    function setURI(uint256 tokenId, string memory newURI) external virtual adminOrOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        require(!_tokenDetails[tokenId].frozen, "ERC1155TLCore: Token metadata frozen");
        _tokenDetails[tokenId].uri = newURI;
        emit URI(newURI, tokenId);
    }

    /**
    *   @notice set token mint status
    *   @dev requires admin or owner
    *   @param tokenId is the token id
    *   @param status is the desired status
    */
    function setMintStatus(uint256 tokenId, bool status) external virtual adminOrOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        _tokenDetails[tokenId].mintStatus = status;
    }

    /**
    *   @notice function to change the royalty recipient
    *   @dev requires owner
    *   @dev this is useful if an account gets compromised or anything like that
    *   @param tokenId is the token id to assign this address to
    *   @param newRecipient is the new royalty recipient
    */
    function setRoyaltyRecipient(uint256 tokenId, address newRecipient) external virtual onlyOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        _setRoyaltyInfo(tokenId, newRecipient, _royaltyPerc[tokenId]);
    }

    /**
    *   @notice function to change the royalty percentage
    *   @dev requires owner
    *   @dev this is useful if the amount was set improperly at contract creation.
    *   @param tokenId is the token id
    *   @param newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function setRoyaltyPercentage(uint256 tokenId, uint256 newPerc) external virtual onlyOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        _setRoyaltyInfo(tokenId, _royaltyAddr[tokenId], newPerc);
    }

    /**
    *   @notice function for batch minting the token to many addresses
    *   @dev requires owner or admin
    *   @dev airdrop not subject to mint allowance constraints
    *   @param tokenId is the token id to airdrop
    *   @param addresses is an array of addresses to mint to
    */
    function airdrop(uint256 tokenId, address[] calldata addresses) external virtual adminOrOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        require(_tokenDetails[tokenId].availableSupply >= addresses.length, "ERC1155TLCore: Not enough token supply available");

        _tokenDetails[tokenId].availableSupply -= uint64(addresses.length);
        
        for (uint256 i; i < addresses.length; i++) {
            _mint(addresses[i], tokenId, 1, "");
        }
    }

    /**
    *   @notice function for minting to the owner's address
    *   @dev requires owner or admin
    *   @dev not subject to mint allowance constraints
    *   @param tokenId is the token id to airdrop
    *   @param numToMint is the number to mint
    */
    function ownerMint(uint256 tokenId, uint256 numToMint) external virtual adminOrOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        require(_tokenDetails[tokenId].availableSupply >= numToMint, "ERC1155TLCore: Not enough token supply available");

        _tokenDetails[tokenId].availableSupply -= uint64(numToMint);
        
        _mint(owner(), tokenId, numToMint, "");
    }

    /**
    *   @notice function to withdraw ERC20 tokens from the contract
    *   @dev requires admin or owner
    *   @dev requires payout address to be abel to receive ERC20 tokens
    *   @param tokenAddress is the ERC20 contract address
    *   @param amount is the amount to withdraw
    */
    function withdrawERC20(address tokenAddress, uint256 amount) external virtual adminOrOwner {
        IERC20 erc20 = IERC20(tokenAddress);
        require(amount <= erc20.balanceOf(address(this)), "ERC721ATLCore: cannot withdraw more than balance");
        require(erc20.transfer(payoutAddress, amount));
    }

    /**
    *   @notice function to withdraw ether from the contract
    *   @dev requires admin or owner
    *   @dev recipient MUST be an EOA or contract that does not require more than 2300 gas
    *   @param amount is the amount to withdraw
    */
    function withdrawEther(uint256 amount) external virtual adminOrOwner {
        require(amount <= address(this).balance, "ERC721ATLCore: cannot withdraw more than balance");
        payoutAddress.transfer(amount);
    }

    /**
    *   @notice function to renounce admin rights
    *   @dev requires admin only
    */
    function renounceAdmin() external virtual onlyAdmin {
        adminAddress = address(0);
    }

    /**
    *   @notice function to set the admin address on the contract
    *   @dev requires owner
    *   @param newAdmin is the new admin address
    */
    function setAdminAddress(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "ERC1155TLCore: New admin cannot be the zero address");
        adminAddress = newAdmin;
    }

    /**
    *   @notice function to set the payout address
    *   @dev requires owner
    *   @param payoutAddr is the new payout address
    */
    function setPayoutAddress(address payoutAddr) external virtual onlyOwner {
        require(payoutAddr != address(0), "ERC1155TLCore: Payout address cannot be the zero address");
        payoutAddress = payable(payoutAddr);
    }

    /**
    *   @notice function for users to mint
    *   @dev requires payment
    *   @param tokenId is the token id to mint
    *   @param numToMint is the amount to mint
    *   @param merkleProof is the has for merkle proof verification
    */
    function mint(uint256 tokenId, uint16 numToMint, bytes32[] calldata merkleProof) external virtual payable nonReentrant {
        TokenDetails storage token = _tokenDetails[tokenId];
        require(token.created, "ERC1155TLCore: Token ID not valid");
        require(token.availableSupply >= numToMint, "ERC1155TLCore: Not enough token supply available");
        require(token.mintStatus == true, "ERC1155TLCore: Mint not open");
        require(msg.value >= token.price*uint256(numToMint), "ERC1155TLCore: Not enough ether attached to the transaction");
        require(token.numMinted[msg.sender] + numToMint <= token.mintAllowance, "ERC1155TLCore: Cannot mint more than allowed");
        if (token.merkleRoot != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, token.merkleRoot, leaf), "ERC1155TLCore: Not on allowlist");
        }

        token.numMinted[msg.sender] += numToMint;
        token.availableSupply -= uint64(numToMint);

        _mint(msg.sender, tokenId, uint256(numToMint), "");
    }

    /**
    *   @notice function to return available token supply
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return uint64 representing available supply
    */
    function getTokenSupply(uint256 tokenId) external view virtual returns(uint64) {
        return _tokenDetails[tokenId].availableSupply;
    }

    /**
    *   @notice function to return mint allowance for a token
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return uint16 representing mint allowance
    */
    function getMintAllowance(uint256 tokenId) external view virtual returns(uint16) {
        return _tokenDetails[tokenId].mintAllowance;
    }

    /**
    *   @notice function to see how many tokens and address has minted
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @param addr is the address to check
    *   @return uint16 indicating number minted
    */
    function getNumMinted(uint256 tokenId, address addr) external view virtual returns (uint16) {
        return _tokenDetails[tokenId].numMinted[addr];
    }

    /**
    *   @notice function to see the mint status for a token
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return boolean indicating mint status
    */
    function getMintStatus(uint256 tokenId) external view virtual returns (bool) {
        return _tokenDetails[tokenId].mintStatus;
    }

    /**
    *   @notice function to see the price for a token
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return uint256 with price in Wei
    */
    function getTokenPrice(uint256 tokenId) external view virtual returns (uint256) {
        return _tokenDetails[tokenId].price;
    }

    /**
    *   @notice function to see the merkle root for a token
    *   @dev does not throw for non-existent tokens
    *   @param tokenId is the token id
    *   @return bytes32 with merkle root
    */
    function getMerkleRoot(uint256 tokenId) external view virtual returns (bytes32) {
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