// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * __  .______    __    __  .___________.    _______. __    __
 * |  | |   _  \  |  |  |  | |           |   /       ||  |  |  |   
 * |  | |  |_)  | |  |  |  | `---|  |----`  |   (----`|  |  |  |
 * |  | |   _  <  |  |  |  |     |  |        \   \    |  |  |  |
 * |  | |  |_)  | |  `--"  |     |  |    .----)   |   |  `--"  |
 * |__| |______/   \______/      |__|    |_______/     \______/
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//Contract for Relics Pre-Mint 
contract IbutsuPreMint is Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public totalSupply;
    uint256 public maxMintAmountPerTx;

    address[] mintAddress;
    mapping(address => uint256) public mintDetail;

    bool public paused = false;

    constructor(uint256 _cost, uint256 _maxSupply, uint256 _maxPreMintAmountPerTx, bytes32 _merkleRoot) {
        setCost(_cost);
        setMaxSupply(_maxSupply);
        setMaxMintAmountPerTx(_maxPreMintAmountPerTx);
        setMerkleRoot(_merkleRoot);
    }

    modifier amountCompliance(uint256 _mintAmount) {
        // mint amount > 0 and mint amount <= max per tx
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount");
        // mint amount no bigger than maxSupply
        require(_mintAmount + totalSupply <= maxSupply, "Max supply exceeded");
        // each wallet can mint only once
        require(mintDetail[_msgSender()] == 0, "Already pre-minted");
        _;
    }

    modifier priceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds");
        _;
    }

    function preMint(uint256 _mintAmount) public payable onlyOwner amountCompliance(_mintAmount) {
        require(!paused, "The contract is paused");
        updateMintRecord(_mintAmount);
    }

    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable amountCompliance(_mintAmount) priceCompliance(_mintAmount) {
        require(!paused, "The contract is paused");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Not in the whitelist.");

        updateMintRecord(_mintAmount);
    }

    function updateMintRecord(uint256 _mintAmount) private {
        mintDetail[_msgSender()] = _mintAmount;
        totalSupply += _mintAmount;
        mintAddress.push(_msgSender());
    }

    // getter
    function listMintAddresses() public view returns (address[] memory) {
        return mintAddress;
    }

    function getMintAddress(uint256 index) public view returns (address) {
        if (index >= 0 && index < mintAddress.length) {
            return mintAddress[index];
        }
        return address(0);
    }

    function getMintConfig() public view returns (bool, uint256, uint256, uint256, uint256, uint256) {
        return (paused, cost, maxMintAmountPerTx, maxSupply, totalSupply, mintDetail[_msgSender()]);
    }

    function remainSupply() public view returns(uint256) {
        return maxSupply - totalSupply;
    }

    // setter
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function reset() public {
        for (uint256 i = 0; i < mintAddress.length; i++) {
            delete mintDetail[mintAddress[i]];
        }
        delete mintAddress;
        delete totalSupply;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool ok1, ) = payable(0x1b63B4Cd25F2f5C4295b0FC5E38CD6AEDd842BbF).call{value: address(this).balance * 90 / 100}('');
        require(ok1);

        (bool ok2, ) = payable(0xe49A81b03659F755B0a9098F1F4466987E27D726).call{value: address(this).balance * 10 / 100}('');
        require(ok2);

        (bool ok3,) = payable(owner()).call{value: address(this).balance}("");
        require(ok3);
    }
}