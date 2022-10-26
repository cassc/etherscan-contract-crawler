// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721psi/contracts/ERC721Psi.sol";
import "erc721psi/contracts/extension/ERC721PsiBurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
 * This contract need deploy to bsc network
 */
contract WorldCupFlag is ERC721PsiBurnable, Ownable, ReentrancyGuard {

    bool public startMint = false;

    bytes32 merkleRoot;
    string baseURI;
    uint8 public constant MAX_COUNTRY = 32;
    uint public mintPrice = 0.08 ether;

    mapping(address => bool) public ogMinted;

    mapping(address => address) public referalMapping; // invitee => inviter
    mapping(address => uint) public referalCount; // inviter => invitee count

    event WCFMint(
        address indexed to,
        uint indexed amount,
        address indexed inviter,
        uint value
    );

    constructor() ERC721Psi("Yoyo in Qatar", "Yoyo") {}

    //=========================================================================
    // Setter
    //=========================================================================

    /**
     * The merkle tree will contain the address and amount, because we need stake og pass with different lock time
     */
    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setMintStatus(bool status) public onlyOwner {
        startMint = status;
    }

    function setMintPrice(uint _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function getMintPrice() public view returns (uint) {
        return mintPrice + (0.01 ether * (_minted / 10000));
    }

    function minted() public view returns(uint){
        return _minted;
    }

    //=========================================================================
    // Modifier
    //=========================================================================

    modifier mintStarted() {
        require(startMint, "World Cup Flag: Mint not started");
        _;
    }

    //=========================================================================
    // Functions
    //=========================================================================
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function premint(address to, uint amount) public onlyOwner {
        _safeMint(to, amount);
    }
    // og holder mint
    function mint(bytes32[] calldata proof, uint amount)
        external
        nonReentrant
        mintStarted
    {
        require(
            ogMinted[msg.sender] == false,
            "World Cup Flag: You have minted"
        );
        ogMinted[msg.sender] = true;
        require(
            MerkleProof.verifyCalldata(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, amount))
            ),
            "Fobo OG: Invalid proof"
        );
        _epollMint(msg.sender, amount);
    }

    // public mint 0.08 BNB
    // echo 10000 mint will increase 0.01 BNB price
    function publicMint(uint amount, address referal)
        external
        payable
        nonReentrant
        mintStarted
    {
        // country will be set in future
        require(
            msg.value ==
                (mintPrice + (0.01 ether * (_minted / 10000))) * amount,
            "Fobo OG: Insufficient amount"
        );
        address inviter = referalMapping[msg.sender];
        if (
            referal != address(0) &&
            referal != msg.sender &&
            inviter == address(0)
        ) {
            referalMapping[msg.sender] = referal;
            referalCount[referal] += 1;
            inviter = referal;
        }
        _epollMint(msg.sender, amount);

        emit WCFMint(msg.sender, amount, inviter, msg.value);
        // transfer 30% to inviter
        if (inviter != address(0)) {
            payable(inviter).transfer((msg.value * 3) / 10);
        }
    }

    /**
     * Burn three flag to generate a new flag
     */
    function merge(uint[] calldata tokenIds) external nonReentrant mintStarted {
        require(tokenIds.length == 3, "World Cup Flag: Invalid tokenIds");
        require(
            _exists(tokenIds[0]) &&
                _exists(tokenIds[1]) &&
                _exists(tokenIds[2]),
            "World Cup Flag: TokenId not exist"
        );
        require(
            ownerOf(tokenIds[0]) == msg.sender &&
                ownerOf(tokenIds[1]) == msg.sender &&
                ownerOf(tokenIds[2]) == msg.sender,
            "World Cup Flag: Not owner"
        );
        _burn(tokenIds[0]);
        _burn(tokenIds[1]);
        _burn(tokenIds[2]);

        _epollMint(msg.sender, 1);
    }

    function _epollMint(address to, uint amount) internal {
        require(startMint, "World Cup Flag: Mint not start");
        _safeMint(to, amount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}