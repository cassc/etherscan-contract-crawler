// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NftinitLifetime is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 1120;

    uint256 public constant WL_PRICE = 0.3 ether;
    uint256 public constant WL_PRICE_DISCOUNTED_2X = 0.5 ether;
    uint256 public constant SALE_PRICE = 0.4 ether;

    uint256 public constant MAX_PER_WL = 2;
    uint256 public constant MAX_PER_TX = 2;

    //  0: INACTIVE, 1: PRE_SALE, 2: PUBLIC_SALE
    uint256 public SALE_STATE = 0;

    bytes32 private merkleRoot;

    mapping(address => uint256) whitelistMints;

    Counters.Counter private idTracker;

    string public baseURI;

    constructor() ERC721("NFTinit Lifetime", "INITLT") {
        idTracker.increment();
    }

    function mintInternal(address _to) internal {
        _mint(_to, idTracker.current());
        idTracker.increment();
    }

    function ownerMint(address account, uint256 amount) external onlyOwner {
        require(
            idTracker.current() + amount - 1 <= MAX_SUPPLY,
            "INIT: Purchasable NFTs are all minted."
        );

        for (uint256 i = 0; i < amount; i++) {
            mintInternal(account);
        }
    }

    function mintPreSale(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(SALE_STATE == 1, "INIT: Pre-sale has not started yet.");
        require(
            idTracker.current() + amount - 1 <= MAX_SUPPLY,
            "INIT: Purchasable NFTs are all minted."
        );
        require(
            msg.value >= (amount == 2 ? WL_PRICE_DISCOUNTED_2X : WL_PRICE),
            "INIT: Insufficient funds."
        );
        require(
            whitelistMints[msg.sender] + amount <= MAX_PER_WL,
            "INIT: Address has reached the wallet cap in pre-sale."
        );

        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "INIT: Merkle verification has failed, address is not in the pre-sale whitelist."
        );

        for (uint256 i = 0; i < amount; i++) {
            mintInternal(msg.sender);
        }
        whitelistMints[msg.sender] += amount;
    }

    function mintPublicSale(uint256 amount) external payable {
        require(SALE_STATE == 2, "INIT: Public sale has not started yet.");
        require(
            idTracker.current() + amount - 1 <= MAX_SUPPLY,
            "INIT: Purchasable NFTs are all minted."
        );
        require(msg.value >= amount * SALE_PRICE, "INIT: Insufficient funds.");
        require(
            amount <= MAX_PER_TX,
            "INIT: Amount exceeds transaction mint cap."
        );

        for (uint256 i = 0; i < amount; i++) {
            mintInternal(msg.sender);
        }
    }

    // DON'T CALL FROM CONTRACTS - RPC CALLS ONLY
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);
        if (balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balance);
            uint256 index = 0;

            uint256 totalSupply_ = totalSupply();
            for (uint256 tokenId = 1; tokenId <= totalSupply_; tokenId++) {
                if (index == balance) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }
            return result;
        }
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return idTracker.current() - 1;
    }

    function setSaleState(uint256 _saleState) external onlyOwner {
        require(
            _saleState >= 0 && _saleState < 3,
            "INIT: Invalid new sale state."
        );
        SALE_STATE = _saleState;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "INIT: No balance to withdraw.");

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "INIT: Transfer failed.");
    }
}