// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GFTShoppe is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // The total tokens minted to an address. Does not matter if tokens are transferred out.
    mapping(address => uint256) public addressMintCount;

    // The addresses allowed to mint in the pre-sale along with how many tokens they are allowed to mint.
    mapping (address => uint256) public whitelist;

    // The redeemed status (true or false) for each token
    mapping (uint256 => bool) public redeemedStatus;

    address private _redeemingContract; // The address of the contract which will be able to set redeemed status. Initial state will be zero.

    string public constant PROVENANCE = "351ec019eac55af38f073eab488f50b4"; // MD5-hashed IPFS hash for provenance

    string public baseTokenURI; // Can be combined with the tokenId to create the metadata URI
    uint256 public maxMintCount = 12; // The maximum number of tokens an address can mint (excluding whitelist mints)
    bool public publicSaleActive = false; // Non-admin users can only mint new tokens when this flag is set to true
    bool public whitelistSaleActive = false; // If set to true, whitelisted users will be allowed to mint
    uint256 public constant MINT_PRICE = 0.1 ether; // Public mint price
    uint256 public constant WHITELIST_MINT_PRICE = 0.09 ether; // Mint price for whitelisted addresses only
    uint256 public constant MAX_TOTAL_SUPPLY = 10000; // The maximum total supply of tokens

    uint256 private constant MAX_TOKEN_ITERATIONS = 40; // Used to prevent out-of-gas errors when looping
    string private redeemedBaseTokenURI; // The metadata base URI for redeemed tokens. Will initially be zero-length.

    event SetBaseURI(address _from);
    event SetRedeemedBaseURI(address _from);
    event Withdraw(address _from, address _to, uint amount);
    event SetMaxMintCount(address _from, uint256 count);
    event TogglePublicSale(address _from, bool isActive);
    event ToggleWhitelistSale(address _from, bool isActive);

    constructor(string memory _baseUri) ERC721("GFT Atari 50th Anniversary", "GFT_Atari") {
        baseTokenURI = _baseUri;
    }

    // Overrides the tokenURI function so that an alternative redeemed base URI can be returned
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {

        string memory baseURI = baseTokenURI;
        if (redeemedStatus[_tokenId]) {
            baseURI = redeemedBaseTokenURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    } 

    // Allows the contract owner to set a new base URI string
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
        emit SetBaseURI(msg.sender);
    }

    // Allows the contract owner to set a new base URI string for redeemed tokens
    function setRedeemedBaseURI(string calldata redeemedURI) external onlyOwner {
        redeemedBaseTokenURI = redeemedURI;
        emit SetRedeemedBaseURI(msg.sender);
    }

    // Adds a number of addresses to the whitelist along with the number of tokens each address is allowed to mint
    function addToWhitelist(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        require(addresses.length <= 100, "Please only add up to 100 addresses at a time"); // Check to prevent OOG errors
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = numAllowedToMint;
        }
    }

    // Public mint function
    function createItem(uint256 amount) external payable {
        uint256 supply = totalSupply();
        uint256 mintCount = addressMintCount[msg.sender];
        require(publicSaleActive, "Public sale is not yet active");
        require(amount > 0, "Mint amount can't be zero");
        require(supply + amount <= MAX_TOTAL_SUPPLY, "Max mint amount is reached");
        require(
            mintCount + amount <= maxMintCount,
            "Exceed the Max Amount to mint."
        );
        require(amount * MINT_PRICE == msg.value, "Price must be 0.1 eth for each NFT");
			
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender , supply + i);
        }
        addressMintCount[msg.sender] = mintCount + amount;
    }

    // Only accessible by the contract owner. This function is used to mint tokens for the team.
    function createTeamItem(uint256 amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(amount > 0, "Mint amount can't be zero");
        require(amount <= MAX_TOKEN_ITERATIONS, "You cannot mint this many in one transaction."); // Used to avoid OOG errors.
        require(supply + amount <= MAX_TOTAL_SUPPLY, "Max supply is reached");
        
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender , supply + i);
        }
    }

    // Minting function for addresses on the whitelist only
    function createWhitelistItem(uint256 amount) external payable {
        uint256 supply = totalSupply();
        uint256 whitelistAllowance = whitelist[msg.sender];
        require(whitelistSaleActive, "Whitelist sale is not active");
        require(amount <= whitelistAllowance, "Exceeded max available to purchase");
        require(amount > 0, "Mint amount can't be zero");
        require(amount <= MAX_TOKEN_ITERATIONS, "You cannot mint this many in one transaction."); // Used to avoid OOG errors.
        require(supply + amount <= MAX_TOTAL_SUPPLY, "Max supply is reached");
        require(amount * WHITELIST_MINT_PRICE == msg.value, "Price must be 0.09 eth for each NFT");
        
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender , supply + i);
        }

        whitelist[msg.sender] = whitelistAllowance - amount;
    }

    // Withdraw the value of the contract to the specified address
    function withdrawTo(address recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "There is no balance to transfer");
        payable(recipient).transfer(balance);
        emit Withdraw(msg.sender, recipient, balance);
    }

    // Used to get the list of token IDs owned by a user (address). Will not work for wallets with over 40 tokens
    function walletOfUser(address user) external view returns(uint256[] memory) {
        uint256 tokenCount = 0;
        uint256[] memory tokensId = new uint256[](0);
        tokenCount = balanceOf(user);
        
        if (tokenCount > MAX_TOKEN_ITERATIONS) {
            tokenCount = MAX_TOKEN_ITERATIONS; // limits the returned token count to avoid OOG errors
        }

        if (tokenCount > 0) {
            tokensId = new uint256[](tokenCount);
            for(uint256 i = 0; i < tokenCount; i++){
                tokensId[i] = tokenOfOwnerByIndex(user, i);
            }
        }
        return tokensId;
    }

    // An owner-only function which toggles the public sale on/off
    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        emit TogglePublicSale(msg.sender, publicSaleActive);
    }

    // An owner-only function which toggles the whitelist sale on/off
    function toggleWhitelistSale() external onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
        emit ToggleWhitelistSale(msg.sender, whitelistSaleActive);
    }

    // Allows the owner to update the max mint count, up to a limit of 40 (to avoid OOG errors)
    function setMaxMintCount(uint256 count) external onlyOwner {
        require(count <= MAX_TOKEN_ITERATIONS, "Count must be less than or equal to 40");
        maxMintCount = count;
        emit SetMaxMintCount(msg.sender, count);
    }

    // Function called by second minting contract which sets the redeemed status
    function setRedeemed(uint256 tokenID) external {
        require(_redeemingContract == msg.sender, "Can only be called by authorised contract");
        redeemedStatus[tokenID] = true;
    }

    // Function to change the allowed redeeming contract address
    function setRedeemingContract(address contractAddress) external onlyOwner {
        _redeemingContract = contractAddress;
    }
}