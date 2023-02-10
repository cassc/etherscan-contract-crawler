// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./LilOwnable.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error DoesNotExist();

contract UkiyoeGirl is ERC721, LilOwnable {

    using Strings for *;

    uint256 public constant TOTAL_SUPPLY = 1000;
    uint256 public totalSupply;
    uint16 public constant MAX_MINT_PER_WALLET = 60; 
    uint16 public constant BULK_BUY_LIMIT = 20;

    string public baseURI;

    bool public isMintPaused = true;
    bool public isPepeHolderMintPaused = true;

    IERC721 public immutable ukiyoPepeAddress;

    mapping(address => uint256) public minted;

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI,
        address _ukiyoPepeAddress

    ) ERC721(name, symbol) {
        baseURI = _baseURI;
        ukiyoPepeAddress = IERC721(_ukiyoPepeAddress);
    }

    modifier onlyOwner {
        require (msg.sender == _owner, "You are not the owner");
        _;
    }

    modifier isUkiyoPepeHolder {
        require (ukiyoPepeAddress.balanceOf(msg.sender) >= 1, "You don't hold UkiyoPepe"); 
        _;
    }

    function ukiyoPepeHolderMint(uint16 amount) external isUkiyoPepeHolder {
        require(amount <= BULK_BUY_LIMIT, "Can not mint more than 20 in one transaction.");
        require(totalSupply + amount <= TOTAL_SUPPLY, "Total supply already minted");
        require(isPepeHolderMintPaused == false, "UkiyoPepe holder mint is paused.");
        require (minted[msg.sender] + amount <= MAX_MINT_PER_WALLET, "mint: You can't mint more than 60 per wallet.");

        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply++);
            }
        }
        minted[msg.sender] += amount;
    }

    function publicMint(uint16 amount) external {
        require(amount <= BULK_BUY_LIMIT, "Can not mint more than 20 in one transaction.");
        require(totalSupply + amount <= TOTAL_SUPPLY, "Total supply already minted");
        require(isMintPaused == false, "Public mint is paused");
        require (minted[msg.sender] + amount <= MAX_MINT_PER_WALLET, "mint: You can't mint more than 60 per wallet.");

        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply++);
            }
        }
        minted[msg.sender] += amount; 
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf(id) == address(0)) revert DoesNotExist();

        // return string(abi.encodePacked(baseURI, id, ".json"));
        return string(abi.encodePacked(baseURI, '/', id.toString(), '.json'));
    }

        function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function withdraw() external onlyOwner {

        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    function pausePepeHolderMint() external onlyOwner {

        isPepeHolderMintPaused = true;
    }

    function unpausePepeHolderMint() external onlyOwner {

        isPepeHolderMintPaused = false;
    }

    function pauseMint() external onlyOwner { 

        isMintPaused = true;
    }

    function unpauseMint() external onlyOwner{ 

        isMintPaused = false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, LilOwnable)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }
}