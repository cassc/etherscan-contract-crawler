// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract B3ARMARKETisERC721A is ERC721A, Ownable, PaymentSplitter  {
    using Strings for uint;

    enum Step {
        SaleNotStarted,
        OGSale,
        WhitelistSale,
        PublicSale,
        FreeMint,
        SoldOut
    }

    Step public currentStep;

    bytes32 public ogMerkleRoot;    // OG merkle root
    bytes32 public wlMerkleRoot;    // Whitelist merkle root
    bytes32 public fmMerkleRoot;    // FreeMint merkle root

    uint public wlPrice = 0.00625 ether;
    uint public publicPrice = 0.0125 ether;

    mapping(address => uint) public mintByWalletOG;
    mapping(address => uint) public mintByWalletWL;
    mapping(address => uint) public mintByWalletFM;

    uint public constant sale_supply = 192;
    uint public constant total_supply = 222;

    string public baseURI;

    event stepUpdated(Step currentStep);
    event newMint(address indexed owner, uint256 startId, uint256 number);

    /*
    * @notice Initializes the contract with the given parameters.
    * @param baseURI The base token URI of the token.
    * @param rootOfMerkle The root of the merkle tree.
    * @param teamMembers The team members of the token.
    */
    constructor(string memory _baseURI, bytes32 _ogMerkleRoot, bytes32 _wlMerkleRoot, bytes32 _fmMerkleRoot, address[] memory _team, uint[] memory _teamShares)
    ERC721A("B3AR MARKET", "B3AR")
    PaymentSplitter(_team, _teamShares)
    {
        baseURI = _baseURI;
        ogMerkleRoot = _ogMerkleRoot;
        wlMerkleRoot = _wlMerkleRoot;
        fmMerkleRoot = _fmMerkleRoot;
    }

    /*
    * @notice Modifier to check if the sender is not a contract
    */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /*
    * @notice OG mint function
    * @param _proof Merkle Proof for OG
    */
    function OGMint(bytes32[] calldata _proof) external payable callerIsUser {
        require(currentStep == Step.OGSale || msg.sender == owner(), "The OG sale is not open.");
        require(isOG(msg.sender, _proof), "Not OG.");
        require(mintByWalletOG[msg.sender] + 1 <= 1, "You can only mint 1 NFT with OG role");
        require(totalSupply() + 1 <= sale_supply, "Max supply exceeded");
        require(msg.value >= wlPrice, "Not enough ETH");
        mintByWalletOG[msg.sender] += 1;
        _safeMint(msg.sender, 1);
        emit newMint(msg.sender, totalSupply() - 1, 1);
    }

    /*
    * @notice WL mint function
    * @param _proof Merkle Proof for WL
    * @param _amount The amount of tokens to mint. (max 2)
    */
    function WLMint(bytes32[] calldata _proof, uint256 _amount) external payable callerIsUser {
        require(currentStep == Step.WhitelistSale, "The WL sale is not open.");
        require(isWhitelisted(msg.sender, _proof), "Not WL.");
        require(mintByWalletWL[msg.sender] + _amount <= 2, "You can only mint 2 NFTs with WL role");
        require(totalSupply() + _amount <= sale_supply, "Max supply exceeded");
        require(msg.value >= wlPrice * _amount, "Not enough ETH");
        mintByWalletWL[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
        emit newMint(msg.sender, totalSupply() - _amount, _amount);
    }

    /*
    * @notice public mint function
    * @param _amount The amount of tokens to mint. (no limit)
    */
    function PublicMint(uint256 _amount) external payable callerIsUser {
        require(currentStep == Step.PublicSale, "The public sale is not open.");
        require(totalSupply() + _amount <= sale_supply, "Max supply exceeded");
        require(msg.value >= publicPrice * _amount, "Not enough ETH");
        _safeMint(msg.sender, _amount);
        emit newMint(msg.sender, totalSupply() - _amount, _amount);
    }

    /*
    * @notice FreeMint mint function
    * @param _proof Merkle Proof for FreeMint
    */
    function FreeMint(bytes32[] calldata _proof) external callerIsUser {
        require(currentStep == Step.FreeMint, "The FreeMint sale is not open.");
        require(isFreeMint(msg.sender, _proof), "You don't have Free mint.");
        require(totalSupply() + 1 <= total_supply, "Max supply exceeded");
        require(mintByWalletFM[msg.sender] + 1 <= 1, "You can only mint 1 NFT with FreeMint role");
        mintByWalletFM[msg.sender] += 1;
        _safeMint(msg.sender, 1);
        emit newMint(msg.sender, totalSupply() - 1, 1);
    }


    /*
    * @notice Owner mint function (WILL BE NEVER USED IF USERS CLAIM THEIR FREE MINTS
    * @param _count The number of NFTs to mint
    * @param _to The address to mint the NFTs to
    */
    function mintForOwner(uint _count, address _to) external onlyOwner {
        require(totalSupply() + _count  <= total_supply, "Max supply exceeded.");
        _safeMint(_to, _count);
        emit newMint(_to, totalSupply() - _count, _count);
    }

    /*
    * @notice update step
    * @param _step step to update
    */
    function updateStep(Step _step) external onlyOwner {
        currentStep = _step;
        emit stepUpdated(currentStep);
    }

    /*
    * @notice set base token URI
    * @param _baseURI string
    */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /*
    * @notice set wl merkle root
    * @param _merkleRoot bytes32
    */
    function setOGMerkleRoot(bytes32 _ogMerkleRoot) public onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    /*
    * @notice set wl merkle root
    * @param _merkleRoot bytes32
    */
    function setWlMerkleRoot(bytes32 _wlMerkleRoot) public onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    /*
    * @notice set fm merkle root
    * @param _merkleRoot bytes32
    */
    function setFMMerkleRoot(bytes32 _fmMerkleRoot) public onlyOwner {
        fmMerkleRoot = _fmMerkleRoot;
    }

    /*
    * @notice return token URI
    * @param _tokenId uint256 id of token
    */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /*
    * @notice return current price
    */
    function getPrice() public view returns (uint) {
        if (currentStep == Step.WhitelistSale || currentStep == Step.OGSale) {
            return wlPrice;
        } else {
            return publicPrice;
        }
    }

    /*
    * @notice know if user is OG
    * @param _account address of user
    * @param proof Merkle proof
    */
    function isOG(address _account, bytes32[] calldata proof) public view returns(bool) {
        return _verifyOG(_leaf(_account), proof);
    }

    /*
    * @notice know if user is whitelisted
    * @param _account address of user
    * @param proof Merkle proof
    */
    function isWhitelisted(address _account, bytes32[] calldata proof) public view returns(bool) {
        return _verifyWL(_leaf(_account), proof);
    }

    /*
    * @notice know if user is free mint
    * @param _account address of user
    * @param proof Merkle proof
    */
    function isFreeMint(address _account, bytes32[] calldata proof) public view returns(bool) {
        return _verifyFM(_leaf(_account), proof);
    }

    /*
    * @notice get merkle _leaf
    * @param _account address of user
    */
    function _leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }


    /*
    * @notice verify if user is whitelisted OG
    * @param leaf bytes32 leaf of merkle tree
    * @param proof bytes32 Merkle proof
    */
    function _verifyOG(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, ogMerkleRoot, leaf);
    }

    /*
    * @notice verify if user is whitelisted
    * @param leaf bytes32 leaf of merkle tree
    * @param proof bytes32 Merkle proof
    */
    function _verifyWL(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, wlMerkleRoot, leaf);
    }

    /*
    * @notice verify if user is free mint
    * @param leaf bytes32 leaf of merkle tree
    * @param proof bytes32 Merkle proof
    */
    function _verifyFM(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, fmMerkleRoot, leaf);
    }
}