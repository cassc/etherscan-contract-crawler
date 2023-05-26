// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

error BadMintState();
error MaxMintPerWallet();
error SoldOut();
error BadProof();
error InsufficientFunds();
error CannotIncreaseSupply();
error SupplyMustBeMultipleOfThree();

contract OneEyeEntPhaseOne is
    ERC1155,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    string public name;
    string public symbol;
    string public contractURI;
    uint256 public maxSupply = 294;
    uint256 public cost = 0 ether;
    uint256 public maxPerWallet = 2;
    mapping(address => uint256) public walletMintCounts;
    uint256 public mintedSupply;
    bytes32 public allowlistMerkleRoot =
        0x9f1746b61ea43e16e58584ded0371a2e2e160b85d38d99a7b13132ec6ed1173a;
    bytes32 public teamMerkleRoot =
        0x068605bf098ce1c161665eb1fa8b714fece08e2bd3746f7ad5074959fb228d91;
    MintState public mintState = MintState.DISABLED;
    address public fundsReceiver = 0x95ee3143BA1E2fD4DbF8287b4b15936197B89Ddd;
    address public communityWallet = 0x6c7b02D483C233A7D3De215b21248857A978b496;

    struct Config {
        uint256 mintState;
        uint256 cost;
        uint256 maxSupply;
        uint256 mintedSupply;
    }

    enum MintState {
        DISABLED,
        ALLOW,
        PUBLIC
    }

    constructor(string memory _contractURI, string memory _uri) ERC1155("") {
        name = "1Eye Ent Phase 1";
        symbol = "1EE";
        contractURI = _contractURI;
        _setURI(_uri);
    }

    // Minting Setters

    function setAllowlistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    function setTeamMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        teamMerkleRoot = _merkleRoot;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        if (_maxSupply > maxSupply) {
            revert CannotIncreaseSupply();
        }
        if (_maxSupply % 3 != 0) {
            revert SupplyMustBeMultipleOfThree();
        }
        maxSupply = _maxSupply;
    }

    function setMaxPerWallet(uint256 _newperwallet) public onlyOwner {
        maxPerWallet = _newperwallet;
    }

    function setMintState(MintState _mintState) public onlyOwner {
        mintState = _mintState;
    }

    // Metadata Setters

    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    // Minting functions

    modifier ensureMintState(MintState _mintState) {
        if (mintState != _mintState) {
            revert BadMintState();
        }
        _;
    }

    modifier checkSupply() {
        if (walletMintCounts[msg.sender] >= maxPerWallet) {
            revert MaxMintPerWallet();
        }

        if (mintedSupply + 3 > maxSupply) {
            revert SoldOut();
        }
        _;
    }

    modifier checkFunds() {
        if (msg.value != cost) {
            revert InsufficientFunds();
        }
        _;
    }

    modifier checkProof(bytes32[] calldata proof, bytes32 root) {
        if (
            !MerkleProof.verify(
                proof,
                root,
                keccak256(bytes.concat(keccak256(abi.encode(msg.sender))))
            )
        ) {
            revert BadProof();
        }
        _;
    }

    function _commonMint() internal {
        _mint(msg.sender, 1, 1, "");
        _mint(msg.sender, 2, 1, "");
        _mint(msg.sender, 3, 1, "");
        walletMintCounts[msg.sender] += 1;
        mintedSupply += 3;
    }

    function communityWalletMint() external onlyOwner {
        if (mintedSupply + 30 > maxSupply) {
            revert SoldOut();
        }

        _mint(communityWallet, 1, 10, "");
        _mint(communityWallet, 2, 10, "");
        _mint(communityWallet, 3, 10, "");
        walletMintCounts[communityWallet] += 10;
        mintedSupply += 30;
    }

    function teamMint(
        bytes32[] calldata proof
    )
        external
        ensureMintState(MintState.ALLOW)
        checkSupply
        checkProof(proof, teamMerkleRoot)
    {
        _commonMint();
    }

    function allowlistMint(
        bytes32[] calldata proof
    )
        external
        payable
        ensureMintState(MintState.ALLOW)
        checkSupply
        checkFunds
        checkProof(proof, allowlistMerkleRoot)
    {
        _commonMint();
    }

    function publicMint()
        external
        payable
        ensureMintState(MintState.PUBLIC)
        checkSupply
        checkFunds
    {
        _commonMint();
    }

    // Transfers

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // Misc

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(fundsReceiver).transfer(_balance);
    }

    function getConfig() external view returns (Config memory) {
        Config memory config = Config({
            mintState: uint8(mintState),
            cost: cost,
            maxSupply: maxSupply,
            mintedSupply: mintedSupply
        });

        return config;
    }
}