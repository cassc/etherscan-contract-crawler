// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BenMezrichProject3 is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint constant public PRICE = 0.06 ether;
    uint MAX_TOKEN_ID = 6000;

    enum MintStatus { Closed, Whitelist, Public }
    MintStatus status;

    bytes32 root;
    string baseURI;
    bool revealed;
    Counters.Counter nextToken;
    mapping (address => bool) public mintedWallets;

    uint royaltyRate = 7_500; 
    uint constant royaltyRateDivisor = 100_000;
    address payable royaltyWallet; 
    
    // CONSTRUCTOR //

    constructor(bytes32 _root, string memory _baseURI, address _royaltyWallet) ERC721("Ben Mezrich Project 3", "BENFT3") {
        root = _root; // 0xd376c951f133c65f70d5890361b6a6a8257904a102c7ac0ebd76ebb9b8d71734
        baseURI = _baseURI; // ipfs://Qma1djqd33xYibVcu2TcJGFrMt3bb6P9av8SKbk6ZFtbGK/
        royaltyWallet = payable(_royaltyWallet); // 0xfe4bcA1F6Cb50e63D6ac7eFD1878e3D9110a8Dde
        for (uint i; i < 100; i++) {
            _mint(_royaltyWallet, nextTokenId());
        }
    }

    // MINT STATUS //

    function openWhitelist() external onlyOwner {
        status = MintStatus.Whitelist;
    }

    function openPublic() external onlyOwner {
        status = MintStatus.Public;
    }

    function closeMinting() external onlyOwner {
        status = MintStatus.Closed;
    }

    function getMintStatus() public view returns (MintStatus) {
        return status;
    }

    // MINTING //

    function whitelistMint(bytes32[] calldata proof, uint quantity) external payable {
        require(status == MintStatus.Whitelist, 'whitelist not open');
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(quantity, msg.sender))), "invalid merkle proof");
        require(!mintedWallets[msg.sender], "already minted"); // one minting tx per wallet
        mintedWallets[msg.sender] = true; // update first to avoid reentrancy
        _mintQuantity(quantity);
    }

    function publicMint(uint quantity) external payable {
        require(status == MintStatus.Public, 'public minting closed');
        _mintQuantity(quantity);
    }

    function _mintQuantity(uint quantity) internal {
        require(nextToken.current() < MAX_TOKEN_ID, "sold out");
        require(msg.value == PRICE * quantity, 'wrong value sent');
        for (uint i; i < quantity; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // URIs //

    function updateBaseURI(string calldata _newBaseURI, bool _revealed) external onlyOwner {
        baseURI = _newBaseURI;
        revealed = _revealed;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) {
            return baseURI;
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }
    }

    // HELPERS //

    function nextTokenId() private returns (uint) {
        nextToken.increment();
        return nextToken.current();
    }

    function updateRoot(bytes32 newRoot) external onlyOwner {
        root = newRoot;
    }

    // EIP 2981 ROYALTIES //

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "nonexistant token");
        uint amountToPay = _salePrice * royaltyRate / royaltyRateDivisor;
        return (royaltyWallet, amountToPay);
    }

    function updateRoyaltyRate(uint256 _rate) external onlyOwner {
        royaltyRate = _rate;
    }

    function updateRoyaltyWallet(address payable _wallet) external onlyOwner {
        royaltyWallet = _wallet;
    }

    // FUND WITHDRAWAL //

    function withdrawToken(address token) external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, 'transfer unsuccessful');
    }
}