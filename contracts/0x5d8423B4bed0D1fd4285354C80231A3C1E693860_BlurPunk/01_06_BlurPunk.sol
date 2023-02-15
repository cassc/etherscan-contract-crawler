//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract BlurPunk is ERC721A {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 1402;
    uint256 public constant MAX_MINT_WHITELIST = 2;
    uint256 public constant MAX_MINT_PER_TX_PUBLIC = 3;
    uint256 public constant START_TOKEN_ID = 1;
    uint256 public price = 0.01402 ether;
    string public baseURI;
    string internal baseExtension = ".json";
    Stage public stage = Stage.Pause;
    address private WITHDRAW_ADDRESS;
    bool public founderMintStatus = false;

    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistClaimed;

    enum Stage {
        Pause,
        Whitelist,
        Public
    }

    event StageChanged(Stage from, Stage to);

    function setStage(Stage _stage) external onlyOwner {
        require(stage != _stage, "BlurPunk: invalid stage.");
        Stage prevStage = stage;
        stage = _stage;
        emit StageChanged(prevStage, stage);
    }

    address public immutable owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "BlurPunk: not owner");
        _;
    }

    /**
     * @dev Constructor function
     * @param _merkleRoot bytes32 Merkle root
     */
    constructor(bytes32 _merkleRoot) ERC721A("BlurPunk", "BLURPUNK") {
        owner = msg.sender;
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Returns the token ID
     * @return uint256 token ID
     * override start token id
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return START_TOKEN_ID;
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function whitelistMint(bytes32[] calldata merkleProof, uint256 quantity)
        public
        payable
    {
        require(stage == Stage.Whitelist, "BlurPunk: not whitelist mint stage");
        require(
            quantity <= MAX_MINT_WHITELIST,
            "BlurPunk: exceed max mint per account"
        );
        require(msg.value == price * quantity, "BlurPunk: not enough ether");
        require(
            whitelistClaimed[msg.sender] < MAX_MINT_WHITELIST,
            "BlurPunk: already claimed max quantity"
        );
        require(
            whitelistClaimed[msg.sender] + quantity <= MAX_MINT_WHITELIST,
            "BlurPunk: already claimed max quantity"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                toBytes32(msg.sender)
            ) == true,
            "invalid merkle proof"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "BlurPunk: exceed max supply"
        );
        whitelistClaimed[msg.sender] = whitelistClaimed[msg.sender] + quantity;
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) public payable {
        require(stage == Stage.Public, "BlurPunk: not public mint stage");
        require(
            quantity <= MAX_MINT_PER_TX_PUBLIC,
            "BlurPunk: exceed max mint per tx"
        );
        require(msg.value == price * quantity, "BlurPunk: not enough ether");

        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "BlurPunk: exceed max supply"
        );
        _mint(msg.sender, quantity);
    }

    function founderMint(address _to, uint256 quantity) public onlyOwner {
        require(quantity == 50, "BlurPunk: founder mint quantity must be 50");
        require(
            founderMintStatus == false,
            "BlurPunk: founder mint already minted"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "BlurPunk: exceed max supply"
        );
        _mint(_to, quantity);
        founderMintStatus = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "BlurPunk: not exist");
        string memory currentBaseURI = _baseURI();
        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : ""
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setWithdrawAddress(address _newWithdrawAddress)
        external
        onlyOwner
    {
        WITHDRAW_ADDRESS = _newWithdrawAddress;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        require(WITHDRAW_ADDRESS != address(0), "No withdraw address");
        _withdraw(WITHDRAW_ADDRESS, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}