// SPDX-License-Identifier: MIT
//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel

/* 
  ______ _____   ____   _____   _      ____  _____  _____   _____ 
 |  ____|  __ \ / __ \ / ____| | |    / __ \|  __ \|  __ \ / ____|
 | |__  | |__) | |  | | |  __  | |   | |  | | |__) | |  | | (___  
 |  __| |  _  /| |  | | | |_ | | |   | |  | |  _  /| |  | |\___ \ 
 | |    | | \ \| |__| | |__| | | |___| |__| | | \ \| |__| |____) |
 |_|    |_|  \_\\____/ \_____| |______\____/|_|  \_\_____/|_____/ 
                                                                  
*/

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract FrogLords is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    string public baseURI;
    uint256 public cost = 0.0059 ether;
    uint256 public maxSupply = 7777;
    uint256 public MaxperWallet = 7;
    bool public paused = true;
    mapping(address => bool) public FreeClaimed;

    constructor() ERC721A("Frog Lords", "FROG") {}

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public
    /// @dev Public mint
    function mint(uint256 tokens) public payable nonReentrant {
        require(!paused, "FROG: oops contract is paused");
        require(
            tokens <= MaxperWallet,
            "FROG: max mint amount per tx exceeded"
        );
        require(totalSupply() + tokens <= maxSupply, "FROG: We Soldout");
        require(
            numberMinted(_msgSenderERC721A()) + tokens <= MaxperWallet,
            "FROG: Max NFT Per Wallet exceeded"
        );
        if (!FreeClaimed[_msgSenderERC721A()]) {
            uint256 pricetopay = tokens - 1;
            require(msg.value >= cost * pricetopay, "FROG: insufficient funds");
            FreeClaimed[_msgSenderERC721A()] = true;
        } else {
            require(msg.value >= cost * tokens, "FROG: insufficient funds");
        }
        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev use it for giveaway and team mint
    function airdrop(uint256 _mintAmount, address[] calldata destination)
        public
        onlyOwner
        nonReentrant
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "max NFT limit exceeded"
        );
        for (uint256 i = 0; i < destination.length; i++) {
            _safeMint(destination[i], _mintAmount);
        }
    }

    /// @notice returns metadata link of tokenid
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /// @notice return the number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @notice return the tokens owned by an address
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    //only owner
    /// @dev change the public max per wallet
    function setMaxPerWallet(uint256 _limit) public onlyOwner {
        MaxperWallet = _limit;
    }

    /// @dev change the public price(amount need to be in wei)
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    /// @dev cut the supply if we dont sold out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
        maxSupply = _newsupply;
    }

    /// @dev set your baseuri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev to pause and unpause your contract(use booleans true or false)
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /// @dev withdraw funds from contract
    function withdraw() public payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSenderERC721A()).transfer(balance);
    }

    /// Opensea Royalties
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}