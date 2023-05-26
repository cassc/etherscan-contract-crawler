// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
/* 
     .-. .-.
    (   |   )
  .-.:  |  ;,-.
 (_ __`.|.'_ __)
 (    ./Y\.    )
  `-.-' | `-.-'
        \ gas optimized mint
       */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

interface IERC721ABurnable is IERC721A {
    function burn(uint256 tokenId) external;
}

contract LeprechaunTown_WTF is Ownable, ERC721AQueryable, ReentrancyGuard, IERC721ABurnable {
    using Address for *;
    string private _baseTokenURI;
    uint256 public immutable maxSupply = 7777; // 🍀
    uint256 public immutable maxFree = 6000;
    uint256 public reserved = 100;
    uint256 public immutable freeLimit = 2;
    uint256 public immutable buyLimit = 5;
    uint256 public immutable phase2price = 0.03 ether;
    string public contractURI; /// @dev collection metadata

    constructor() ERC721A("LeprechaunTown_WTF", "LTWTF") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    ///@dev mint nft 🍀
    function mint() public payable nonReentrant {
        require(_totalMinted() != 0, "sale has not started");
        require(!msg.sender.isContract(), "please no contract");
        require(msg.sender == tx.origin, "please be yourself");
        uint64 userAlreadyMintedFree = _getAux(msg.sender);
        uint256 amount;
        if (_totalMinted() + reserved >= maxFree) {
            require(msg.value >= phase2price, "forgot eth attachment");
            amount = msg.value / phase2price;
            require(msg.value == phase2price * amount, "unnecessary");
            require(_numberMinted(msg.sender) + amount - userAlreadyMintedFree <= buyLimit, "limit 5");
        } else {
            require(userAlreadyMintedFree == 0, "dont be greedy, thats what got us here");
            amount = freeLimit;
            _setAux(msg.sender, uint64(freeLimit));
        }
        require(amount != 0, "amount is zero");
        _mint(msg.sender, amount);
        require(_totalMinted() <= maxSupply - reserved, "minting is finished");
    }

    ///@dev burn nft
    function burn(uint256 tokenId) public virtual override {
        _burn(tokenId, true);
    }

    // mint from reserved 100
    function devMint(uint256 quantity) external onlyOwner {
        require(quantity <= reserved, "no more reserved");
        require(quantity != 0, "no more to reserve");
        reserved -= quantity;
        _mint(msg.sender, quantity);
        require(_totalMinted() <= maxSupply - reserved, "that would exceed max supply");
    }

    /// @dev admin can get ether out
    function getEther(address to, uint256 amount) public onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        payable(to).sendValue(amount);
    }

    ///@dev admin can get all ether out
    function withdrawEther() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /// @dev admin can get token (it happens..)
    function getToken(
        address tokenAddr,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20 token = IERC20(tokenAddr);
        if (amount == 0) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    /// @dev see https://docs.opensea.io/docs/contract-level-metadata
    function setContractUri(string memory collectionUri) public onlyOwner {
        contractURI = collectionUri;
    }

    /// @dev see https://docs.opensea.io/docs/metadata-standards
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // view functions for dapp etc

    ///@dev amount user minted
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    ///@dev amount user burned
    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    ///@dev amount user minted during free mint
    function numberFreeMinted(address owner) public view returns (uint256) {
        return uint256(_getAux(owner));
    }

    ///@dev total number of nfts minted
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    ///@dev total number of nfts burned
    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    ///@dev nft exists and has not been burned
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    ///@dev view raw ownership data (address, startTimestamp, burned)
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }
} // ts22

interface IERC20 {
    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}