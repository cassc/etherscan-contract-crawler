// contracts/PMV.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Optimized.sol";
import "./PMVMixin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract PiratesOfTheMetaverse is PMVMixin, ERC721Optimized, VRFConsumerBase {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    mapping (address => uint256) public presaleMints;
    mapping (address => uint256) public freeMints;
    bytes32 private s_keyHash;
    uint256 private s_fee;
    bool public allowBurning = false;

    constructor(bytes32 merkleroot, string memory uri, bytes32 _rootMintFree,
                bytes32 _provenanceHash, address vrfCoordinator,
                address link, bytes32 keyhash, uint256 fee, address _multiSigWallet) ERC721Optimized("Pirates of the Metaverse", "POMV") VRFConsumerBase(vrfCoordinator, link){
        root = merkleroot;
        notRevealedUri = uri;
        rootMintFree = _rootMintFree;
        provenanceHash = _provenanceHash;
        s_keyHash = keyhash;
        s_fee = fee;
        multiSigWallet = _multiSigWallet;
     }

    function mintPresale(uint256 allowance, bytes32[] calldata proof, uint256 tokenQuantity) external payable {
        require(presaleActive, "PRESALE NOT ACTIVE");
        require(proof.verify(root, keccak256(abi.encodePacked(msg.sender, allowance))), "NOT ON ALLOWLIST");
        require(presaleMints[msg.sender] + tokenQuantity <= allowance, "MINTING MORE THAN ALLOWED");

        uint256 currentSupply = totalNonBurnedSupply();

        require(tokenQuantity + currentSupply <= maxSupply, "NOT ENOUGH LEFT IN STOCK");
        require(tokenQuantity * presalePrice <= msg.value, "INCORRECT PAYMENT AMOUNT");

        for(uint256 i = 1; i <= tokenQuantity; i++) {
            _mint(msg.sender, currentSupply + i);
        }

        presaleMints[msg.sender] += tokenQuantity;
    }

    function mintFree(uint256 allowance, bytes32[] calldata proof, uint256 tokenQuantity) external {
        require(presaleActive, "Free mint not allowed");
        require(proof.verify(rootMintFree, keccak256(abi.encodePacked(msg.sender, allowance))), "NOT ON FREE MINT ALLOWLIST");
        require(freeMints[msg.sender] + tokenQuantity <= allowance, "MINTING MORE THAN ALLOWED");

        uint256 currentSupply = totalNonBurnedSupply();

        require(tokenQuantity + currentSupply <= maxSupply, "NOT ENOUGH LEFT IN STOCK");

        for(uint256 i = 1; i <= tokenQuantity; i++) {
            _mint(msg.sender, currentSupply + i);
        }

        freeMints[msg.sender] += tokenQuantity;
    }

    function mint(uint256 tokenQuantity) external payable {
        if (!letContractMint){
            require(msg.sender == tx.origin, "CONTRACT NOT ALLOWED TO MINT IN PUBLIC SALE");
        }
        require(saleActive, "SALE NOT ACTIVE");
        require(tokenQuantity <= maxPerTransaction, "MINTING MORE THAN ALLOWED IN A SINGLE TRANSACTION");

        uint256 currentSupply = totalNonBurnedSupply();

        require(tokenQuantity + currentSupply <= maxSupply, "NOT ENOUGH LEFT IN STOCK");
        require(tokenQuantity * salePrice <= msg.value, "INCORRECT PAYMENT AMOUNT");

        for(uint256 i = 1; i <= tokenQuantity; i++) {
            _mint(msg.sender, currentSupply + i);
        }
    }

    function ownerMint(uint256 tokenQuantity) external onlyOwner {
        uint256 currentSupply = totalNonBurnedSupply();
        require(tokenQuantity + currentSupply <= ownerMintBuffer, "NOT ENOUGH LEFT IN STOCK");

        for(uint256 i = 1; i <= tokenQuantity; i++) {
            _mint(multiSigWallet, currentSupply + i);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _tokenURI(tokenId);
    }

    function generateRandomOffset() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");
        require(!offsetRequested, "Already generated random offset");
        requestId = requestRandomness(s_keyHash, s_fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // transform the result to a number between 0 and 9,997 inclusively
        // token 1 and 2 are fixed and are not included for purposes of offsetting
        uint256 newOffset = (randomness % (maxSupply - 2));
        offset = newOffset;
        offsetRequested = true;
    }

    function setAllowBurning(bool _allowBurning) external onlyOwner {
        allowBurning = _allowBurning;
    }

    function burn(uint256 tokenId) public virtual {
        require(allowBurning, "Burning not currently allowed");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

}