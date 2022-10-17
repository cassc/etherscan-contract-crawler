// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Evoldinos is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 1111;
    uint8 public constant MAX_MINTS_PER_WALLET = 2;
    mapping(address => uint8) public walletMints;
    address withdrawAddress = 0xC673fD550fC3e9977139267A15a50EF7FAbc20CB;

    bytes32 public merkleRoot;

    enum SaleState {
        CLOSED,
        WHITELIST,
        PUBLICSALE
    }

    SaleState saleState = SaleState.CLOSED;
    uint256 public immutable PRICE;
    string private _baseTokenURI;
    bool public teamHasMinted = false;

    constructor() ERC721A("Evoldinos Club", "EVOLDINOS") {
        PRICE = 0.035 ether;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function getContractState()
        public
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256,
            uint8
        )
    {
        return (
            getSaleState(),
            PRICE,
            totalSupply(),
            MAX_SUPPLY,
            MAX_MINTS_PER_WALLET
        );
    }

    function whitelistMint(bytes32[] calldata merkleProof, uint256 amount)
        external
        payable
        callerIsUser
    {
        require(saleState != SaleState.CLOSED, "Sale inactive");
        require(saleState == SaleState.WHITELIST, "Use publicMint() function");
        require(
            (walletMints[msg.sender] + amount) <= MAX_MINTS_PER_WALLET,
            "exceeding max mints per wallet limit"
        );
        require((totalSupply() + amount) <= MAX_SUPPLY, "reached max supply");
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "merkle proof verification failed"
        );

        require(isValidValueSent(amount), "invalid ETH amount provided");
        walletMints[msg.sender] += uint8(amount);
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) external payable callerIsUser {
        require(saleState != SaleState.CLOSED, "Sale inactive");
        require(saleState == SaleState.PUBLICSALE, "Mint closed to public");
        require(
            (walletMints[msg.sender] + amount) <= MAX_MINTS_PER_WALLET,
            "exceeding max mints per wallet limit"
        );

        require(
            (balanceOf(msg.sender) + amount) <= MAX_MINTS_PER_WALLET,
            "exceeding max quantity per wallet limit"
        );

        require(isValidValueSent(amount), "invalid ETH amount provided");

        require((totalSupply() + amount) <= MAX_SUPPLY, "exceeding max supply");
        walletMints[msg.sender] += uint8(amount);
        _safeMint(msg.sender, amount);
    }

    function mintTeamAllocation() public onlyOwner nonReentrant {
        require(
            !teamHasMinted,
            "Founding team has already minted their allocation"
        );
        _safeMint(msg.sender, 61);
        teamHasMinted = true;
    }

    function isValidValueSent(uint256 amount) internal view returns (bool) {
        return PRICE * amount == msg.value;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setSaleState(uint8 stateNumber) public onlyOwner {
        if (stateNumber == 0) {
            saleState = SaleState.CLOSED;
        } else if (stateNumber == 1) {
            saleState = SaleState.WHITELIST;
        } else if (stateNumber == 2) {
            saleState = SaleState.PUBLICSALE;
        } else {
            revert("invalid input");
        }
    }

    function getSaleState() public view returns (uint8) {
        if (saleState == SaleState.CLOSED) {
            return 0;
        } else if (saleState == SaleState.WHITELIST) {
            return 1;
        } else if (saleState == SaleState.PUBLICSALE) {
            return 2;
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 totalBalance = address(this).balance;
        

        (bool success, ) = withdrawAddress.call{value: totalBalance}("");
        require(success, "Withdrawal failed.");
    }
}