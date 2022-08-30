// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    //function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns true if the claim function is frozen
    function frozen() external view returns (bool);

    // Freezes the claim function and allow the merkleRoot to be changed.
    function freeze() external;

    // Unfreezes the claim function.
    function unfreeze() external;

    // Update the merkle root and increment the week.
    function updateWhitelist(bytes32 newMerkleRoot) external;

    // This event is triggered whenever the merkle root gets updated.
    event whitelistUpdated(bytes32 indexed merkleRoot);
}

contract BlindAngels is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC721Burnable,
    IMerkleDistributor
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    bytes32 public override merkleRoot;

    uint256 public cost = 0.41 ether;
    uint256 public maxSupply = 30000;
    uint256 public maxMintAmount = 120;
    mapping(address => uint256) public addressMintedBalance;
    uint256 public nftPerAddressLimit = 30000;
    bool public onlyWhitelisted;
    bool public override frozen;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    bool public revealed;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        frozen = true;
        revealed = false;
        onlyWhitelisted = true;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        _tokenIdCounter.increment();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(bytes32[] calldata merkleProof, uint256 _mintAmount)
        public
        payable
        whenNotPaused
    {

        require(!frozen, "NFT: Contract is frozen.");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                // Verify the merkle proof.
                bytes32 node = keccak256(abi.encodePacked(msg.sender));
                require(
                    MerkleProof.verify(merkleProof, merkleRoot, node),
                    "Whitelist: Invalid proof."
                );

                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                    "max NFT per address exceeded"
                );
            }
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function updateWhitelist(bytes32 _merkleRoot) public override onlyOwner {
        require(frozen, "NFT: Contract not frozen.");

        // Set the new merkle root
        merkleRoot = _merkleRoot;

        emit whitelistUpdated(merkleRoot);
    }

    function isWhitelisted(bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    function freeze() public override onlyOwner {
        frozen = true;
    }

    function unfreeze() public override onlyOwner {
        frozen = false;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdrawSome(uint256 _amount, address _payoutAddress) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0 && _amount <= balance);
        _widthdraw(_payoutAddress, _amount);
    }

    function withdrawAll(address _payoutAddress) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(_payoutAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
}