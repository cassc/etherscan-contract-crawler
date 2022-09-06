//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTYDashPremium is ERC1155, Ownable {
    using Strings for uint256;

    string public constant name = "NFTY DASH PREMIUM";
    string public constant symbol = "NFTYpremium";

    uint256 public totalSupply;

    bytes32 public merkleRoot;

    bool public publicMinting;
    bool public whitelistMinting;

    uint256 constant MAX_SUPPLY = 5_555;

    uint256 public priceWhitelist = 0.069 ether;
    uint256 public pricePublic = 0.085 ether;

    mapping(address => bool) public mintedPerWallet;

    string public baseURI = "https://ipfs.io/ipfs/bafkreifnrblprd75xx5d557h4ufjbk5e7chqxfvdggu2jo2ohycingrbea";

    modifier onlyPublic() {
        require(publicMinting, "!public");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelistMinting, "!whitelist");
        _;
    }

    constructor() ERC1155("") {}

    /** ----- Public ----- */

    function mintPublic() external payable onlyPublic {
        require(totalSupply + 1 <= MAX_SUPPLY, "MAXED_COL");
        require(msg.value == pricePublic, "!PRICE");
        require(!mintedPerWallet[msg.sender], "MAXED");
        require(tx.origin == msg.sender, "!EOA");

        unchecked {
            mintedPerWallet[msg.sender] = true;
            totalSupply++;
        }

        _mint(msg.sender, 0, 1, "");
    }

    function whitelist(bytes32[] calldata merkleProof_) external payable onlyWhitelist {
        require(totalSupply + 1 <= MAX_SUPPLY, "MAXED_COL");
        require(msg.value == priceWhitelist, "!PRICE");
        require(!mintedPerWallet[msg.sender], "MAXED");
        require(tx.origin == msg.sender, "!EOA");

        unchecked {
            mintedPerWallet[msg.sender] = true;
            totalSupply++;
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(merkleProof_, merkleRoot, leaf), "!AUTHORIZED");

        _mint(msg.sender, 0, 1, "");
    }

    /** ----- PUBLIC ----- */

    function uri(uint256 id) public view override returns (string memory) {
        return baseURI;
    }

    /** ----- Gov Power ----- */

    function govMinting(address to_, uint256 amount_) external onlyOwner {
        require(totalSupply + amount_ <= MAX_SUPPLY, "MAXED_COL");

        totalSupply += amount_;

        _mint(to_, 0, amount_, "");
    }

    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "address(0)");
        (bool succeed, ) = _to.call{ value: address(this).balance }("");
        require(succeed, "Failed to withdraw Ether");
    }

    function setPublicMinting(bool publicMinting_) external onlyOwner {
        publicMinting = publicMinting_;
    }

    function setWhitelistMinting(bool whitelistMinting_) external onlyOwner {
        whitelistMinting = whitelistMinting_;
    }

    /**
     * @notice sets baseURI
     * @param newUri_ the new base uri
     */
    function setBaseUri(string calldata newUri_) external onlyOwner {
        baseURI = newUri_;
    }

    function setPriceWhitelist(uint256 priceWhitelist_) external onlyOwner {
        priceWhitelist = priceWhitelist_;
    }

    function setPricePublic(uint256 pricePublic_) external onlyOwner {
        pricePublic = pricePublic_;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }
}