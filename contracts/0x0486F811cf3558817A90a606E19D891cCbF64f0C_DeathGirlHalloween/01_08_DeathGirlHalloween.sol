// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DeathGirlHalloween is ERC721A, Ownable, ReentrancyGuard {
    // state
    string private base;
    uint256 public allowedMintsPerAllowlistAddress;
    uint256 public allowedMintsPerWaitlistAddress;
    uint256 public immutable mintPrice;
    uint256 public immutable collectionSize;
    string private placeholderURI;

    bool private allowlistActive;
    bytes32 private allowlistMerkleRoot;
    bool private waitlistActive;
    bytes32 private waitlistMerkleRoot;
    bool private teamActive;
    bytes32 private teamMerkleRoot;

    event UpdatedTeamList(bytes32 _old, bytes32 _new);
    event UpdatedTeamStatus(bool _old, bool _new);
    event UpdatedAllowlist(bytes32 _old, bytes32 _new);
    event UpdatedAllowlistStatus(bool _old, bool _new);
    event UpdatedAllowlistMintAmount(uint256 _old, uint256 _new);
    event UpdatedWaitlist(bytes32 _old, bytes32 _new);
    event UpdatedWaitlistStatus(bool _old, bool _new);
    event UpdatedWaitlistMintAmount(uint256 _old, uint256 _new);

    constructor(
        string memory _placeholderURI,
        bytes32 _teamMerkleRoot,
        bytes32 _allowlistMerkleRoot,
        bytes32 _waitlistMerkleRoot
    ) ERC721A("DEATH GIRL - HALLOWEEN", "DGH") {
        placeholderURI = _placeholderURI;
        mintPrice = 0;
        collectionSize = 66;
        allowedMintsPerAllowlistAddress = 1;
        allowedMintsPerWaitlistAddress = 1;
        teamMerkleRoot = _teamMerkleRoot;
        allowlistMerkleRoot = _allowlistMerkleRoot;
        waitlistMerkleRoot = _waitlistMerkleRoot;
        teamActive = true;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Mint
    function allowlistMint(bytes32[] calldata merkleProof, uint64 amount)
        external
        callerIsUser
    {
        require(allowlistActive, "Allowlist not active");
        require(totalSupply() + amount < collectionSize + 1, "Amount requested would exceed supply");
        require(amount < allowedMintsPerAllowlistAddress + 1, "Trying to mint more than allowed");
        require(
            MerkleProof.verify(
                merkleProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not on allowlist"
        );
        require(
            amountMinted(msg.sender) + amount < allowedMintsPerAllowlistAddress + 1,
            "Can't mint more"
        );

        _safeMint(_msgSender(), amount);
    }

    function waitlistMint(bytes32[] calldata merkleProof, uint64 amount)
        external
        callerIsUser
    {
        require(waitlistActive, "Waitlist not active");
        require(totalSupply() + amount < collectionSize + 1, "Amount requested would exceed supply");
        require(amount < allowedMintsPerWaitlistAddress + 1, "Trying to mint more than allowed");
        require(
            MerkleProof.verify(
                merkleProof,
                waitlistMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not on waitlist"
        );
        require(
            amountMinted(msg.sender) + amount < allowedMintsPerWaitlistAddress + 1,
            "Can't mint more"
        );

        _safeMint(_msgSender(), amount);
    }

    function teamMint(bytes32[] calldata merkleProof, uint64 amount)
        external
        callerIsUser
    {
        require(teamActive, "Team mint not active");
        require(totalSupply() + amount < collectionSize + 1, "Amount requested would exceed supply");
        require(
            MerkleProof.verify(
                merkleProof,
                teamMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not part of the dev team"
        );

        _safeMint(_msgSender(), amount);
    }

    // Contract Admin
    function setBaseURI(string memory baseURI) public onlyOwner {
        base = baseURI;
    }

    function disableTeam() public onlyOwner {
        require(teamActive, "Team mint not active");
        bool oldValue = teamActive;

        teamActive = false;
        emit UpdatedTeamStatus(oldValue, teamActive);
    }

    function enableAllowlist() external onlyOwner {
        require(!allowlistActive, "Allowlist mint already active");
        bool oldValue = allowlistActive;

        allowlistActive = true;
        emit UpdatedAllowlistStatus(oldValue, allowlistActive);
    }

    function disableAllowlist() public onlyOwner {
        require(allowlistActive, "Allowlist mint not active");
        bool oldValue = allowlistActive;

        allowlistActive = false;
        emit UpdatedAllowlistStatus(oldValue, allowlistActive);
    }

    function updateAllowlistMintAmount(uint256 _amount) external onlyOwner {
        uint256 oldAmount = allowedMintsPerAllowlistAddress;

        allowedMintsPerAllowlistAddress = _amount;
        emit UpdatedAllowlistMintAmount(oldAmount, allowedMintsPerAllowlistAddress);
    }

    function enableWaitlist() external onlyOwner {
        require(!waitlistActive, "Waitlist mint already active");
        bool oldValue = waitlistActive;

        waitlistActive = true;
        emit UpdatedWaitlistStatus(oldValue, waitlistActive);
    }

    function disableWaitlist() public onlyOwner {
        require(waitlistActive, "Waitlist mint not active");
        bool oldValue = waitlistActive;

        waitlistActive = false;
        emit UpdatedWaitlistStatus(oldValue, waitlistActive);
    }

    function updateWaitlistMintAmount(uint256 _amount) external onlyOwner {
        uint256 oldAmount = allowedMintsPerWaitlistAddress;

        allowedMintsPerWaitlistAddress = _amount;
        emit UpdatedWaitlistMintAmount(oldAmount, allowedMintsPerWaitlistAddress);
    }

    function setTeamlistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 oldList = teamMerkleRoot;

        teamMerkleRoot = _merkleRoot;
        emit UpdatedTeamList(oldList, teamMerkleRoot);
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 oldList = allowlistMerkleRoot;

        allowlistMerkleRoot = _merkleRoot;
        emit UpdatedAllowlist(oldList, allowlistMerkleRoot);
    }

    function setWaitlistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 oldList = waitlistMerkleRoot;

        waitlistMerkleRoot = _merkleRoot;
        emit UpdatedWaitlist(oldList, waitlistMerkleRoot);
    }

    function amountMinted(address ownerAddress) public view returns (uint256) {
        return _numberMinted(ownerAddress);
    }

    // Getters
    function getMintStatus() external view returns (bool) {
        return allowlistActive || waitlistActive;
    }

    function teamStatus() external view returns (bool) {
        return teamActive;
    }

    function allowlistStatus() external view returns (bool) {
        return allowlistActive;
    }

    function waitlistStatus() external view returns (bool) {
        return waitlistActive;
    }

    function mintingFee() external view returns (uint256) {
        return mintPrice;
    }

    function getCollectionSize() external view returns (uint256) {
        return collectionSize;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmTMsS1av11NDs5ctgAxfS3uSkjJkuMTFuiayZUDXQjAjq";
    }

    // Overrides
    // @notice Solidity required override for _baseURI(), if you wish to
    //  be able to set from API -> IPFS or vice versa using setBaseURI(string)
    function _baseURI() internal view override returns (string memory) {
        return base;
    }

    // @notice Override for ERC721A _startTokenId to change from default 0 -> 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // @notice Override for ERC721A tokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token doesn't exist");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : placeholderURI;
    }
}