// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

      /$$$$$$   /$$$$$$  /$$      /$$
     /$$__  $$ /$$__  $$| $$$    /$$$
    |__/  \ $$| $$  \__/| $$$$  /$$$$
       /$$$$$/| $$ /$$$$| $$ $$/$$ $$
      |___  $$| $$|_  $$| $$  $$$| $$
     /$$  \ $$| $$  \ $$| $$\  $ | $$
    |  $$$$$$/|  $$$$$$/| $$ \/  | $$
    \______/  \______/ |__/     |__/


    ** Website
       https://3gm.dev/

    ** Twitter
       https://twitter.com/3gmdev

**/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ArtForZombies is ERC721A, Ownable {

    string public baseURI = "";
    string public contractURI = "";
    uint256 constant public MAX_SUPPLY = 1024;
    bytes32 public whitelistMerkle;

    uint256 public txLimit = 2;
    uint256 public walletLimit = 10;
    uint256 public price = 0.01 ether;

    bool public whitelistPaused = true;
    bool public publicPaused = true;

    mapping(address => uint256) public claimedWhitelist;
    mapping(address => uint256) public walletMint;

    constructor() ERC721A("ArtForZombies", "AFZ") {}

    function whitelist(uint256 _amountToMint, uint256 _maxAmount, bytes32[] calldata _merkleProof) external payable {
        require(!whitelistPaused, "Whitelist paused");
        require(MAX_SUPPLY >= totalSupply() + _amountToMint, "Exceeds max supply");
        require(_amountToMint > 0, "Not 0 mints");

        address _caller = _msgSender();
        require(tx.origin == _caller, "No contracts");
        require(claimedWhitelist[_caller] + _amountToMint <= _maxAmount, "Not allow to mint more");

        bytes32 leaf = keccak256(abi.encodePacked(_caller, _maxAmount));
        require(MerkleProof.verify(_merkleProof, whitelistMerkle, leaf), "Invalid proof");

        unchecked { claimedWhitelist[_caller] += _amountToMint; }
        _safeMint(_caller, _amountToMint);
    }

    function mint(uint256 _amountToMint) external payable {
        require(!publicPaused, "Public paused");
        require(MAX_SUPPLY >= totalSupply() + _amountToMint, "Exceeds max supply");
        require(_amountToMint > 0, "Not 0 mints");
        require(_amountToMint <= txLimit, "Tx limit");
        require(_amountToMint * price <= msg.value, "Invalid funds provided");

        address _caller = _msgSender();
        require(tx.origin == _caller, "No contracts");
        require(walletMint[_caller] + _amountToMint <= walletLimit, "Not allow to mint more");

        unchecked { walletMint[_caller] += _amountToMint; }
        _safeMint(_caller, _amountToMint);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function minted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function withdraw() external onlyOwner {
        bool success;
        // 0x9D5025B327E6B863E5050141C987d988c07fd8B2 - accountant.ndao.eth
        // 33% of the funds goes to -> https://twitter.com/ucfoundation | https://app.endaoment.org/orgs/571168205
        (success, ) = payable(0x9D5025B327E6B863E5050141C987d988c07fd8B2).call{value: ((address(this).balance * 3333) / 10000)}("");
        require(success, "Failed to send");

        (success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "Failed to send");
    }

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        _safeMint(_to, _amount);
    }

    function toggleWhitelist() external onlyOwner {
        whitelistPaused = !whitelistPaused;
    }

    function togglePublic() external onlyOwner {
        publicPaused = !publicPaused;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setTxLimit(uint256 _limit) external onlyOwner {
        txLimit = _limit;
    }

    function setWalletLimit(uint256 _limit) external onlyOwner {
        walletLimit = _limit;
    }

    function setWhitelistMerkle(bytes32 _merkle) external onlyOwner {
        whitelistMerkle = _merkle;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }
}