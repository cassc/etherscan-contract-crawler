// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error allowwhitelistfail();
error PriceErr();
error Minting();
error OwnerOfContract();

contract KaiganGenesis is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter public _totalSupply;
    //! Address Dev, Founder Pirce and PublicMint
    uint256 public priceGK = 0.2 ether; //* The current parameter is wei
    uint256 public LimitedToken;
    address public DEV;
    address public Founder;
    bool public publicMint;

    //! Mapping
    mapping(address => mapping(uint256 => bool)) public AllowWLAdd; //* Mint Acceptance List Addresses;
    mapping(uint256 => bool) public AllowToken; //* Mint Acceptance list Token;

    modifier onlyFounder() {
        if (msg.sender != DEV && msg.sender != Founder) {
            revert OwnerOfContract();
        }
        _;
    }

    //! Events
    event TokenMaxMint(uint256 indexed _Limitedtoken);

    constructor(address _Founder) payable ERC721("KaiganGenesis", "KGN") {
        DEV = msg.sender; //* Set Address DEV
        Founder = _Founder;
    }

    function setWlToken(address[] calldata _wlAdd, uint256[] calldata _TokenId)
        external
        onlyFounder
    {
        if (_wlAdd.length != _TokenId.length) {
            revert allowwhitelistfail();
        }
        for (uint256 i = 0; i < _wlAdd.length; i++) {
            AllowWLAdd[_wlAdd[i]][_TokenId[i]] = true;
            AllowToken[_TokenId[i]] = true;
        }
    }

    function PbMintConfig(uint256 _LimitedToken, bool _pb)
        external
        onlyFounder
    {
        publicMint = _pb;
        LimitedToken = _LimitedToken;
        emit TokenMaxMint(_LimitedToken);
    }

    //! Mint Genesis
    function GKmint(uint256 _idtoken) external payable {
        if (msg.value < priceGK || _idtoken > LimitedToken) {
            revert Minting();
        }
        if (_idtoken == 4) {
            revert Minting();
        }
        //* Check Allow Token to Mint
        if (AllowToken[_idtoken] == true) {
            //* Minting With WL
            if (AllowWLAdd[msg.sender][_idtoken] == true) {
                mintGK(_idtoken);
                delete AllowWLAdd[msg.sender][_idtoken];
                delete AllowToken[_idtoken];
                _totalSupply.increment();
            } else {
                //* Error Minting WL;
                revert Minting();
            }
        } else {
            mintGK(_idtoken);
            _totalSupply.increment();
        }
    }

    function DevMint() external onlyFounder {
        if (_exists(0)) {
            revert Minting();
        }
        // require(!_exists(0), "Token has alreay minted."); //* Check the current token.
        _safeMint(msg.sender, 0);
        _totalSupply.increment();
    }

    //! Refunds

    function mintGK(uint256 tokenid) internal {
        _safeMint(msg.sender, tokenid);
        refund(priceGK);
    }

    function refund(uint256 price) internal {
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    //! Set PriceGK
    function setPrice(uint256 _number) external onlyFounder {
        if (_number <= 0) {
            revert PriceErr();
        }
        priceGK = _number;
    }

    //! Metadata
    string private _baseTokenURI;

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyFounder {
        _baseTokenURI = baseURI;
    }

    //! Withdraw
    function withdraw() external onlyFounder nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}