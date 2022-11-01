// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SurrealsSwap.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DarkSurreals is ERC721A, Ownable {
    //@dev Attributes for NFT configuration
    string internal baseURI;
    uint256 public cost = 0.0666 ether;
    uint256 public maxSupply = 3330;
    uint256 public MAX_MINTABLE_AMOUNT = 9;
    mapping(uint256 => string) private _tokenURIs;
    bool public isWhitelist = false;
    bytes32 public merkleRoot;
    address public surrealsAddress;
    address public surrealsSwapAddress;
    mapping(address => uint256) sacrificeRedeemed;
    address paymentWallet = 0xD2F8818DfB5B9a4C64D0EB1039Ee68c311A4B180;

    // uint public whitelistStartTimestamp;

    // @dev inner attributes of the contract
    constructor() ERC721A("Surreals Midnight NFT", "SM") {}

    // Merkle tree whitelisting
    function setWhitelistActive(bool _whitelistActive) external onlyOwner {
        isWhitelist = _whitelistActive;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        merkleRoot = _whitelistMerkleRoot;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function setSurrealsAddress(address _surrealsAddress) external onlyOwner {
        surrealsAddress = _surrealsAddress;
    }

    function setSwapAddress(address _surrealsSwap) external onlyOwner {
        surrealsSwapAddress = _surrealsSwap;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev get base URI for NFT metadata
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 amount) external payable {
        require(!isWhitelist, "Whitelist ongoing.");
        uint256 costFull = getCost(amount, msg.sender);
        require(msg.value == costFull, "Invalid ETH amount");
        if (SurrealsSwap(surrealsSwapAddress).sacrifices(msg.sender) > 0)
            SurrealsSwap(surrealsSwapAddress).redeemSacrifice(
                msg.sender,
                amount
            );
        _mint(amount);
    }

    function mintWithSignature(uint256 amount, bytes32[] calldata _proof)
        external
        payable
    {
        // require(block.timestamp >= whitelistStartTimestamp, "Sale not started");
        require(isWhitelist, "Whitelist has ended");
        if (isWhitelist) {
            require(
                _verify(_leaf(msg.sender), _proof),
                "Invalid Merkle Tree proof."
            );
        }

        uint256 costFull = getCost(amount, msg.sender);
        require(msg.value == costFull, "Invalid ETH amount");
        _mint(amount);
    }

    function _mint(uint256 amount) internal {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply.");
        require(
            _numberMinted(msg.sender) + amount <= MAX_MINTABLE_AMOUNT,
            "Exceeds max mintable amount"
        );

        if (amount >= 3) sacrificeRedeemed[msg.sender] += 3;
        else sacrificeRedeemed[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    /**
     * @dev change cost of NFT
     * @param _newCost new cost of each edition
     */
    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    /**
     * @dev change metadata uri
     * @param _newBaseURI new URI for metadata
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Get token URI
     * @param tokenId ID of the token to retrieve
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (bytes(_tokenURIs[tokenId]).length == 0) {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            Strings.toString(tokenId),
                            ".json"
                        )
                    )
                    : "";
        } else return _tokenURIs[tokenId];
    }

    function getCost(uint256 amount, address _wallet)
        public
        view
        returns (uint256)
    {
        uint256 sacrifice = SurrealsSwap(surrealsSwapAddress).sacrifices(
            _wallet
        );

        if (sacrifice > 0) amount -= sacrifice;

        if (isWhitelist || IERC721(surrealsAddress).balanceOf(_wallet) > 0)
            return 0.05 ether * amount;

        return cost * amount;
    }

    function setPaymentWallet(address _wallet) external onlyOwner {
        paymentWallet = _wallet;
    }

    function withdraw() external onlyOwner {
        address payable to = payable(paymentWallet);
        to.transfer(address(this).balance);
    }
}