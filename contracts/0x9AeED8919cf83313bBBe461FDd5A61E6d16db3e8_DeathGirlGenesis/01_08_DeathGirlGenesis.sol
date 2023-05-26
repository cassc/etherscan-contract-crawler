// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DeathGirlGenesis is ERC721A, Ownable, ReentrancyGuard {
    // state
    string private base;
    uint256 public immutable allowedMintsPerAddress;
    uint256 public immutable mintPrice;
    uint256 public immutable collectionSize;
    string private placeholderURI;

    bool private deathlistActive;
    bytes32 private deathlistMerkleRoot;
    bool private allowlistActive;
    bytes32 private allowlistMerkleRoot;
    bool private teamActive;
    bytes32 private teamMerkleRoot;

    event UpdatedTeamList(bytes32 _old, bytes32 _new);
    event UpdatedTeamStatus(bool _old, bool _new);
    event UpdatedDeathlist(bytes32 _old, bytes32 _new);
    event UpdatedDeathlistStatus(bool _old, bool _new);
    event UpdatedAllowlist(bytes32 _old, bytes32 _new);
    event UpdatedAllowlistStatus(bool _old, bool _new);

    constructor(
        string memory _placeholderURI,
        bytes32 _teamMerkleRoot,
        bytes32 _deathlistMerkleRoot,
        bytes32 _allowlistMerkleRoot
    ) ERC721A("Deathgirl Genesis", "DGXG") {
        placeholderURI = _placeholderURI;
        mintPrice = 0;
        collectionSize = 666;
        allowedMintsPerAddress = 2;
        teamMerkleRoot = _teamMerkleRoot;
        deathlistMerkleRoot = _deathlistMerkleRoot;
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Mint
    function deathlistMint(bytes32[] calldata merkleProof, uint64 amount)
        external
        callerIsUser
    {
        require(deathlistActive, "Deathlist not active");
        require(totalSupply() + amount < collectionSize + 1, "Hit max supply");
        require(amount < allowedMintsPerAddress + 1, "The limit is 2");
        require(
            MerkleProof.verify(
                merkleProof,
                deathlistMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not on deathlist"
        );
        require(
            amountMinted(msg.sender) + amount < allowedMintsPerAddress + 1,
            "Can't mint more than 2 total"
        );

        _safeMint(_msgSender(), amount);
    }

    function allowlistMint(bytes32[] calldata merkleProof, uint64 amount)
        external
        callerIsUser
    {
        require(allowlistActive, "Allowlist not active");
        require(totalSupply() + amount < collectionSize + 1, "Hit max supply");
        require(amount < allowedMintsPerAddress + 1, "The limit is 2");
        require(
            MerkleProof.verify(
                merkleProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not on allowlist"
        );
        require(
            amountMinted(msg.sender) + amount < allowedMintsPerAddress + 1,
            "Can't mint more than 2 total"
        );

        _safeMint(_msgSender(), amount);
    }

    function teamMint(bytes32[] calldata merkleProof, uint64 amount)
        external
        callerIsUser
    {
        require(teamActive, "Team mint not active");
        require(totalSupply() + amount < collectionSize + 1, "Hit max supply");
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

    function enableTeam() external onlyOwner {
        require(!teamActive, "Team mint already active");
        bool oldValue = teamActive;

        teamActive = true;
        emit UpdatedTeamStatus(oldValue, teamActive);
    }

    function disableTeam() public onlyOwner {
        require(teamActive, "Team mint not active");
        bool oldValue = teamActive;

        teamActive = false;
        emit UpdatedTeamStatus(oldValue, teamActive);
    }

    function enableDeathlist() external onlyOwner {
        require(!deathlistActive, "Deathlist mint already active");
        bool oldValue = deathlistActive;

        deathlistActive = true;
        emit UpdatedDeathlistStatus(oldValue, deathlistActive);
    }

    function disableDeathlist() public onlyOwner {
        require(deathlistActive, "Deathlist mint not active");
        bool oldValue = deathlistActive;

        deathlistActive = false;
        emit UpdatedDeathlistStatus(oldValue, deathlistActive);
    }

    function enableAllowlist() external onlyOwner {
        require(!allowlistActive, "Allowlist mint already active");
        bool oldValue = allowlistActive;

        allowlistActive = true;
        emit UpdatedDeathlistStatus(oldValue, allowlistActive);
    }

    function disableAllowlist() public onlyOwner {
        require(allowlistActive, "Allowlist mint not active");
        bool oldValue = allowlistActive;

        allowlistActive = false;
        emit UpdatedAllowlistStatus(oldValue, allowlistActive);
    }

    function setTeamlistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 oldList = teamMerkleRoot;

        teamMerkleRoot = _merkleRoot;
        emit UpdatedTeamList(oldList, teamMerkleRoot);
    }

    function setDeathlistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 oldList = deathlistMerkleRoot;

        deathlistMerkleRoot = _merkleRoot;
        emit UpdatedTeamList(oldList, deathlistMerkleRoot);
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 oldList = allowlistMerkleRoot;

        allowlistMerkleRoot = _merkleRoot;
        emit UpdatedAllowlist(oldList, allowlistMerkleRoot);
    }

    function amountMinted(address ownerAddress) public view returns (uint256) {
        return _numberMinted(ownerAddress);
    }

    // Getters
    function getMintStatus() external view returns (bool) {
        return deathlistActive || allowlistActive;
    }

    function teamStatus() external view returns (bool) {
        return teamActive;
    }

    function deathlistStatus() external view returns (bool) {
        return deathlistActive;
    }

    function allowlistStatus() external view returns (bool) {
        return allowlistActive;
    }

    function mintingFee() external view returns (uint256) {
        return mintPrice;
    }

    function getCollectionSize() external view returns (uint256) {
        return collectionSize;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://Qma655xPC2HffrPUptCac9gvLzBNr6YEMZHn9kQuh7ReuD";
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