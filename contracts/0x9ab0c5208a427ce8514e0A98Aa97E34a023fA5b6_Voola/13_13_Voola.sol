// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Voola is ERC1155, Ownable, ReentrancyGuard, Pausable {
    uint256[] public supplies = [1000, 1000, 1000];
    uint256[] public minted = [0, 0, 0];
    uint256[] public nfts = [0, 1, 2];
    uint256[] public nfts3 = [0, 1];
    uint256[] public nfts2 = [1, 2];
    uint256[] public nfts1 = [0, 2];
    uint256 counter = 0;

    error NotAllowlisted();
    error MaxPerWalletExceeded();
    error PreSaleNotActive();
    error PublicSaleNotActive();
    error NoContracts();

    bytes32 public root;
    uint256 public price = 0.033 ether;
    uint256 public maxMintAmount = 5;
    bool public presaleActive;
    bool public publicSaleActive;
    address public constant LEDGER1 =
        0x1a0Fb8e5C1df8E8f5BdBF72DA21bfbfb6FdBF45A;
    address public constant LEDGER2 =
        0x0CA051175A0DEba6635Df8D6E2Cd8cEb8014Bda4;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    mapping(address => uint256) public addressMintedBalance;

    constructor()
        ERC1155("ipfs://QmbFxXEysnGzejJMyXoNg1WjvxmXABjzpKAKSnqhbPuJKZ/{id}")
    {}

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function isValid(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function randdomNumber(uint256 mod) public returns (uint256) {
        counter++;
        return (uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender,
                    counter
                )
            )
        ) % mod);
    }

    function presaleMint(uint256 amount, bytes32[] memory proof)
        external
        payable
        callerIsUser
    {
        if (!presaleActive) revert PreSaleNotActive();
        if (!isValid(proof, keccak256(abi.encodePacked(msg.sender))))
            revert NotAllowlisted();
        uint256 supply = supplies[0] + supplies[1] + supplies[2];
        uint256 totalMint = minted[0] + minted[1] + minted[2];
        uint256 remain = supply - totalMint;
        require(remain >= amount, "Not enough nfts to mint");
        require(msg.value >= amount * price, "Not enough ether sent");
        if (addressMintedBalance[msg.sender] + amount > maxMintAmount)
            revert MaxPerWalletExceeded();

        for (uint256 i = 0; i < amount; i++) {
            uint256 id;
            if (
                minted[0] < supplies[0] &&
                minted[1] < supplies[1] &&
                minted[2] < supplies[2]
            ) {
                id = randdomNumber(3);
                _mint(msg.sender, nfts[id], 1, "");
                minted[nfts[id]] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[2] == minted[2] &&
                minted[0] < supplies[0] &&
                minted[1] < supplies[1]
            ) {
                id = randdomNumber(2);
                _mint(msg.sender, nfts3[id], 1, "");
                minted[nfts3[id]] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[0] == minted[0] &&
                minted[1] < supplies[1] &&
                minted[2] < supplies[2]
            ) {
                id = randdomNumber(2);
                _mint(msg.sender, nfts2[id], 1, "");
                minted[nfts2[id]] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[1] == minted[1] &&
                minted[0] < supplies[0] &&
                minted[2] < supplies[2]
            ) {
                id = randdomNumber(2);
                _mint(msg.sender, nfts1[id], 1, "");
                minted[nfts1[id]] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[1] == minted[1] &&
                supplies[2] == minted[2] &&
                minted[0] < supplies[0]
            ) {
                _mint(msg.sender, nfts[0], 1, "");
                minted[0] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[0] == minted[0] &&
                supplies[2] == minted[2] &&
                minted[1] < supplies[1]
            ) {
                _mint(msg.sender, nfts[1], 1, "");
                minted[1] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[1] == minted[1] &&
                supplies[0] == minted[0] &&
                minted[2] < supplies[2]
            ) {
                _mint(msg.sender, nfts[2], 1, "");
                minted[2] += 1;
                addressMintedBalance[msg.sender] += 1;
            }
        }
    }

    function mint(uint256 amount) external payable callerIsUser {
        if (!publicSaleActive) revert PublicSaleNotActive();
        uint256 supply = supplies[0] + supplies[1] + supplies[2];
        uint256 totalMint = minted[0] + minted[1] + minted[2];
        uint256 remain = supply - totalMint;
        require(remain >= amount, "Not enough nfts to mint");
        require(msg.value >= amount * price, "Not enough ether sent");
        if (addressMintedBalance[msg.sender] + amount > maxMintAmount)
            revert MaxPerWalletExceeded();

        for (uint256 i = 0; i < amount; i++) {
            uint256 id;
            if (
                minted[0] < supplies[0] &&
                minted[1] < supplies[1] &&
                minted[2] < supplies[2]
            ) {
                id = randdomNumber(3);
                _mint(msg.sender, nfts[id], 1, "");
                minted[nfts[id]] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[2] == minted[2] &&
                minted[0] < supplies[0] &&
                minted[1] < supplies[1]
            ) {
                id = randdomNumber(2);
                _mint(msg.sender, nfts3[id], 1, "");
                minted[nfts3[id]] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[0] == minted[0] &&
                minted[1] < supplies[1] &&
                minted[2] < supplies[2]
            ) {
                id = randdomNumber(2);
                _mint(msg.sender, nfts2[id], 1, "");
                minted[nfts2[id]] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[1] == minted[1] &&
                minted[0] < supplies[0] &&
                minted[2] < supplies[2]
            ) {
                id = randdomNumber(2);
                _mint(msg.sender, nfts1[id], 1, "");
                minted[nfts1[id]] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[1] == minted[1] &&
                supplies[2] == minted[2] &&
                minted[0] < supplies[0]
            ) {
                _mint(msg.sender, nfts[0], 1, "");
                minted[0] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[0] == minted[0] &&
                supplies[2] == minted[2] &&
                minted[1] < supplies[1]
            ) {
                _mint(msg.sender, nfts[1], 1, "");
                minted[1] += 1;
                addressMintedBalance[msg.sender] += 1;
            } else if (
                supplies[1] == minted[1] &&
                supplies[0] == minted[0] &&
                minted[2] < supplies[2]
            ) {
                _mint(msg.sender, nfts[2], 1, "");
                minted[2] += 1;
                addressMintedBalance[msg.sender] += 1;
            }
        }
    }

    function airDrop(
        address[] memory targets,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        require(
            minted[id] + amount * targets.length <= supplies[id],
            "Not enough supply"
        );
        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], id, amount, "");
            minted[id] += amount;
        }
    }

    function setWhitelistMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function withdraw() external nonReentrant {
        require(
            msg.sender == LEDGER1 || msg.sender == LEDGER2,
            "Only Team can withdraw"
        );
        uint256 balance = address(this).balance;

        uint256 SLEDGER1 = ((balance * 95) / 100);
        uint256 SLEDGER2 = balance - SLEDGER1;
        (bool os1, ) = payable(LEDGER1).call{value: SLEDGER1}("");
        require(os1);
        (bool os2, ) = payable(LEDGER2).call{value: SLEDGER2}("");
        require(os2);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override whenNotPaused {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override whenNotPaused {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}