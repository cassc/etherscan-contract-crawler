// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

    error NotInWhitelist();

contract NftFragmentTransfer is ERC721A, ERC721Holder, Ownable, Pausable {
    IERC721A public nftToken;
    address private immutable _wallet;
    uint256 public mintPrice;
    bytes32 private _merkleRoot;
    address public _address_5 = 0xa106bFed8dC68537953e3FdAf9DfD878Bb143066;
    address public _address_95 = 0x5D8912fEBD1Ae3b44a15629BE43EAd349aDb98a4;
    mapping(address => uint256) private _walletMintCount;


    constructor(
        string memory _name,
        string memory _symbol,
        address wallet_,
        bytes32 merkleRoot,
        uint256 _mintPrice,
        address nft_
    ) ERC721A(_name, _symbol) {
        nftToken = IERC721A(nft_);
        _wallet = wallet_;
        mintPrice = _mintPrice;
        _merkleRoot = merkleRoot;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function getCountWalletNft() public view returns (uint) {
        return _walletMintCount[_msgSender()];
    }

    function mint(uint256 _tokenId, bytes32[] calldata _merkleProof) public whenNotPaused payable validateProof(_merkleProof){
        require(getCountWalletNft() < 1, "You cant by nft.");
        require(msg.value >= mintPrice, "Not enough ethers to buy");
        _walletMintCount[_msgSender()] = 1;
        nftToken.transferFrom(address(this), _msgSender(), _tokenId);
    }

    function setCountWalletNft(address _to) public payable onlyOwner{
        _walletMintCount[_to] = 0;
    }

    modifier validateProof(bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, _merkleRoot, leaf)) {
            revert NotInWhitelist();
        }
        _;
    }

    function withdraw() public onlyOwner {
        uint bal = address(this).balance;
        uint _5_expenses = bal / 20; // 1/20 = 5%
        bal = bal -_5_expenses;

        require(payable(_address_5).send(_5_expenses));
        require(payable(_address_95).send(bal));
    }
}