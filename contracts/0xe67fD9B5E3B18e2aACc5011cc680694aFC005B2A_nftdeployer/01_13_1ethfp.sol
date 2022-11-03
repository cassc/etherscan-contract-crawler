// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract nftdeployer is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public cost = 0 ether;

    address public constant multisig = 0x59A32f97EDC24B5ec4aD2025B23BEB16Bd78bD30;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("1 ETH FP - PH2", "1ETHFP2"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "1 ETH FP - PH2 :: Cannot be called by a contract");
        _;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply!");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Already minted!");
        require(msg.value >= (cost * _quantity), "Below mint price!");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] calldata __merkleProof, uint64 maxAllowanceToMint, uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "Minting is on Pause");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= maxAllowanceToMint, "Cannot mint beyond allowance!");
        require(msg.value >= (cost * _quantity), "Payment is below the price");
        //create leaf node
        bytes32 leaf = keccak256(abi.encode(msg.sender, maxAllowanceToMint));
        require(MerkleProof.verify(__merkleProof, merkleRoot, leaf) == true, "Wrong merkle proof");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "Alert :: Team already minted");
        teamMinted = true;
        _safeMint(multisig, 250);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}