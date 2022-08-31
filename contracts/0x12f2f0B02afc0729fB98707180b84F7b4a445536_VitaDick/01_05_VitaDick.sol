pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VitaDick is Ownable, ERC721A {
    string private _baseUri;
    uint256 public totalAmount = 1741;
    uint256 public constant MAX_TOKENS = 5;
    uint256 private _teamAmount = 15;
    uint256 private _teamTokensMinted = 0;
    uint256 public publicListingPrice = 0.005 ether;
    bool public isMintAllowed = true;
    address payable private _walletAddress;
    mapping(address => uint256) public addressBalance;

    constructor(
        address payable _initWalletAddress,
        string memory _initBaseUri
    ) ERC721A("VitaDick", "VD") {
        _walletAddress = _initWalletAddress;
        setBaseURI(_initBaseUri);
    }

    error SoldOut();
    error InsufficientBalance(string msg);

    modifier noContracts() {
        require(tx.origin == msg.sender, "No contracts allowed");
        _;
    }

    function setWalletAddress(address payable _newWalletAddress) external onlyOwner {
        _walletAddress = _newWalletAddress;
    }

    function setTotalAmountLimit(uint256 newLimit) external onlyOwner {
        require(newLimit <= totalAmount, "too many tokens");
        totalAmount = newLimit;
    }

    function flipIsMintAllowed() external onlyOwner {
        isMintAllowed = !isMintAllowed;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory _newBaseTokenURI) public onlyOwner {
        _baseUri = _newBaseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory directTokenURI = super.tokenURI(tokenId + 1);

        return
            bytes(directTokenURI).length > 0
                ? string(abi.encodePacked(directTokenURI, ".json"))
                : "";
    }
    

    function publicMint(uint256 amount) external payable noContracts {
        require(isMintAllowed, "Public Sale has not started yet");
        require(
            amount > 0 && addressBalance[msg.sender] + amount <= MAX_TOKENS,
            "Cannot mint specified number of NFTs."
        );
        if (totalSupply() + amount > totalAmount - _teamAmount) revert SoldOut();
        if (amount > 1 && msg.value < publicListingPrice * (amount - 1))
            revert InsufficientBalance("Need more ETH!");
        if (addressBalance[msg.sender] >= 1 && msg.value < publicListingPrice * amount )
            revert InsufficientBalance("Need more ETH!");
        addressBalance[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    function mintTeamTokens(address to, uint256 amount) external onlyOwner {
        require(
            _teamTokensMinted + amount <= _teamAmount,
            "This amount is more than max allowed"
        );
        _teamTokensMinted += amount;
        _safeMint(to, amount);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(_walletAddress).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}