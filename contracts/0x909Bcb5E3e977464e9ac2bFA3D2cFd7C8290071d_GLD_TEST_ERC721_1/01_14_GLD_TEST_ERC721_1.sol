//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GLD_TEST_ERC721_1 is 
    ERC721, 
    ERC2981, 
    Ownable, 
    ReentrancyGuard 
{   
    uint256 public cost = 0.0001 ether;
    uint256 public totalMinted;
    address public royaltyAddress;
    string private customBaseURI;
    bool public paused;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory customBaseURI_,
        address royaltyAddress_
    ) ERC721(tokenName, tokenSymbol) 
        ReentrancyGuard() 
        ERC2981()
    {
        customBaseURI = customBaseURI_;
        royaltyAddress = royaltyAddress_;
        paused = false;
        _setDefaultRoyalty(royaltyAddress, 1000);
    }

    /***********
        receive function
    */
    receive() external payable { 
    }

    /*************
        minting functions
    */
    function mint()
        external
        payable
        nonReentrant 
    {
        require(!paused, "paused");
        require(msg.value == cost, "ether != COST");

        _safeMint(msg.sender);

        emit Mint(msg.sender, totalMinted);
    }


    function mint(address _recipient) 
        external 
        payable 
        nonReentrant
    {
        require(!paused, "paused");

        require(msg.value == cost, "ether != COST");

        _safeMint(_recipient); 

        emit MintToRecipient(_recipient, totalMinted);
    }

    function mintDiscount()
        external
        payable
        nonReentrant
    {
        require(!paused, "paused");
        require(msg.value == ((cost * 1000) / 10000), "ether != DISCOUNT COST");

        _safeMint(msg.sender);

        emit MintDiscount(msg.sender, totalMinted);
    }

    function mintAllowlist()
        external
        payable
        nonReentrant
    {
        require(!paused, "paused");
        require(msg.value == cost, "ether != COST");

        _safeMint(msg.sender);

        emit MintAllowlist(msg.sender, totalMinted);
    }

    function mintByOwner(address to) 
        public  
        payable 
        onlyOwner
        nonReentrant 
    {
        _safeMint(to);

        emit MintByOwner(to, totalMinted);
    }

     function mintByOwner(address to, uint256 tokenId) 
        public  
        payable 
        onlyOwner
        nonReentrant 
    {
        _safeMint(to, tokenId);
        emit MintByOwner(to, tokenId);
    }

    function mintByOwnerBulk(address[] memory to) 
        external 
        payable 
        onlyOwner
        nonReentrant 
    {
        for (uint i = 0; i < to.length; i++) {
            _safeMint(to[i]);
        }

        emit MintByOwnerBulk(to.length);
    }

    function burn(uint256 tokenId) 
        external
        onlyOwner
    {
        address tokenOwner = ownerOf(tokenId);
        _burn(tokenId);
        
        (bool sent,) = payable(tokenOwner).call{value: cost}("");
        require(sent, "Failed to receive Ether");

        emit Burned(tokenId, cost);
    }

    function _safeMint(address to) 
        internal 
        virtual 
    {
        uint256 _totalMinted = ++totalMinted;
        
        _safeMint(to, _totalMinted);
    }

    function withdraw(address to, uint256 amount)
        external
        onlyOwner
    {
        (bool sent,) = payable(to).call{value: amount}("");
        require(sent, "Failed to pay Ether");
        emit Withdraw(to, amount);
    }
    
    /**************
        pause/unpause 
    */
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /*********
        update price
     */
    function setCost(uint256 newCost) 
        external 
        onlyOwner {
        cost = newCost;
        emit CostChanged(cost);
    }

    /*****************
        token uri
    */
    function baseTokenURI() 
        public 
        view 
        returns (string memory) 
    {
        return customBaseURI;
    }

    function setBaseURI(string memory customBaseURI_) 
        external 
        onlyOwner 
    {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return customBaseURI;
    }

    /**********
        supported interfaces 
    */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC2981, ERC721) returns (bool)
    {   
        return super.supportsInterface(interfaceId);
    }

    /***********
        ERC2981 interface
    */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external 
        onlyOwner 
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltyChanged(tokenId, receiver);
    }

    function updateDefaultRoyalty(
        address newRoyaltyReceiver
    ) external 
        onlyOwner 
    {
        royaltyAddress = newRoyaltyReceiver;
        _setDefaultRoyalty(royaltyAddress, 1000);
        emit RoyaltyAddressChanged(royaltyAddress);
    }

    /**************
        public function to get state of mint
    */
    function mintState() 
        public 
        view
        returns (
            bool isPaused, 
            uint256 numMinted, 
            string memory baseUri,
            uint256 mintCost
        )
    {
        return (paused, totalMinted, customBaseURI, cost);
    }

    /*************
        events
    */
    event Mint(address indexed to, uint256 tokenId);
    event MintToRecipient(address indexed to, uint256 tokenId);
    event MintDiscount(address indexed to, uint256 tokenId);
    event MintAllowlist(address indexed to, uint256 tokenId);
    event MintByOwner(address indexed to, uint256 tokenId);
    event MintByOwnerBulk(uint256 numMinted);
    event Withdraw(address indexed to, uint256 amount);
    event Paused();
    event Unpaused();
    event CostChanged(uint256 cost);
    event Burned(uint256 tokenId, uint256 cost);
    event RoyaltyAddressChanged(address indexed to);
    event TokenRoyaltyChanged(uint256 tokenId, address indexed to);
}