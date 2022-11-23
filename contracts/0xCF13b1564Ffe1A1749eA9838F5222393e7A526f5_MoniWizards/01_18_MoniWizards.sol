// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";


contract MoniWizards is DefaultOperatorFilterer, ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(address => bool) public mintRecords;

    uint256 public waveSupply;
    uint256 public MAX_SUPPLY;
    uint256 public waveMinted;
    uint256 public pricePerToken;

    uint256 public whiteListStart;
    uint256 public allowListStart;
    uint256 public publicStart;

    string public baseURI;

    bytes32 private merkleRootWhitelist;
    bytes32 private merkleRootAllowlist;
    mapping(address => bool) private claimList;

    bool public saleOpen = false;

    enum Status {
        Closed,
        SoldOut,
        WhiteListMint,
        AllowListMint,
        PublicMint,
        NotStarted,
        SoldOutStage
    }

    enum WalletStage {
        whiteList,
        allowList,
        publicMint
    }

    struct Info {
        Status stage;
        uint256 whiteListStart;
        uint256 allowListStart;
        uint256 publicStart;
        bool saleOpen;
        uint256 waveSupply;
        uint256 maxSupply;
        uint256 waveMinted;
        uint256 totalMinted;
        uint256 pricePerToken;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 _supply,
        uint256 _maxSupply,
        uint256 _pricePerToken
    )
    ERC721(name, symbol)
    {
        pricePerToken = _pricePerToken;
        waveSupply = _supply;
        MAX_SUPPLY = _maxSupply;
    }

    function info()
    public
    view
    returns
    (Info memory)
    {
        return Info(
            stage(),
            whiteListStart,
            allowListStart,
            publicStart,
            saleOpen,
            waveSupply,
            MAX_SUPPLY,
            waveMinted,
            totalSupply(),
            pricePerToken
        );
    }

    function stage()
    public
    view
    returns (Status)
    {
        if (!saleOpen) {
            return Status.Closed;
        }

        if (totalSupply() >= MAX_SUPPLY) {
            return Status.SoldOut;
        }

        if (waveMinted >= waveSupply) {
            return Status.SoldOutStage;
        }

        uint256 ts = block.timestamp;
        if (publicStart != 0 && ts >= publicStart) {
            return Status.PublicMint;
        } else if (allowListStart != 0 && ts >= allowListStart) {
            return Status.AllowListMint;
        } else if (whiteListStart != 0 && ts >= whiteListStart) {
            return Status.WhiteListMint;
        }

        return Status.NotStarted;
    }

    function setMerkleRootWhitelist(bytes32 _merkleRoot)
    external
    onlyOwner
    {
        merkleRootWhitelist = _merkleRoot;
    }

    function setMerkleRootAllowlist(bytes32 _merkleRoot)
    external
    onlyOwner
    {
        merkleRootAllowlist = _merkleRoot;
    }

    function addToClaimlist(address[] calldata _claimlist)
    external
    onlyOwner
    {
        for (uint i = 0; i < _claimlist.length; i++) {
            claimList[_claimlist[i]] = true;
        }
    }

    function removeFromClaimlist(address[] calldata _claimlist)
    external
    onlyOwner
    {
        for (uint i = 0; i < _claimlist.length; i++) {
            if (claimList[_claimlist[i]]) {
                delete claimList[_claimlist[i]];
            }
        }
    }

    function startWave(uint256 _whiteListStart, uint256 _allowListStart, uint256 _publicStart, uint256 _amount)
    public
    onlyOwner
    {
        waveMinted = 0;
        waveSupply = _amount;
        setSaleStart(_whiteListStart, _allowListStart, _publicStart);
    }

    function withdraw()
    public
    onlyOwner
    {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setSaleOpen()
    onlyOwner
    external
    {
        saleOpen = true;
    }

    function setSaleClose()
    onlyOwner
    external
    {
        saleOpen = false;
    }

    function setSaleStart(uint256 _whiteListStart, uint256 _allowListStart, uint256 _publicStart)
    internal
    {
        whiteListStart = _whiteListStart;
        allowListStart = _allowListStart;
        publicStart = _publicStart;
    }

    function setBaseURI(string memory _uri)
    external
    onlyOwner
    {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function setPrice(uint256 _price)
    external
    onlyOwner
    {
        pricePerToken = _price;
    }

    function mint(bytes32[] calldata _merkleProof)
    payable
    external
    {
        require(saleOpen, "Sale is closed");

        uint256 _totalSupply = totalSupply();

        require(_totalSupply + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(waveMinted + 1 <= waveSupply, "Purchase would exceed wave max tokens");
        require(msg.value >= pricePerToken, "Ether value sent is not correct");
        require(!mintRecords[msg.sender], "Already minted");

        uint256 _publicStart = publicStart;
        uint256 _allowListStart = allowListStart;
        uint256 _whiteListStart = whiteListStart;

        require(_publicStart > 0, "Public start should be set");
        require(_allowListStart > 0, "Public start should be set");
        require(_whiteListStart > 0, "Public start should be set");

        uint256 ts = block.timestamp;

        if (ts >= _publicStart) {
            _mintInternal();
        } else if (ts >= _allowListStart) {
            require(MerkleProof.verify(
                    _merkleProof,
                    merkleRootAllowlist,
                    keccak256(abi.encodePacked(msg.sender)
                    )), "Wallet is not in allowlist");
            _mintInternal();
        } else if (ts >= _whiteListStart) {
            require(MerkleProof.verify(
                    _merkleProof,
                    merkleRootWhitelist,
                    keccak256(abi.encodePacked(msg.sender)
                    )), "Wallet is not in whitelist");
            _mintInternal();
        } else {
            revert("Sale not started yet");
        }
    }

    function claim()
    external
    {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(!mintRecords[msg.sender], "Already minted");
        require(claimList[msg.sender], "Wallet is not in claim list");
        mintRecords[msg.sender] = true;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function _mintInternal()
    private
    {
        mintRecords[msg.sender] = true;
        waveMinted += 1;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function revoke(address _from, address _to, uint256 _id)
    external
    onlyOwner
    {
        _transfer(_from, _to, _id);
    }

    function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}