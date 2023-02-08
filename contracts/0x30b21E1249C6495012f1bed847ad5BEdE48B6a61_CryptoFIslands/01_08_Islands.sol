// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "lib/ERC721A/contracts/ERC721A.sol";

contract CryptoFIslands is ERC721A, Ownable {
    using MerkleProof for bytes32[];

    /* ––– PUBLIC VARIABLES ––– */
    /*
     * @notice – Control switch for sale
     * @notice – Set by `setMintStage()`
     * @dev – 0 = PAUSED; 1 = ALLOWLIST, 2 = PUBLIC
     */
    enum MintStage {
        PAUSED,
        ALLOWLIST,
        PUBLIC
    }
    MintStage public _stage = MintStage.PAUSED;

    /*
     * @notice – Mint price in ether
     * @notice – Set by `setPrice()`
     */
    uint256 public _price = 0.0289 ether;

    /*
     * @notice – MerkleProof root for verifying allowlist addresses
     * @notice – Set by `setRoot()`
     */
    bytes32 public _root;

    /*
     * @notice – Maximum token supply
     * @dev – Note this is constant and cannot be changed
     */
    uint256 public constant MAX_SUPPLY = 5_555;

    /*
     * @notice – Wallet Mint Qty
     * @notice – Set by `setMintQty()`
     */
    uint256 public _walletMintQty = 3;

    /*
     * @notice – Token URI base
     * @notice – Passed into constructor and also can be set by `setBaseURI()`
     */
    string public baseTokenURI;

    /* ––– END PUBLIC VARIABLES ––– */

    /* ––– INTERNAL FUNCTIONS ––– */
    /*
     * @notice – Internal function that overrides baseURI standard
     * @return – Returns newly set baseTokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /* ––– END INTERNAL FUNCTIONS ––– */

    /* ––– CONSTRUCTOR ––– */
    /*
     * @notice – Contract constructor
     * @param - newBaseURI : Token base string for metadata
     */
    constructor(string memory newBaseURI)
        ERC721A("CryptoFIslands", "CFISLANDS")
    {
        baseTokenURI = newBaseURI;
    }

    /* ––– END CONSTRUCTOR ––– */

    /* ––– MODIFIERS ––– */
    /*
     * @notice – Smart contract source check
     */
    modifier contractCheck() {
        require(tx.origin == msg.sender, "beep boop");
        _;
    }

    /*
     * @notice – Current mint stage check
     */
    modifier checkSaleActive() {
        require(MintStage.PAUSED != _stage, "sale not active");
        _;
    }

    /*
     * @notice – Token max supply boundary check
     */
    modifier checkMaxSupply(uint256 _amount) {
        require(totalSupply() + _amount <= MAX_SUPPLY, "exceeds total supply");
        _;
    }

    /*
     * @notice – Transaction value check
     */
    modifier checkTxnValue(uint256 _amount) {
        require(msg.value >= _price * _amount, "invalid transaction value");
        _;
    }

    /*
     * @notice – Validates the merkleproof data
     */
    modifier validateProof(bytes32[] calldata _proof) {
        //Only for ALLOWLIST. Skips for public
        if (MintStage.ALLOWLIST == _stage) {
            require(
                MerkleProof.verify(
                    _proof,
                    _root,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "wallet not allowed"
            );
        }
        _;
    }

    /*
     * @notice – Wallet max supply boundary check
     */
    modifier validateMintQty(uint256 _amount) {
        require(
            _numberMinted(msg.sender) + _amount <= _walletMintQty,
            "wallet already claimed"
        );
        _;
    }

    /* ––– END MODIFIERS ––– */

    /* ––– OWNER FUNCTIONS ––– */
    /*
     * @notice – Gifts an amount of tokens to a given address
     * @param – _to: Address to send the tokens to
     * @param – _amount: Amount of tokens to send
     */
    function gift(address _to, uint256 _amount)
        public
        onlyOwner
        checkMaxSupply(_amount)
    {
        _safeMint(_to, _amount);
    }

    /*
     * @notice – Sets the merkle root
     * @param – _newRoot: New root to set
     */
    function setRoot(bytes32 _newRoot) public onlyOwner {
        _root = _newRoot;
    }

    /*
     * @notice – Sets the mint qty for each sale phase
     * @param – _newMintQty: New qty a user can mint
     */
    function setMintQty(uint256 _newMintQty) public onlyOwner {
        _walletMintQty = _newMintQty;
    }

    /*
     * @notice – Sets the mint price (in wei)
     * @param – _newPrice: New mint price to set
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    /*
     * @notice – Sets the mint stage
     * @param – _stage: {0 = PAUSED | 1 = ALLOWLIST | 2 = PUBLIC}
     */
    function setMintStage(MintStage _newStage) public onlyOwner {
        _stage = _newStage;
    }

    /*
     * @notice – Sets the base URI to the given string
     * @param – baseURI: New base URI to set
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    /*
     * @notice – Withdraws the contract balance to the contract owner
     */
    function withdraw() public onlyOwner {
        uint256 value = address(this).balance;
        address payable to = payable(msg.sender);
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer failed.");
    }

    /*
     * @notice – Withdraws any ERC20 contract balance to the contract owner
     */
    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /* ––– END OWNER FUNCTIONS ––– */

    /* ––– PUBLIC FUNCTIONS ––– */
    /*
     * @notice – Mint function
     * @param _proof: MerkleProof data to validate
     */
    function mint(bytes32[] calldata _proof, uint256 quantity)
        public
        payable
        contractCheck
        checkSaleActive
        checkMaxSupply(quantity)
        checkTxnValue(quantity)
        validateProof(_proof)
        validateMintQty(quantity)
    {
        _safeMint(msg.sender, quantity);
    }

    /*
     * @notice – mintRemaining function
     * @param owner: address to check how many more they can mint while transitioning through sales phases
     */
    function mintRemaining(address owner) public view returns (uint256) {
        uint256 userMinted = _numberMinted(owner);
        return _walletMintQty - userMinted;
    }

    /* ––– END PUBLIC FUNCTIONS ––– */
}