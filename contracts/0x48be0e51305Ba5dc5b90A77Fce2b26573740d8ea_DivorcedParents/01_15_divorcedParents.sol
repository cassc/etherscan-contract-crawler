// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/interfaces/IERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/** @title An ERC721A contract named NFTtrial
 @author UNKNOWN
 @notice Serves as a non-fungible token
 @dev Test
 */


contract DivorcedParents is
    Ownable,
    ERC721A,
    IERC721ABurnable,
    PaymentSplitter,
    ReentrancyGuard
{
    using Strings for uint256;


    // Deployer Address
    address private _owner;
    // The next token ID to be minted.
    uint256 private _currentIndex = 1;
    // The number of tokens burned.
    uint256 public _burnCounter;
    // Token name
    string public _name;
    // Hidden Metadata
    string public hiddenMetadataUri = "https://ipfs.io/ipfs/QmSePyGHhngcyjtf2pzDnNRBfNNxMs9bASAQQDZsou1oR4";
    // Revealed
    bool public revealed = false;
    // Token symbol
    string private _symbol;
    // Cost
    uint256 public cost = 0.0069 ether;
    // Base URI
    string public baseURI = "https://ipfs.io/ipfs/QmdAvUEk1X9UMnDjcBVYazJxWDNtZf7UZ9P2GpPiUisDaK/";
    // Total Number of Toxic Relationships
    uint256 public _maxSupply = 6969;
    // Sale active or not
    bool public _parentsFighting;
    // Number of free parental figures in wallet
    uint256 public _freeparentsPerWallet = 1;

    // Mappings
    // mapping (address => uint256) public timeOfSetApprovalForAll;

    // function setApprovalForAll() public {
    //     timeOfSetApprovalForAll[msg.sender] = block.timestamp;
    // }

    constructor()
        payable
        ERC721A("Divorced Parents", "DP69")
        PaymentSplitter(_team, _teamShares)
    {
        _owner = msg.sender;
        _currentIndex = _startTokenId();
    }



/*---------- ----------- ---------- Public Functions ---------- ----------- ----------*/
    
    /** 
    @notice
    Mint Function
  */
    function _mint(uint256 count) external payable nonReentrant {
        if(balanceOf(msg.sender) < 1) {
            require(msg.value >= (cost * count) - cost, "Insufficient Payment");
            require(_parentsFighting);
        } else {
            require(msg.value >= cost * count, "Insufficient Payment");
            require(_parentsFighting);
        }
            _safeMint(msg.sender, count);
        }
    
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return string(abi.encodePacked(hiddenMetadataUri));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }
    }

    function owner() public view virtual override returns (address) {
        return _owner;
    }
/*---------- ----------- ---------- Deployer Functions ---------- ----------- ----------*/
    
    function _teamMint() external onlyOwner {
        _safeMint(msg.sender, 1);
    }

    function _reveal() public onlyOwner {
        revealed = !revealed;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function _flipSale() external onlyOwner {
        _parentsFighting = !_parentsFighting;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function burn(uint256 tokenId) onlyOwner external virtual override {
        _burn(tokenId, true);
    }

/*---------- ----------- ---------- Internal Functions ---------- ----------- ----------*/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Team Address For Payout
    uint256[] private _teamShares = [50, 50];
    address[] private _team = [
        0xba897860Ec9B4B1defc9ACE4316f3aAE127a9F62,
        0xa6F4f68339641F3C7ad4808d05304Eb6e0EEC657
    ];


}