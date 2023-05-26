// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8;

import "../ONFT721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { GelatoRelayContext } from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";

/// @title Interface of the AdvancedONFT standard
/// @author exakoss
/// @notice this implementation supports: batch mint, payable public and private mint, reveal of metadata and EIP-2981 on-chain royalties
contract AdvancedONFT721Gasless is ONFT721, GelatoRelayContext, ReentrancyGuard {
    using Strings for uint;
    using SafeERC20 for IERC20;

    uint public tax = 1000; // 10% = 1000, 100 % = 10000
    uint public price = 0;
    uint public nextMintId;
    uint public maxMintId;
    uint public maxTokensPerMint;


    // address for withdrawing money and receiving royalties, separate from owner
    address payable beneficiary;
    // address for tax recipient;
    address payable taxRecipient;
    // Merkle Root for WL implementations
    bytes32 public merkleRoot;

    string public contractURI;
    string private baseURI;
    string private hiddenMetadataURI;

    bool public _publicSaleStarted;
    bool public _saleStarted;
    bool revealed;
    bool private _linearPriceIncreaseActive;

    mapping(address => uint16) private _whitelistMintCount;

    IERC20 public stableToken;

    modifier onlyBeneficiaryAndOwner() {
        require(msg.sender == beneficiary || msg.sender == owner() , "AdvancedONFT721Gasless: caller is not the beneficiary");
        _;
    }

    /// @notice Constructor for the AdvancedONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _startMintId the starting mint number on this chain, excluded
    /// @param _endMintId the max number of mints on this chain
    /// @param _maxTokensPerMint the max number of tokens that could be minted in a single transaction
    /// @param _baseTokenURI the base URI for computing the tokenURI
    /// @param _hiddenURI the URI for computing the hiddenMetadataUri
    constructor(
        string memory _name,
        string memory _symbol,
        address _layerZeroEndpoint,
        uint _startMintId,
        uint _endMintId,
        uint _maxTokensPerMint,
        string memory _baseTokenURI,
        string memory _hiddenURI,
        address _stableToken,
        uint _tax,
        address _taxRecipient
    ) ONFT721(_name, _symbol, _layerZeroEndpoint, 200000) {
        nextMintId = _startMintId;
        maxMintId = _endMintId;
        maxTokensPerMint = _maxTokensPerMint;
        //set default beneficiary to owner
        beneficiary = payable(msg.sender);
        baseURI = _baseTokenURI;
        hiddenMetadataURI = _hiddenURI;
        stableToken = IERC20(_stableToken);
        tax = _tax;
        taxRecipient = payable(_taxRecipient);
    }

    function setMintRange(uint _startMintId, uint _endMintId, uint _maxTokensPerMint) external onlyOwner {
        nextMintId = _startMintId;
        maxMintId = _endMintId;
        maxTokensPerMint = _maxTokensPerMint;
    }

    function setTax(uint _tax) external onlyOwner {
        tax = _tax;
    }

    function setTaxRecipient(address payable _taxRecipient) external onlyOwner {
        taxRecipient = payable(_taxRecipient);
    }

    /// @notice mint with stable coin
    function _mintTokens(address minter, uint _nbTokens) internal {
        //using a local variable, _mint and ++X pattern to save gas
        uint local_nextMintId = nextMintId;
        for (uint i; i < _nbTokens; i++) {
            _mint(minter, ++local_nextMintId);
        }
        nextMintId = local_nextMintId;
    }

    /// @notice gasless mint 
    function publicMintGasless(uint _nbTokens, address minter) external onlyGelatoRelay {
        require(_publicSaleStarted == true, "ONFT721Gasless: Public sale has not started yet!");
        require(_saleStarted == true, "ONFT721Gasless: Sale has not started yet!");
        require(_nbTokens != 0, "ONFT721Gasless: Cannot mint 0 tokens!");
        require(_nbTokens <= maxTokensPerMint, "ONFT721Gasless: You cannot mint more than maxTokensPerMint tokens at once!");
        require(nextMintId + _nbTokens <= maxMintId, "ONFT721Gasless: max mint limit reached");
        require(price > 0, "ONFT721Gasless: you need to set stable price");
        require(address(stableToken) != address(0), "ONFT721Gasless: not support stable token");

        _transferRelayFee();

             
        if ((_nbTokens < 4) && (_linearPriceIncreaseActive == true)) {
            stableToken.safeTransferFrom(minter, address(this), price * 3);
        } else {
            stableToken.safeTransferFrom(minter, address(this), price * _nbTokens);
        }
 
        _mintTokens(minter, _nbTokens);
    }


    /// @notice Gasless Mint your ONFTs, whitelisted addresses only
    function mintGasless(uint _nbTokens, address minter, bytes32[] calldata _merkleProof, uint wlTokenCount) external onlyGelatoRelay {
        require(_saleStarted == true, "ONFT721Gasless: Sale has not started yet!");
        require(_nbTokens != 0, "ONFT721Gasless: Cannot mint 0 tokens!");
        require(_nbTokens <= maxTokensPerMint, "ONFT721Gasless: You cannot mint more than maxTokensPerMint tokens at once!");
        require(nextMintId + _nbTokens <= maxMintId, "ONFT721Gasless: max mint limit reached");
        require(_whitelistMintCount[minter] + _nbTokens <= wlTokenCount, "ONFT721Gasless: cannot mint more than your whitelisted amount");

        bool isWL = MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(minter, wlTokenCount)));

        require(isWL == true, "ONFT721Gasless: Invalid Merkle Proof");

        _transferRelayFee();
        
        if ((_nbTokens < 4) && (_linearPriceIncreaseActive == true)) {
            stableToken.safeTransferFrom(minter, address(this), price * 3);
        } else {
            stableToken.safeTransferFrom(minter, address(this), price * _nbTokens);
        }
        
        _mintTokens(minter, _nbTokens);
        _whitelistMintCount[minter] += uint16(_nbTokens);
    }


    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }



    function withdraw() public virtual onlyBeneficiaryAndOwner {
        require(beneficiary != address(0), "AdvancedONFT721: Beneficiary not set!");

        uint _balance = stableToken.balanceOf(address(this));
        uint _taxFee = _balance * tax / 10000;

        stableToken.safeTransfer(taxRecipient, _taxFee);
        stableToken.safeTransfer(beneficiary, _balance - _taxFee);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setBeneficiary(address payable _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external onlyOwner {
        hiddenMetadataURI = _hiddenMetadataUri;
    }

    function setStableToken(address _stableToken) external onlyOwner {
        stableToken = IERC20(_stableToken);
    }

    function flipRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function flipSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;
    }

    function flipPublicSaleStarted() external onlyOwner {
        _publicSaleStarted = !_publicSaleStarted;
    }

    function flipLinearPriceIncreaseActive() external onlyOwner {
        _linearPriceIncreaseActive = !_linearPriceIncreaseActive;
    }

    // The following functions are overrides required by Solidity.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) {
            return hiddenMetadataURI;
        }
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    receive() external payable {}
}