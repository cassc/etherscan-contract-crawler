//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTYDashLite is ERC1155, Pausable, Ownable {

    string public constant name = "NFTY DASH LITE";
    string public constant symbol = "NFTYlite";

    uint256 public allowedPerWallet = 1;
    bytes32 public merkleRoot;

    uint256 constant MAX_SUPPLY = 2_222;
    uint256 public totalSupply;

    mapping(address => uint256) public mintedPerWallet;

    string public baseURI = "https://ipfs.io/ipfs/bafkreihezp3ih453c34km5xpae4evmnrbbnoxsi7wrk5px4fjbifklhrxe";

    event GovernanceMint(address to, uint256 amount);
    event PublicMint(address to, uint256 amount);

    constructor() ERC1155("") {}

    /** ----- Public ----- */

    function mintPublic(uint256 amount_, bytes32[] calldata merkleProof_) external whenNotPaused {
        require(totalSupply + amount_ <= MAX_SUPPLY, "MAXED_COL");

        unchecked {
            mintedPerWallet[msg.sender] += amount_;
            totalSupply += amount_;
        }
        require(mintedPerWallet[msg.sender] <= allowedPerWallet, "MAXED");

        require(tx.origin == msg.sender, "!EOA");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(merkleProof_, merkleRoot, leaf), "!AUTHORIZED");

        _mint(msg.sender, 0, amount_, "");

        emit PublicMint(msg.sender, amount_);
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

        emit GovernanceMint(to_, amount_);
    }

    function setAllowedPerWallet(uint256 newAllowed_) external onlyOwner {
        allowedPerWallet = newAllowed_;
    }

    /**
     * @notice sets baseURI
     * @param newUri_ the new base uri
     */
    function setBaseUri(string calldata newUri_) external onlyOwner {
        baseURI = newUri_;
    }

    function togglePause(bool paused_) external onlyOwner {
        if (paused_) _pause();
        else _unpause();
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }
}