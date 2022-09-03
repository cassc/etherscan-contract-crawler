// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract IvyLeague is ERC721A, Ownable {

    // ===== CONSTANTS =====
    uint256 public WL_MINT_PRICE = 1.5 ether;
    uint256 public PUBLIC_MINT_PRICE = 2.0 ether;
    uint256 public TOTAL_SUPPLY = 133;
    string public baseURI;
    string public prerevealedURI;
    bool isRevealed = false;
    bool public isWhitelistMintActive;
    bool public isPublicMintActive;
    mapping(uint256 => bool) public isSoulBound;

    mapping(address => uint256) public whitelist;

    constructor() ERC721A("IvyLeague", "IVYL") {}

    function airdrop(
        address[] calldata _receivers,
        uint256[] calldata _numTokens
    ) external onlyOwner {
        require(_receivers.length == _numTokens.length, "Mismatched arrays");
        for (uint256 i; i < _receivers.length; ) {
            _mint(_receivers[i], _numTokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ===== MINTING =====

    function publicMint(uint256 _quantity) public payable {
        require(msg.value >= _quantity * PUBLIC_MINT_PRICE, "Not enough eth sent");
        require(isPublicMintActive, "Public sale has not started");
        require(
            totalSupply() + _quantity <= TOTAL_SUPPLY,
            "Exceed total supply"
        );
        _mint(msg.sender, _quantity);
    }

    function whitelistMint(uint256 _quantity) external payable {
        require(isWhitelistMintActive, "Whitelist sale has not started");
        require(whitelist[msg.sender] >= _quantity, "Exceed whitelist limit");
        require(msg.value >= _quantity * WL_MINT_PRICE, "Not enough eth sent");
        require(
            totalSupply() + _quantity <= TOTAL_SUPPLY,
            "Exceed total supply"
        );
        _mint(msg.sender, _quantity);
        whitelist[msg.sender] -= _quantity;
    }

    function teamMint(uint256 _quantity) external onlyOwner {
        require(
            totalSupply() + _quantity <= TOTAL_SUPPLY,
            "Exceed total supply"
        );
        _mint(msg.sender, _quantity);
    }

    // ===== SETTERS =====

    function setMintPrice(uint256 _presale, uint256 _public) external onlyOwner {
        WL_MINT_PRICE = _presale;
        PUBLIC_MINT_PRICE = _public;
    }

    function setWhitelist(
        address[] calldata _addresses,
        uint256[] calldata _counts
    ) external onlyOwner {
        require(_addresses.length == _counts.length, "Mismatched arrays");
        for (uint256 i; i < _addresses.length; ) {
            whitelist[_addresses[i]] = _counts[i];
            unchecked {
                ++i;
            }
        }
    }

    function setSoulBound(
        uint256[] calldata _tokenIds,
        bool[] calldata _state

    ) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; ) {
            isSoulBound[_tokenIds[i]] = _state[i];
            unchecked {
                ++i;
            }
        }
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTotalSupply(uint256 _supply) external onlyOwner {
        TOTAL_SUPPLY = _supply;
    }

    function setPrerevealedURI(string calldata _uri) external onlyOwner {
        prerevealedURI = _uri;
    }

    function setIsRevealed(bool _revealed) external onlyOwner {
        isRevealed = _revealed;
    }

    function setMintPhase(bool _whitelist, bool _public) public onlyOwner {
        isPublicMintActive = _public;
        isWhitelistMintActive = _whitelist;
    }

    // ==== WITHDRAW ====

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // ==== OVERRIDES ====

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        if (!isRevealed) return prerevealedURI;

        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) {
        require(isSoulBound[tokenId], "Not allowed to transfer");
        super.transferFrom(from, to, tokenId);
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}