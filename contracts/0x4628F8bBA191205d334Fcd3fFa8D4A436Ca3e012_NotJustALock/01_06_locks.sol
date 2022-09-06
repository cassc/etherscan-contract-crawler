// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NotJustALock is ERC721A, Ownable {
    enum SaleStatus {
        PAUSED,
        ALLOWLIST,
        PUBLIC
    }

    SaleStatus public saleStatus = SaleStatus.PAUSED;

    string private baseURI;
    uint256 private constant PRICE_LOCKS = 0 ether;
    uint256 private constant MAX_LOCKS = 5555;


    bytes32 public merkleRoot;

    address private unlockContract;
    mapping(address => bool) public publicSaleMinted;
    mapping(address => uint256) public quantityMintedPrivate;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(string memory baseTokenURI, bytes32 _merkleRoot)
        ERC721A("NotJustALock", "LOCK")
    {
        baseURI = baseTokenURI;
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function mintPrivate(uint256 quantity, uint256 allowedQuantity, bytes32[] calldata proof) public payable callerIsUser {
        require(saleStatus == SaleStatus.ALLOWLIST, "PRIVATE SALE NOT ACTIVE");
        require(msg.value >= PRICE_LOCKS * quantity, "INCORRECT ETH SENT");
        require(canMintPrivate(msg.sender, allowedQuantity, proof), "FAILED WALLET VERIFICATION");
        require(quantityMintedPrivate[msg.sender] + quantity <= allowedQuantity, "EXCEEDS ALLOWED QUANTITY");

        quantityMintedPrivate[msg.sender] = quantityMintedPrivate[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
    }

    function mintPublic() public callerIsUser {
        require(saleStatus == SaleStatus.PUBLIC, "PUBLIC SALE NOT ACTIVE");
        require(_totalMinted() < MAX_LOCKS, "EXCEEDS SUPPLY");
        require(!publicSaleMinted[msg.sender], "ALREADY MINTED PUBLIC");

        publicSaleMinted[msg.sender] = true;

        _safeMint(msg.sender, 1);
    }

    function canMintPrivate(address account, uint256 allowedQuantity, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, generateMerkleLeaf(account, allowedQuantity));
    }

    function generateMerkleLeaf(address account, uint256 allowedQuantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allowedQuantity));
    }

    function setSaleStatus(SaleStatus _status) external onlyOwner {
        saleStatus = _status;
    }

    function setUnlockContract(address _unlockContract) external onlyOwner {
        unlockContract = _unlockContract;
    }

    function getPublicMintedForAddress(address account) public view returns (bool) {
        return publicSaleMinted[account];
    }

    function getPrivateMintedForAddress(address account) public view returns (uint256) {
        return quantityMintedPrivate[account];
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        if (address(unlockContract) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}