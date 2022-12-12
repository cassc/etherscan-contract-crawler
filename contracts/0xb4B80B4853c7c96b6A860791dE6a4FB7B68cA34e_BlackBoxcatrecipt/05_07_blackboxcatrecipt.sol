// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlackBoxcatrecipt is Ownable, ERC721A {
    uint256 public immutable collectionSize = 200;

    struct saleInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 maxAvailable;
        uint256 purchaseLimit;
        uint256 price;
    }

    saleInfo public mintInfo;
    address public nftContract;

    // metadata URI
    string private _baseTokenURI;

    constructor() ERC721A("Boxcat black ball", "BBB") {
    }


    modifier checkSupply(uint256 _amount) {
        require(_amount > 0, "Invalid amount");
        require(
            totalSupply() + _amount <= collectionSize,
            "Exceeding max supply"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Public Mint
    // *****************************************************************************
    // Public Functions
    function mint(uint256 quantity)
        external
        payable
        callerIsUser
        checkSupply(quantity)
    {
        require(isMintOn(), "Public sale has not begun yet");

        IERC721A forgingContract = IERC721A(nftContract);
        require(
            (forgingContract.balanceOf(msg.sender) > 0),
            "Cannot mint if you don't have boxcat"
        );

        require(
            quantity + numberMinted(msg.sender) <= mintInfo.purchaseLimit,
            "Cannot mint more"
        );
        require(quantity <= mintInfo.maxAvailable, "Phase Sold out");

        require(msg.value >= quantity * mintInfo.price, "Insuffcient ETH");

        mintInfo.maxAvailable -= quantity;

        _mint(msg.sender, quantity);
    }

    function isMintOn() public view returns (bool) {
        require(mintInfo.startTime != 0, "Mint Start Time is TBD.");
        require(mintInfo.endTime != 0, "Mint End Time is TBD.");

        return
            (block.timestamp >= mintInfo.startTime) &&
            (block.timestamp <= mintInfo.endTime);
    }

    // Public Views
    // *****************************************************************************
    function numberMinted(address user) public view returns (uint256) {
        return _numberMinted(user);
    }

    // Owner Controls

    // Contract Controls (onlyOwner)
    // *****************************************************************************
    function setBaseURI(string calldata baseURI)
        external
        onlyOwner
    {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setupMintInfo(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxAvailable,
        uint256 _purchaseLimit,
        uint256 _price
    ) external onlyOwner {
        mintInfo.startTime = _startTime;
        mintInfo.endTime = _endTime;
        mintInfo.maxAvailable = _maxAvailable;
        mintInfo.purchaseLimit = _purchaseLimit;
        mintInfo.price = _price;
    }

    function setNftContract(address _nftContract) external onlyOwner {
        nftContract = _nftContract;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        require(from == address(0), "cannot be transfered");
    }

}