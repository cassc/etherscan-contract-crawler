// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import '@openzeppelin/contracts/security/Pausable.sol';

/*
* @title ERC721 token for Comic 2
*/
contract Comic2 is ERC721Enumerable, ERC721Burnable, Ownable, Pausable {
    string public ipfsLink;

    uint256 claimWindowOpens;
    uint256 claimWindowCloses;
    uint256 daoWindowOpens;
    uint256 holdersWindowOpens;
    uint256 purchaseWindowOpens;

    uint256 constant MAX_PURCHASE = 9604;
    uint256 constant MAX_OWNER = 400;
    uint256 constant MAX_PURCHASE_PER_TX = 20;

    uint256 ownerSupply;

    bool isSaleClosed;
    bool isClaimClosed;

    bytes32 merkleRoot;
    mapping(address => uint256) claimed;

    address immutable comicContract;
    address immutable founderDAOContract;
    address immutable comicSEContract;
    address immutable metaHeroContract;
    address immutable metaHeroCoreContract;
    address immutable planetsContract;
    address immutable mintPassContract;

    address immutable comicStakingContract;
    address immutable comicSEStakingContract;
    address immutable metaHeroStakingContract;
    address immutable metaHeroCoreStakingContract;

    uint256 mintPrice = 100000000000000000;

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _ipfsLink,
        bytes32 _merkleRoot,
        uint256 _purchaseWindowOpens,
        uint256 _daoWindowOpens,
        uint256 _holderWindowOpens,
        uint256 _claimWindowOpens,
        uint256 _claimWindowCloses,
        address[] memory _contracts
    ) ERC721(_name, _symbol) {
        ipfsLink = _ipfsLink;

        merkleRoot = _merkleRoot;

        claimWindowOpens = _claimWindowOpens;
        claimWindowCloses = _claimWindowCloses;
        purchaseWindowOpens = _purchaseWindowOpens;
        daoWindowOpens = _daoWindowOpens;
        holdersWindowOpens = _holderWindowOpens;

        comicContract = _contracts[0];
        comicSEContract = _contracts[1];
        founderDAOContract = _contracts[2];
        metaHeroContract = _contracts[3];
        metaHeroCoreContract = _contracts[4];
        planetsContract = _contracts[5];
        mintPassContract = _contracts[6];

        comicStakingContract = _contracts[7];
        comicSEStakingContract = _contracts[8];
        metaHeroStakingContract = _contracts[9];
        metaHeroCoreStakingContract = _contracts[10];
    }

    /**
     * @notice Checks if purchasing window for current buyer has already opened
     */
    modifier whenEligible() {
        require(isEligible(msg.sender), "Purchase: window not open");
        _;
    }

    function isEligible(address user) public view returns (bool) {
        return (
            purchaseWindowOpens <= block.timestamp ||
            (IERC721(founderDAOContract).balanceOf(user) > 0 && block.timestamp >= daoWindowOpens) ||
            (StakingContract(metaHeroStakingContract).stakedTokensOf(user).length > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC721(metaHeroContract).balanceOf(user) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(mintPassContract).balanceOf(user, 0) > 0 && block.timestamp >= holdersWindowOpens)||
            (StakingContract(comicStakingContract).stakedTokensOf(user).length > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC721(comicContract).balanceOf(user) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 5) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 6) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 7) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 8) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 2) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 1) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 4) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 0) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 10) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 9) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC1155(planetsContract).balanceOf(user, 3) > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC721(metaHeroCoreContract).balanceOf(user) > 0 && block.timestamp >= holdersWindowOpens) ||
            (StakingContract(metaHeroCoreStakingContract).stakedTokensOf(user).length > 0 && block.timestamp >= holdersWindowOpens) ||
            (StakingContract(comicSEStakingContract).stakedTokensOf(user).length > 0 && block.timestamp >= holdersWindowOpens) ||
            (IERC721(comicSEContract).balanceOf(user) > 0 && block.timestamp >= holdersWindowOpens)
          );
    }


    function setMetadata(string calldata _ipfsLink) external onlyOwner {
        ipfsLink = _ipfsLink;
    }

    function ownerMint (address to, uint256 amount) external onlyOwner {
        require(ownerSupply + amount <= MAX_OWNER, "max owner supply exceeded");

        ownerSupply += amount;

        for(uint256 i; i < amount; i++) {
            _mint(to, totalSupply() + 1);
        }
    }

    function purchase(uint256 amount) external payable whenEligible whenNotPaused {
        require(!isSaleClosed, "Purchase: is closed");
        require(msg.value == mintPrice * amount, "Purchase: payment incorrect");
        require(totalSupply() + amount <= MAX_PURCHASE, "Purchase: max purchase supply exceeded");
        require(amount <= MAX_PURCHASE_PER_TX, "Purchase: max purchase amount exceeded");

        for(uint256 i; i < amount; i++) {
            _mint(msg.sender, totalSupply() + 1);
        }
    }

    /**
    * @notice free claim for minters of first edition
    *
    * @param amount the amount of comics to claim
    * @param index the index of the merkle proof
    * @param maxAmount the max amount of comics sender is eligible to claim
    * @param merkleProof the valid merkle proof of sender
    */
    function claim(
        uint256 amount,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(!isClaimClosed, "Claim: is closed");
        require (block.timestamp >= claimWindowOpens && block.timestamp <= claimWindowCloses, "Claim: window closed");
        require(claimed[msg.sender] + amount <= maxAmount, "Claim: amount exceeded");

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, maxAmount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        claimed[msg.sender] = claimed[msg.sender] + amount;

        for(uint256 i; i < amount; i++) {
            _mint(msg.sender, totalSupply() + 1);
        }
    }


    /**
    * @notice set merkle root
    *
    * @param _merkleRoot the merkle root to verify eligile claims
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    * @notice edit windows for claiming
    *
    * @param _purchaseWindowOpens UNIX timestamp for general purchase window opening time
    * @param _daoWindowOpens UNIX timestamp for Founders DAO holder opening time
    * @param _holderWindowOpens UNIX timestamp for PV NFT holder opening time
    *
    */
    function editSaleWindows(
        uint256 _purchaseWindowOpens,
        uint256 _daoWindowOpens,
        uint256 _holderWindowOpens
    ) external onlyOwner {
        purchaseWindowOpens = _purchaseWindowOpens;
        daoWindowOpens = _daoWindowOpens;
        holdersWindowOpens = _holderWindowOpens;
    }

    /**
    * @notice edit windows for claiming
    *
    * @param _claimWindowOpens UNIX timestamp for claim window opening time
    * @param _claimWindowCloses UNIX timestamp for claim window closing time
    *
    */
    function editClaimWindows(
        uint256 _claimWindowOpens,
        uint256 _claimWindowCloses
    ) external onlyOwner {
        claimWindowOpens = _claimWindowOpens;
        claimWindowCloses = _claimWindowCloses;
    }

    /**
    * @notice set mint price
    *
    * @param _mintPrice mint price in wei
    */
    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
    * @notice close comic sale
    */
    function closeSale() external onlyOwner {
        require(!isSaleClosed, "CloseSale: already closed");

        isSaleClosed = true;
    }

    /**
    * @notice close comic claims
    */
    function closeClaim() external onlyOwner {
        require(!isClaimClosed, "CloseClaim: already closed");

        isClaimClosed = true;
    }

    /**
    * @notice pause sales
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @notice unpause sales
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawEther(address payable _to, uint256 _amount) external onlyOwner {
        _to.transfer(_amount);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return ipfsLink;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

 interface StakingContract {
    function stakedTokensOf(address account) external view returns (uint256[] memory);
 }