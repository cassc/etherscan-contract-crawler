// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract PeculiarPugs {
    function reveal() public virtual;
    function setCost(uint256 _newCost) public virtual;
    function setNotRevealedURI(string memory _notRevealedURI) public virtual;
    function setBaseURI(string memory _newBaseURI) public virtual;
    function setBaseExtension(string memory _newBaseExtension) public virtual;
    function pause(bool _state) public virtual;
    function withdraw() public payable virtual;
    function mint(uint256 _mintAmount) public payable virtual;
    function cost() public virtual returns(uint256);
    function totalSupply() public virtual returns(uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
    function transferOwnership(address newOwner) public virtual;
}

abstract contract PeculiarPugsRewards {
    function grantReward(address holder, uint256 tokenId, uint256 amount) external virtual;
    function burnReward(address holder, uint256 tokenId, uint256 amount) external virtual;
    function balanceOf(address account, uint256 id) external virtual returns (uint256);
}


contract PeculiarPugsWL is Ownable, IERC721Receiver {

    PeculiarPugs pugsContract;
    PeculiarPugsRewards rewardsContract;

    mapping(uint256 => uint256) public rewardTokenDiscount;
    bool public mintRewardActive = true; 
    uint256 public mintRewardTokenId = 1991;
    uint256 public mintRewardQuantity = 1;
    uint256 public wlMintPrice = 0.03 ether;
    bytes32 public merkleRoot;

    error InsufficientPayment();
    error RefundFailed();

    constructor(address pugsAddress, address rewardsAddress) {
        pugsContract = PeculiarPugs(pugsAddress);
        rewardsContract = PeculiarPugsRewards(rewardsAddress);
    }

    receive() external payable { }
    fallback() external payable { }

    function wlMint(uint256 count, bytes32[] calldata proof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle proof");

        uint256 totalCost = wlMintPrice * count;
        uint256 startTokenId = pugsContract.totalSupply() + 1;
        uint256 endTokenId = startTokenId + count - 1;
        pugsContract.mint{value: 0}(count);
        for(uint256 tokenId = startTokenId; tokenId <= endTokenId;tokenId++) {
            pugsContract.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        if(mintRewardActive) {
            rewardsContract.grantReward(msg.sender, mintRewardTokenId, mintRewardQuantity * count);
        }

        refundIfOver(totalCost);
    }

    function mintWithRewards(uint256 count, uint256[] calldata rewardTokenIds, uint256[] calldata rewardTokenAmounts) external payable {
        require(rewardTokenIds.length == rewardTokenAmounts.length);
        uint256 totalCost = pugsContract.cost() * count;
        uint256 totalDiscount = 0;
        for(uint256 i = 0;i < rewardTokenIds.length;i++) {
            totalDiscount += (rewardTokenDiscount[rewardTokenIds[i]] * rewardTokenAmounts[i]);
        }
        require(totalCost >= totalDiscount);
        for(uint256 i = 0;i < rewardTokenIds.length;i++) {
            rewardsContract.burnReward(msg.sender, rewardTokenIds[i], rewardTokenAmounts[i]);
        }
        uint256 startTokenId = pugsContract.totalSupply() + 1;
        uint256 endTokenId = startTokenId + count - 1;
        pugsContract.mint{value: 0}(count);
        for(uint256 tokenId = startTokenId; tokenId <= endTokenId;tokenId++) {
            pugsContract.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        refundIfOver((totalCost - totalDiscount));
    }

    function mintForRewards(uint256 count) external payable {
        uint256 totalCost = pugsContract.cost() * count;
        uint256 startTokenId = pugsContract.totalSupply() + 1;
        uint256 endTokenId = startTokenId + count - 1;
        pugsContract.mint{value: 0}(count);
        for(uint256 tokenId = startTokenId; tokenId <= endTokenId;tokenId++) {
            pugsContract.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        if(mintRewardActive) {
            rewardsContract.grantReward(msg.sender, mintRewardTokenId, mintRewardQuantity * count);
        }
        refundIfOver(totalCost);
    }

    function ownerMint(uint256 count, address to) external onlyOwner {
        uint256 startTokenId = pugsContract.totalSupply() + 1;
        uint256 endTokenId = startTokenId + count - 1;
        pugsContract.mint{value: 0}(count);
        for(uint256 tokenId = startTokenId; tokenId <= endTokenId;tokenId++) {
            pugsContract.safeTransferFrom(address(this), to, tokenId);
        }
    }

    /**
     * @notice Refund for overpayment on rental and purchases
     * @param price cost of the transaction
     */
    function refundIfOver(uint256 price) private {
        if(msg.value < price) { revert InsufficientPayment(); }
        if (msg.value > price) {
            (bool sent, ) = payable(msg.sender).call{value: (msg.value - price)}("");
            if(!sent) { revert RefundFailed(); }
        }
    }

    function onERC721Received(address _operator, address, uint, bytes memory) public virtual override returns (bytes4) {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return IERC721Receiver.onERC721Received.selector;
    }

    function setRewardTokenDiscount(uint256 rewardTokenId, uint256 discount) external onlyOwner {
        rewardTokenDiscount[rewardTokenId] = discount;
    }

    function setMintReward(bool _active, uint256 _tokenId, uint256 _quantity) external onlyOwner {
        mintRewardActive = _active;
        mintRewardTokenId = _tokenId;
        mintRewardQuantity = _quantity;
    }

    function setWLMintPrice(uint256 _price) external onlyOwner {
        wlMintPrice = _price;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setContractAddresses(address pugsAddress, address rewardsAddress) external onlyOwner {
        pugsContract = PeculiarPugs(pugsAddress);
        rewardsContract = PeculiarPugsRewards(rewardsAddress);
    }

    function reveal() public onlyOwner {
        pugsContract.reveal();
    }
  
    function setCost(uint256 _newCost) public onlyOwner {
        pugsContract.setCost(_newCost);
    }
  
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        pugsContract.setNotRevealedURI(_notRevealedURI);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        pugsContract.setBaseURI(_newBaseURI);
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        pugsContract.setBaseExtension(_newBaseExtension);
    }

    function pause(bool _state) public onlyOwner {
        pugsContract.pause(_state);
    }

    function transferPugsOwnership(address newOwner) public onlyOwner {
        pugsContract.transferOwnership(newOwner);
    }
 
    function withdraw() public payable onlyOwner {
        pugsContract.withdraw();
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}