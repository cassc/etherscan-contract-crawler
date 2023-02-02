// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract VCAFixedPrice is ERC721A, AccessControl, DefaultOperatorFilterer {
    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // This is the existing token Id
    uint256 public currentTokenId = 1;

    // By default, allow minting
    bool public allowMint = true;

    // This is the contract URI - link to IPFS
    string public contractinfo = "";

    // Info about each drop we support
    struct Drop {
        address curator;
        address artist;
        string tokenURI; /* IPFS hash */
        uint256 curationFee; /** If 10%, use 100, 15.5% use 155 */
        uint256 price; /* This is in Wei **/
        uint256 supply; /* This is the initial supply **/
        uint256 balance; /* This is the balance */
    }

    // Tracks Drop ID each token ID is linked to
    mapping(uint256 => uint256) public tokenIdDrop; 

    // Tracks Drop ID
    mapping(uint256 => Drop) public dropDetails;

    // Custom errors
    error Soldout();
    error InsufficientEth();
    error Unauthorized();
    error DropError(); // Represents error with drop called
    error MintingPaused();

    // `dropId` takes in a number (identifier) that represents the NFT drop to mint.
    //  Each drop has pre-defined details stored. 

    function mint(uint256 dropId) external payable {
        
        uint256 _balance = dropDetails[dropId].balance;
        uint256 _curationFee = (dropDetails[dropId].curationFee*msg.value)/1000;

        // Check mint is allowed
        if (allowMint == false) {
            revert MintingPaused();
        }

        // If drop does not exist
        if (dropDetails[dropId].curator == address(0x0)) {
            revert DropError();
        }

        if (_balance == 0) {
            revert Soldout();
        }

        if (msg.value != dropDetails[dropId].price) {
            revert InsufficientEth();
        }

        // Blocks smart contracts 
        if (_msgSender() != tx.origin) {
            revert Unauthorized();
        }

        tokenIdDrop[currentTokenId] = dropId;
        dropDetails[dropId].balance--;

        // Transfers eth to Curator & Artist
        payable(dropDetails[dropId].curator).transfer(_curationFee);
        payable(dropDetails[dropId].artist).transfer(msg.value-_curationFee);

        // Deducts balance from drop and increment token Id
        unchecked {
            currentTokenId++;
        }

        _safeMint(_msgSender(), 1);
    }

    // This function returns the Token URI based on the Drop it is associated with
    // (ipfs://xxxx)
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return dropDetails[tokenIdDrop[tokenId]].tokenURI;
    }

    // This function returns the contract URI that stores royalties and info to be displayed
    // in marketplaces 
    function contractURI() external view returns (string memory) {
        return contractinfo;
    }


    // Start tokenId from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Admin functions
    function addDrop(uint256 dropId, address curator, address artist, string calldata uri, uint256 curationFee, uint256 price, uint256 supply, uint256 balance) 
        external onlyRole(DEFAULT_ADMIN_ROLE) {
        
        // Check if existing drop exist. There would be no overwrites.
        if (dropDetails[dropId].curator != address(0x0)) {
            revert DropError();
        }
        
        dropDetails[dropId] = Drop(curator, artist, uri, curationFee, price, supply, balance);
    }

    function setTokenURI(uint256 dropId, string calldata uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dropDetails[dropId].tokenURI = uri;
    }

    function setContractURI(string calldata uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractinfo = uri;
    }

    // Allows pausing / unpausing of mint
    function toggleMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowMint = !allowMint;
    }

    function getMintFlag() external view returns(bool) {
        return allowMint;
    }

    // Safety function - Withdraws all the Eth in the contract
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Function overrides due to Operator Filter Registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) payable {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) payable 
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    
    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}