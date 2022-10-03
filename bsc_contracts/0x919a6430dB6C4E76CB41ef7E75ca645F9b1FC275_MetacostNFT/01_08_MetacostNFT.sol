// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MetacostNFT is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0 ether;
    uint256 public maxSupply = 6;
    bool public isPaused = false;

    constructor(string memory _initBaseURI)
        ERC721A("Metacost NFT", "METACOST")
    {
        setBaseURI(_initBaseURI);
    }

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
        require(!isPaused, "Contract is isPaused.");
        require(msg.value >= cost * tokens, "Insufficient funds");
        require(totalSupply() + tokens <= maxSupply, "NFT sold out");
        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev use it for giveaway and team mint
    function airdrop(uint256 _mintAmount, address destination)
        public
        onlyOwner
        nonReentrant
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "max NFT limit exceeded"
        );
        _safeMint(destination, _mintAmount);
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
                        baseExtension
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

    /// @dev set baseuri extension
    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    /// @dev to pause and unpause your contract(use booleans true or false)
    function pause(bool _state) public onlyOwner {
        isPaused = _state;
    }

    /// @dev withdraw funds from contract
    function withdraw() public payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSenderERC721A()).transfer(balance);
    }
}