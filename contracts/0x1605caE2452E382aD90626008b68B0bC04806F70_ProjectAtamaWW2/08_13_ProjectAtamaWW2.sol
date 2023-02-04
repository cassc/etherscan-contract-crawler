// SPDX-License-Identifier: MIT


// - .... .. ... / .. ... / .--- ..- ... - / - .... . / -... . --. .. -. .. -. --. / ... --- .-.. -.. .. . .-. --..-- / .--. . --- .--. .-.. . / .-- .... --- / .- .-. . -. .----. - / .--. .- .-. - / --- ..-. / - .... .. ... / .--. .-. --- .--- . -.-. - / .- .-. . / --. --- .. -. --. / - --- / -- .. ... ... / --- ..- - / .. -. / .-- . -... ...-- / .... .. ... - --- .-. -.--


pragma solidity ^0.8.13;

import 'util/ERC721A.sol';
import 'util/operator-filter-registry/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract ProjectAtamaWW2 is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    address[] MarketplaceBlockList = [
        0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e,
        0x00000000000111AbE46ff893f3B2fdF1F759a8A8, 
        0xb16c1342E617A5B6E4b631EB114483FDB289c0A4 
    ];

    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public maxSupply = 2500;
    uint256 public maxPublicMintAmountPerTx = 1;
    uint256 public maxTeamMintAmountPerWallet = 1;
    uint256 public maxWhitelistMintAmountPerWallet = 2;

    uint256 public publicMintCost = 0.08 ether;
    uint256 public teamMintCost = 0 ether;
    uint256 public whitelistMintCost = 0.08 ether;

    bytes32 public merkleRoot1;
    bytes32 public merkleRoot2;
    bool public paused = true;
    bool public teamMintEnabled = false;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        hiddenMetadataUri = _hiddenMetadataUri;
        ownerClaimed();
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function ownerClaimed() internal {
        _mint(_msgSender(), 766);
    }

    function teamMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable mintCompliance(_mintAmount) {
        require(teamMintEnabled, "The team sale is not enabled!");
        require(
            _numberMinted(_msgSender()) + _mintAmount <=
                maxTeamMintAmountPerWallet,
            "Max limit per wallet!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot1, leaf),
            "Invalid proof for team member!"
        );

        _safeMint(_msgSender(), _mintAmount);
    }

    function whitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable mintCompliance(_mintAmount) {
        require(whitelistMintEnabled, "The whitelist is not enabled!");
        require(
            _numberMinted(_msgSender()) + _mintAmount <=
                maxWhitelistMintAmountPerWallet,
            "Max limit per wallet!"
        );
        require(
            msg.value >= whitelistMintCost * _mintAmount,
            "Insufficient funds for Whitelist!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot2, leaf),
            "Invalid proof for whitelist!"
        );

        _safeMint(_msgSender(), _mintAmount);
    }

    function publicMint(
        uint256 _mintAmount
    ) public payable mintCompliance(_mintAmount) nonReentrant {
        require(!paused, "The mint is paused!");
        require(
            msg.value >= publicMintCost * _mintAmount,
            "Insufficient funds for public sale!"
        );
        require(
            _mintAmount <= maxPublicMintAmountPerTx,
            "Max limit per Transaction!"
        );
        _safeMint(_msgSender(), _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        publicMintCost = _cost;
    }

    function setMaxPublicMintAmountPerTx(
        uint256 _maxPublicMintAmountPerTx
    ) public onlyOwner {
        maxPublicMintAmountPerTx = _maxPublicMintAmountPerTx;
    }

    function setMaxTeamMintAmountPerWallet(
        uint256 _maxTeamMintAmountPerWallet
    ) public onlyOwner {
        maxTeamMintAmountPerWallet = _maxTeamMintAmountPerWallet;
    }

    function setMaxWhitelistMintAmountPerWallet(
        uint256 _maxWhitelistMintAmountPerWallet
    ) public onlyOwner {
        maxWhitelistMintAmountPerWallet = _maxWhitelistMintAmountPerWallet;
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot1(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot1 = _merkleRoot;
    }

    function setMerkleRoot2(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot2 = _merkleRoot;
    }

    function setTeamMintEnabled(bool _state) public onlyOwner {
        teamMintEnabled = _state;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

      //****OPENSEA FILTER FUNCTIONS***
      function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
      }

      function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
      }

      function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
      }

    // --------------------------------------------------------------------------
    // ***                     START: Overridden functions                 *** //
    // --------------------------------------------------------------------------
    function approve(
        address _to,
        uint256 _tokenId
    ) public payable virtual override {
        _checkMarketplaceBlockList(_to); // we add this to the approve methods
        super.approve(_to, _tokenId);
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public virtual override {
        _checkMarketplaceBlockList(_operator); // we add this to the approve methods
        super.setApprovalForAll(_operator, _approved);
    }

    // --------------------------------------------------------------------------
    // ***                       END: Overridden functions                 *** //
    // --------------------------------------------------------------------------

    // --------------------------------------------------------------------------
    // ***                       START: Public functions                   *** //
    // --------------------------------------------------------------------------
    function getBlockList() public view returns (address[] memory) {
        return MarketplaceBlockList;
    }

    function addToMarketplaceBlockList(
        address _mpToBeBlocked
    ) public onlyOwner {
        bool alreadyInList = false;

        for (uint i = 0; i < MarketplaceBlockList.length; i++) {
            if (_mpToBeBlocked == MarketplaceBlockList[i]) {
                alreadyInList = true;
            }
        }

        require(alreadyInList == false, "MARKETPLACE ALREADY IN BLOCKLIST");
        MarketplaceBlockList.push(_mpToBeBlocked);
    }

    function removeFromMarketplaceBlockList(
        address _mpToBeUnblocked
    ) public onlyOwner {
        bool alreadyInList = false;
        uint foundAtIndex;

        for (uint i = 0; i < MarketplaceBlockList.length; i++) {
            if (_mpToBeUnblocked == MarketplaceBlockList[i]) {
                alreadyInList = true;
                foundAtIndex = i;
            }
        }

        require(alreadyInList == true, "MARKETPLACE NOT IN BLOCKLIST");
        _removeFromBlockListArray(foundAtIndex);
    }

    // --------------------------------------------------------------------------
    // ***                        END: Public functions                    *** //
    // --------------------------------------------------------------------------

    // --------------------------------------------------------------------------
    // ***                  START: Internal/private functions              *** //
    // --------------------------------------------------------------------------
    function _checkMarketplaceBlockList(address _to) internal view {
        for (uint i = 0; i < MarketplaceBlockList.length; i++) {
            require(
                _to != MarketplaceBlockList[i],
                "TRADING NOT SUPPORTED VIA THIS MARKETPLACE"
            );
        }
    }

    function _removeFromBlockListArray(uint index) private {
        if (index >= MarketplaceBlockList.length) return;

        MarketplaceBlockList[index] = MarketplaceBlockList[
            MarketplaceBlockList.length - 1
        ];
        MarketplaceBlockList.pop();
    }
    // --------------------------------------------------------------------------
    // ***                   END: Internal/private functions               *** //
    // --------------------------------------------------------------------------
}