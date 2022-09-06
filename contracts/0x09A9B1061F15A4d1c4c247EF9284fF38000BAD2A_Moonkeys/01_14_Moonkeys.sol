// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Moonkeys is ERC721A, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    enum State {
        Setup,
        FreeList,
        Public,
        Finished
    }

    string public baseURI;
    bytes32 private freeListRoot;
    State public state;

    uint256 public tokensReserved;
    uint256 public RESERVED_AMOUNT = 125;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant FREE_SUPPLY = 1500;
    uint256 public constant FREE_MAX_MINT = 3;
    uint256 public constant PUBLIC_MAX_MINT = 10;
    uint256 public PUBLIC_PRICE = 0.008 * 10**18;

    mapping(address => uint256) public freeMintedBalance;
    event Minted(address minter, uint256 amount);
    event StateChanged(State state);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        state = State.Setup;
        baseURI = _initBaseURI;
    }

    function updatePublicPrice(uint256 price) public onlyOwner {
        PUBLIC_PRICE = price;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setState(State _state) public onlyOwner {
        state = _state;
        emit StateChanged(_state);
    }

    function setFreeListRoot(bytes32 _freeListRoot) public onlyOwner {
        freeListRoot = _freeListRoot;
    }

    function freeListMint(uint256 amount, bytes32[] memory proof)
        external
        payable
    {
        require(state == State.FreeList, "FreeList mint is not active.");
        require(!Address.isContract(msg.sender), "Contracts are not allowed.");

        require(
            amount <= FREE_MAX_MINT,
            "Amount should not exceed max free mint number per transaction."
        );
        require(
            totalSupply() + amount <= FREE_SUPPLY,
            "Max free supply exceeded."
        );
        require(
            MerkleProof.verify(
                proof,
                freeListRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not eligible to the free mint."
        );

        uint256 freeMintedCount = freeMintedBalance[msg.sender];

        require(
            freeMintedCount + amount <= FREE_MAX_MINT,
            "Max NFT per address exceeded"
        );

        _safeMint(msg.sender, amount);
        freeMintedBalance[msg.sender] = freeMintedCount + amount;
        emit Minted(msg.sender, amount);
    }

    function publicMint(uint256 amount) external payable {
        require(state == State.Public, "Sale is not active.");
        require(!Address.isContract(msg.sender), "Contracts are not allowed.");
        if (msg.value == 0) {
            require(
                totalSupply() + amount <= FREE_SUPPLY,
                "Max free supply exceeded."
            );
            require(
                amount <= FREE_MAX_MINT,
                "Amount should not exceed max free mint number per transaction."
            );
            uint256 freeMintedCount = freeMintedBalance[msg.sender];

            require(
                freeMintedCount + amount <= FREE_MAX_MINT,
                "Max NFT per address exceeded"
            );

            _safeMint(msg.sender, amount);
            freeMintedBalance[msg.sender] = freeMintedCount + amount;
            emit Minted(msg.sender, amount);
        } else {
            require(
                amount <= PUBLIC_MAX_MINT,
                "Amount should not exceed max mint number per transaction."
            );
            require(
                totalSupply() + amount <= MAX_SUPPLY,
                "Amount should not exceed max supply."
            );
            require(
                msg.value >= PUBLIC_PRICE * amount,
                "Ether value sent is incorrect."
            );

            _safeMint(msg.sender, amount);
            emit Minted(msg.sender, amount);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function reserve(address recipient, uint256 amount) external onlyOwner {
        require(
            tokensReserved + amount <= RESERVED_AMOUNT,
            "Max reserve amount exceeded"
        );
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");

        _safeMint(recipient, amount);
        tokensReserved += amount;
        emit ReservedToken(msg.sender, recipient, amount);
    }

    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;

        uint256 wallet1Value = (balance * 15) / 100;
        uint256 wallet2Value = (balance * 50) / 100;
        uint256 wallet3Value = (balance * 20) / 100;
        uint256 wallet4Value = balance -
            wallet1Value -
            wallet2Value -
            wallet3Value;

        (bool success1, ) = payable(0xb5af8ad4D37541dCaF3c3de0790B37935CFeA6aF)
            .call{value: wallet1Value}("");
        (bool success2, ) = payable(0x17c3f553191E2D963e48F740749f3f262779982b)
            .call{value: wallet2Value}("");
        (bool success3, ) = payable(0x4069afe7352fD6697759A8FEe011b8aD5E8E3806)
            .call{value: wallet3Value}("");
        (bool success4, ) = payable(0x0378F2955e84Ba700c082261e86AF605327Bb81b)
            .call{value: wallet4Value}("");

        require(success1, "Transfer 1 failed.");
        require(success2, "Transfer 2 failed.");
        require(success3, "Transfer 3 failed.");
        require(success4, "Transfer 4 failed.");
    }
}