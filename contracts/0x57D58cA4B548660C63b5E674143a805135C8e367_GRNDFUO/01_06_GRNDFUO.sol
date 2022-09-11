// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GRNDFUO is ERC721A, Ownable {

    uint256 maxSupply = 1000;
    uint256 mintPrice = 0.1 * 10 ** 18;

    string internal metadataBaseURI;
    bool internal mintEnabled = false;
    bytes32 internal whitelistMerkleRoot;
    uint256 internal reservedAmountForOffline = 0;

    address internal immutable etherWithdrawalAddress;

    constructor(string memory baseURI, bytes32 merkleRoot, uint256 reservedAmount, address withdrawalAddress) ERC721A("GRND FUO", "GRND") {
        metadataBaseURI = baseURI;
        whitelistMerkleRoot = merkleRoot;
        reservedAmountForOffline = reservedAmount;
        etherWithdrawalAddress = withdrawalAddress;
    }

    modifier onlyUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    // Only 1 token is allowed for an address.
    function mint(bytes32[] calldata merkleProof) external payable onlyUser {
        require(mintEnabled, "Not opening");
        require(_totalMinted() + reservedAmountForOffline < maxSupply, "Sold out");
        require(mintPrice <= msg.value, "Insufficient fund");
        require(_numberMinted(msg.sender) == 0, "Address already minted");

        require(
            MerkleProof.verify(
                merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not in whitelist"
        );

        _mint(msg.sender, 1);
    }

    // Only 1 token is allowed for an address.
    function mintForOffline(address[] calldata addresses) external onlyOwner onlyUser {
        require(addresses.length <= reservedAmountForOffline, "Not enough reservation left");

        reservedAmountForOffline -= addresses.length;

        for (uint256 i = 0; i < addresses.length; i++)
        {
            require(_numberMinted(addresses[i]) == 0, "Address already minted");
            _mint(addresses[i], 1);
        }
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function numberMinted(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    function setMintEnabled(bool enabled) external onlyOwner {
        mintEnabled = enabled;
    }

    function withdrawEther() external onlyOwner {
        require(address(this).balance > 0, "No ether to withdraw");
        require(
            payable(etherWithdrawalAddress).send(address(this).balance),
            "Withdraw failed"
        );
    }

    function updateMetadataBaseURI(string calldata baseURI) external onlyOwner {
        metadataBaseURI = baseURI;
    }

    function updateWhitelist(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function updateReservationForOffline(uint256 amount) external onlyOwner {
        require(amount + _totalMinted() <= maxSupply, "Not enough tokens left");
        reservedAmountForOffline = amount;
    }

    function reservationForOffline() external view returns (uint256) {
        return reservedAmountForOffline;
    }

    function _baseURI() internal view override returns (string memory) {
        return metadataBaseURI;
    }
}