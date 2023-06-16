//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SleepySniperSociety is Ownable, ERC721A {
    /// @notice baseURI, usually represents ipfs gateway link
    string _baseURIVal;
    string constant _prerevealUri = "https://gateway.pinata.cloud/ipfs/QmWVBkMEo9FoR5T9Bvc8BXB78MPsaA1KnuRHcdrdrmdc9n";
    bool _revealed = false;
    bytes32 _allowListMerkleRoot;
    mapping(address => uint) _personMinted;


    enum CurrentSalePhase { NotStarted, Phase1_AllowList2, Phase2_AllowList3, PublicSale, Paused, Stopped } // allowlist 2 tokens, allowlist 3 tokens, public sale
    CurrentSalePhase public currentPhase = CurrentSalePhase.NotStarted;

    uint public maxMintPerPerson = 3;

    uint public allowListPrice = 39000000000000000; // 0.039eth in wei
    uint public publicSalePrice = 39000000000000000; // 0.039eth in wei

    uint public constant TotalSupplyCap = 5000;

    constructor(string memory name, string memory symbol, bytes32 whiteListMerkleRoot, uint premintTokensNumber, address premintAddress) ERC721A(name, symbol){
        _allowListMerkleRoot = whiteListMerkleRoot;
        _safeMint(premintAddress, premintTokensNumber);
    }

    /// @notice sets current phase of sale (for now for simplicity and debugging)
    /// @param phase CurrentSalePhase  - current phase of sale
    function setCurrentPhase(CurrentSalePhase phase) external onlyOwner {
        require(!_revealed, "Can't change phase after reveal");
        currentPhase = phase;
    }

    /// @notice Sets allow list merkle root
    /// @param merkleRoot byte32
    function setAllowListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _allowListMerkleRoot = merkleRoot;
    }

    /// @notice Sets allowListPrice
    /// @param allowListPriceParam uint of new public sale price
    function setAllowListSalePrice(uint allowListPriceParam) external onlyOwner {
        allowListPrice = allowListPriceParam;
    }

    /// @notice Sets publicSalePrice
    /// @param publicSalePriceParam uint of new public sale price
    function setPublicSalePrice(uint publicSalePriceParam) external onlyOwner {
        publicSalePrice = publicSalePriceParam;
    }

    /// @notice Sets maxMintPerPerson
    /// @param maxMintPerPersonParam uint of new public sale price
    function setMaxMintPerPerson(uint maxMintPerPersonParam) external onlyOwner {
        maxMintPerPerson = maxMintPerPersonParam;
    }

    /// @notice Sets baseURIParam
    /// @param baseURIParam uint of new public sale price
    function setBaseURI(string calldata baseURIParam) external onlyOwner {
        _baseURIVal = baseURIParam;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIVal;
    }

    function baseURI() external view virtual returns (string memory) {
        return _baseURI();
    }

    /// @notice Reveal
    /// @param URI String of new baseURI
    function reveal(string calldata URI) external onlyOwner {
        require(!_revealed, "Can't reveal after reveal");
        _revealed = true;
        _baseURIVal = URI;
        currentPhase = CurrentSalePhase.Stopped;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(_revealed) {
            return super.tokenURI(tokenId);
        } else {
            return _prerevealUri;
        }
    }

    function mintAllowlist(uint numberTokensToMint, bytes32[] calldata merkleProof) external payable {
        require(currentPhase == CurrentSalePhase.Phase1_AllowList2 || currentPhase == CurrentSalePhase.Phase2_AllowList3,  "AllowList mint are not allowed on this phase");
        require(numberTokensToMint <= maxMintPerPerson, "Too many tokens requested to be minted"); // instead of safemath
        require(_personMinted[msg.sender] + numberTokensToMint <= maxMintPerPerson, "Too many tokens requested to be minted");
        require(totalSupply() + numberTokensToMint <= TotalSupplyCap, "maximum number of tokens to mint is reached");
        require(msg.value >= numberTokensToMint*allowListPrice, "Insufficient funds provided");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _allowListMerkleRoot, leaf), "invalid allowlist proof");

        _safeMint(msg.sender, numberTokensToMint);
        _personMinted[msg.sender] = _personMinted[msg.sender] + numberTokensToMint; // yep safemath is preferable here but we operate with 2-3 tokens so hopely don't need
    }

    function mint(uint numberTokensToMint) external payable {
        require(currentPhase == CurrentSalePhase.PublicSale,  "public mint is not allowed on this phase");
        require(_personMinted[msg.sender] + numberTokensToMint <= maxMintPerPerson, "Too many tokens requested to be minted");
        require(totalSupply() + numberTokensToMint <= TotalSupplyCap, "maximum number of tokens to mint is reached");
        require(msg.value >= numberTokensToMint*publicSalePrice, "Insufficient funds provided");

        _safeMint(msg.sender, numberTokensToMint);
        _personMinted[msg.sender] = _personMinted[msg.sender] + numberTokensToMint; // yep safemath is preferable here but we operate with 2-3 tokens so hopely don't need
    }

    function getCurrentBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoneyTo(address payable _to, uint amount) public  onlyOwner {
        require(amount <= getCurrentBalance(), "insufficient funds to withdraw");
        _to.transfer(amount);
    }

    function destroy() public  onlyOwner {
        address payable target_address = payable(owner());
        selfdestruct(target_address);
    }
}