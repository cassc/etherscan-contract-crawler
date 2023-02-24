// SPDX-License-Identifier: MIT

/*
    
 .----------------.  .----------------.  .----------------.  .----------------.   .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. | | .--------------. || .--------------. |
| |      __      | || |  _______     | || |  _________   | || |      __      | | | |    ______    | || |     __       | |
| |     /  \     | || | |_   __ \    | || | |_   ___  |  | || |     /  \     | | | |  .' ____ \   | || |    /  |      | |
| |    / /\ \    | || |   | |__) |   | || |   | |_  \_|  | || |    / /\ \    | | | |  | |____\_|  | || |    `| |      | |
| |   / ____ \   | || |   |  __ /    | || |   |  _|  _   | || |   / ____ \   | | | |  | '____`'.  | || |     | |      | |
| | _/ /    \ \_ | || |  _| |  \ \_  | || |  _| |___/ |  | || | _/ /    \ \_ | | | |  | (____) |  | || |    _| |_     | |
| ||____|  |____|| || | |____| |___| | || | |_________|  | || ||____|  |____|| | | |  '.______.'  | || |   |_____|    | |
| |              | || |              | || |              | || |              | | | |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' | | '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'   '----------------'  '----------------' 

*/

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IERC20 {
    function transferFrom( address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract Area61 is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    IERC20 public D = IERC20(0x2634662D652Ae9e68e3002Ec2DfcF3A8B80C8F90);
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    //colletction details
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    //mint details, control variables
    uint256 public cost; 
    uint256 public maxSupply;
    uint256 public mintMaxSupply;
    uint256 public burnCount;
    uint256 public maxMintAmountPerTx;
    uint256 public D_PRICE; //decimals are 18
    bool public Phase1paused = true; 
    bool public Phase2paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= mintMaxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    constructor(
        uint256 _cost,
        uint256 _d_price,
        uint256 _maxMintAmountPerTx,
        uint256 _maxSupply,
        uint256 _mintMaxSupply
    ) ERC721A("Area 61", "Aliens") {
        setCost(_cost);
        setDcost(_d_price);
        maxMintAmountPerTx = _maxMintAmountPerTx;
        maxSupply = _maxSupply;
        mintMaxSupply = _mintMaxSupply;
    }

    /*
     * Mint functions
     */
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid proof!");

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!Phase1paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintDNA(uint256 _mintAmount) public mintCompliance(_mintAmount) {
        require(!Phase2paused, "The contract is paused!");

        D.transferFrom(_msgSender(), address(this), D_PRICE * _mintAmount);
        _safeMint(_msgSender(), _mintAmount);
    }

    /*
     * Utility functions
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        burnCount++;
        _burn(tokenId);
    }

    function mintMany(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
        require(addresses.length == count.length, "mismatching lengths!");

        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], count[i]);
        }
        require(totalSupply() <= maxSupply, "Exceed MAX_SUPPLY");
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

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

    /*
     * Setters
     */
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setDcost(uint256 _d_price) public onlyOwner {
        D_PRICE = _d_price;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPhase1Paused(bool _state) public onlyOwner {
        Phase1paused = _state;
    }

    function setPhase2Paused(bool _state) public onlyOwner {
        Phase2paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawDna() external onlyOwner {
        uint256 D_BALANCE = D.balanceOf(address(this));
        D.transfer(msg.sender, D_BALANCE);
    }

    receive() external payable {}
}