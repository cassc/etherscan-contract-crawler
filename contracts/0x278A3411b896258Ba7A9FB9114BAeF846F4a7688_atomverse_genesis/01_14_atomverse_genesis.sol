/*

     ___   .___________.  ______   .___  ___. ____    ____  _______ .______          _______. _______ 
    /   \  |           | /  __  \  |   \/   | \   \  /   / |   ____||   _  \        /       ||   ____|
   /  ^  \ `---|  |----`|  |  |  | |  \  /  |  \   \/   /  |  |__   |  |_)  |      |   (----`|  |__   
  /  /_\  \    |  |     |  |  |  | |  |\/|  |   \      /   |   __|  |      /        \   \    |   __|  
 /  _____  \   |  |     |  `--'  | |  |  |  |    \    /    |  |____ |  |\  \----.----)   |   |  |____ 
/__/     \__\  |__|      \______/  |__|  |__|     \__/     |_______|| _| `._____|_______/    |_______|
                                                                                                      

*/


// SPDX-License-Identifier: MIT

/// @title atomverse genesis contract
/// @author atomverse team

pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract atomverse_genesis is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private IndexOfMint;

    string private _baseTokenURI;

    uint8 public maxMintAmountPerTx = 2;
    uint8 public maxPerWallet = 2;

    uint256 public cost = 0.09 ether;
    uint256 public maxSupply = 8888;
    uint256 public totalSupply = 8888;

    bool public paused = true;
    bool public publicSale = false;

    bytes32 public mRoot;

    mapping(address => uint8) public totalMintByUser;

    constructor() ERC721("atomverse_genesis", "ATOM") {}

    function totalMinted() public view returns (uint256) {
        return IndexOfMint.current();
    }

    /// @dev walletofOwner - IRC721 over written to save some gas.
    /// @return tokens id owned by the given address

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    /// @notice sets the cost of one NFT
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    /// @notice Changes the state of the contract, user cannot mint when contract is paused
    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    /// @notice Changes the state of the public sale
    function setPublicState(bool _state) external onlyOwner {
        publicSale = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setmRoot(bytes32 _mRoot) external onlyOwner {
        mRoot = _mRoot;
    }

    /// @dev modifer for mint conditions, which includes both public and whitelist sale.
    modifier mintConditions(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount! should be greater than 0 and less than 3"
        );
        require(!paused, "The contract is paused!");
        require(
            msg.value >= cost * _mintAmount,
            "Insufficient funds in your wallet, or wrong eth value sent!"
        );
        require(
            IndexOfMint.current() + _mintAmount <= maxSupply,
            "Not enough atoms NFT left to mint!"
        );

        if (!publicSale) {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    mRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Sorry you are not in our Whitelist"
            );
            require(
                totalMintByUser[msg.sender] + _mintAmount <= maxPerWallet,
                "Wallet cannot hold or mint more than 2  NFT in presale"
            );
        }
        _;
    }

    function setPriceOnConditions() internal {

        if (IndexOfMint.current() < 1199 && cost != 90000000000000000 && !publicSale) {
            cost = 0.09 ether;
        }
        if (IndexOfMint.current() > 1199 && cost != 100000000000000000 && !publicSale) {
            cost = 0.1 ether;
        }
        if (publicSale && cost != 150000000000000000) {
            cost = 0.15 ether;
        }
    }

    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintConditions(_mintAmount, _merkleProof)
    {
        _mintLoop(msg.sender, _mintAmount);
        setPriceOnConditions();
    }

    /// @notice n atoms reserved for future marketing campagins
    function devMint(uint256 _mintAmount) external onlyOwner {
        _mintLoop(msg.sender, _mintAmount);
    }

    function _mintLoop(address _receiver, uint256 _mintquantity) internal {
        for (uint256 i = 0; i < _mintquantity; i++) {
            IndexOfMint.increment();
            _safeMint(_receiver, IndexOfMint.current());
            totalMintByUser[_receiver]++;
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}