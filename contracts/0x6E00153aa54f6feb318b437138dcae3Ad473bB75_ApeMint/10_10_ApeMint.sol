//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPassport {
    function mintPassports(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external returns (uint256, uint256);
}

interface IApeCoin {
    function allowance(address owner, address spender) external returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);
}

contract ApeMint is AccessControl, ReentrancyGuard {
    IPassport public passport;
    IApeCoin public apeCoin;

    bytes32 public claimlistRoot; // claimlist merkle root
    uint256 public mintStatus; // 0 paused, 1 claimlist mint, 2 public mint
    uint256 public mintPriceEth; // cost to mint a single token (in wei)
    uint256 public mintPriceApe; // cost to mint a single token (ape coin)
    uint256 public numPresale; // number of tokens allocated to presale
    uint256 public curNumPresale; // counter for presale amount sold

    // -------- constructor --------
    constructor(
        address _passport,
        address _apeCoin,
        bytes32 _claimlistRoot,
        uint256 _mintPriceEth,
        uint256 _mintPriceApe,
        uint256 _numPresale
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        passport = IPassport(_passport);
        apeCoin = IApeCoin(_apeCoin);

        claimlistRoot = _claimlistRoot;
        mintPriceEth = _mintPriceEth;
        mintPriceApe = _mintPriceApe;
        numPresale = _numPresale;
    }

    // -------- setters --------

    /// @notice Allows admin to set the merkle tree root for the claimlist
    /// @dev Merkle tree can be generated with the Javascript library "merkletreejs", the hashing algorithm should be keccak256 and pair sorting should be enabled. Leaf is abi encodePacked address & amount
    /// @param _claimlistRoot Merkle tree root
    function setClaimlistRoot(bytes32 _claimlistRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimlistRoot = _claimlistRoot;
    }

    function setMintStatus(uint256 _mintStatus) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_mintStatus <= 2, "wrong value");
        mintStatus = _mintStatus;
    }

    function setPriceEth(uint256 _mintPriceEth) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPriceEth = _mintPriceEth;
    }

    function setPriceApe(uint256 _mintPriceApe) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPriceApe = _mintPriceApe;
    }

    function setNumPresale(uint256 _numPresale) external onlyRole(DEFAULT_ADMIN_ROLE) {
        numPresale = _numPresale;
    }

    // -------- view --------

    function validateProof(bytes32[] calldata proof, address minter, uint256 maxAmount) public view {
        bool validProof = MerkleProof.verify(proof, claimlistRoot, keccak256(abi.encodePacked(minter, maxAmount)));
        require(validProof, "invalid proof");
    }

    // -------- presale mint --------

    function hydratePresaleApeCoin(
        bytes32[] calldata proof,
        uint256 claimAmount,
        uint256 maxAmount
    ) external nonReentrant {
        require(mintStatus == 1, "not started"); // presale started
        require(maxAmount >= claimAmount, "too many claimed");
        uint256 allowance = apeCoin.allowance(msg.sender, address(this));
        uint256 totalApeCoin = mintPriceApe * claimAmount;
        require(allowance >= totalApeCoin, "incorrect amount"); // check can spend enough apecoin
        require(curNumPresale + claimAmount <= numPresale, "presale limit reached"); // check presale quantity

        validateProof(proof, msg.sender, maxAmount);

        curNumPresale = curNumPresale + claimAmount;

        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory amount = new uint256[](1);
        amount[0] = claimAmount;

        passport.mintPassports(to, amount);

        bool success = apeCoin.transferFrom(msg.sender, address(this), totalApeCoin);
        require(success, "not enough ape");
    }

    function hydratePresale(bytes32[] calldata proof, uint256 claimAmount, uint256 maxAmount) external payable {
        require(mintStatus == 1, "not started"); // presale started
        require(maxAmount >= claimAmount, "too many claimed");
        require(mintPriceEth * claimAmount == msg.value, "incorrect amount"); // check eth sent
        require(curNumPresale + claimAmount <= numPresale, "presale limit reached"); // check presale quantity

        validateProof(proof, msg.sender, maxAmount);

        curNumPresale = curNumPresale + claimAmount;

        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory amount = new uint256[](1);
        amount[0] = claimAmount;

        passport.mintPassports(to, amount);
    }

    // -------- public mint --------

    function hydrateApeCoin(uint256 claimAmount) external nonReentrant {
        require(mintStatus == 2, "not started"); // public sale started
        uint256 allowance = apeCoin.allowance(msg.sender, address(this));
        uint256 totalApeCoin = mintPriceApe * claimAmount;
        require(allowance >= totalApeCoin, "incorrect amount"); // check can spend enough apecoin

        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory amount = new uint256[](1);
        amount[0] = claimAmount;

        passport.mintPassports(to, amount);

        bool success = apeCoin.transferFrom(msg.sender, address(this), totalApeCoin);
        require(success, "not enough ape");
    }

    function hydrate(uint256 claimAmount) external payable {
        require(mintStatus == 2, "not started"); // presale started
        require(mintPriceEth * claimAmount == msg.value, "incorrect amount"); // check eth sent

        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory amount = new uint256[](1);
        amount[0] = claimAmount;

        passport.mintPassports(to, amount);
    }

    // -------- withdraw --------

    function withdrawEth() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 value = address(this).balance;
        (bool sent, ) = msg.sender.call{value: value}("");
        require(sent, "withdraw failed");
    }

    function withdrawApe() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 value = apeCoin.balanceOf(address(this));
        bool sent = apeCoin.transfer(msg.sender, value);
        require(sent, "withdraw failed");
    }
}