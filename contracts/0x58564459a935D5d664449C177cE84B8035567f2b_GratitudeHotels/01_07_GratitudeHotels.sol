// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/*
 ██████╗ ██████╗  █████╗ ████████╗██╗████████╗██╗   ██╗██████╗ ███████╗
██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██║╚══██╔══╝██║   ██║██╔══██╗██╔════╝
██║  ███╗██████╔╝███████║   ██║   ██║   ██║   ██║   ██║██║  ██║█████╗  
██║   ██║██╔══██╗██╔══██║   ██║   ██║   ██║   ██║   ██║██║  ██║██╔══╝  
╚██████╔╝██║  ██║██║  ██║   ██║   ██║   ██║   ╚██████╔╝██████╔╝███████╗
 ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚═════╝ ╚══════╝
                                                                       
██╗  ██╗ ██████╗ ████████╗███████╗██╗     ███████╗                     
██║  ██║██╔═══██╗╚══██╔══╝██╔════╝██║     ██╔════╝                     
███████║██║   ██║   ██║   █████╗  ██║     ███████╗                     
██╔══██║██║   ██║   ██║   ██╔══╝  ██║     ╚════██║                     
██║  ██║╚██████╔╝   ██║   ███████╗███████╗███████║                     
╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚══════╝╚══════╝
*/             
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GratitudeHotels is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 private constant RESERVED = 100;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public tokenPrice = 2 ether;
    bool public openToPublic;
    bool public teamMinted;
    string private baseTokenURI;
    bytes32 private merkleRoot;
    mapping(address => uint256) public minted;
    error BeyondMaxSupply();
    error AlreadyMinted();
    error WrongAmountOfEther();
    error NotEligibleToMint();

    constructor(string memory _baseTokenURI, bytes32 _merkleRoot)
        ERC721A("AccessCard", "G")
    {
        baseTokenURI = _baseTokenURI;
        merkleRoot = _merkleRoot;
    }

    function isValidUser(bytes32[] memory _merkleProof, bytes32 _leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(_merkleProof, merkleRoot, _leaf);
    }

    function publicMint(uint256 _quantity) external payable {
        if (!openToPublic) revert NotEligibleToMint();
        if ((totalSupply() + _quantity) > MAX_SUPPLY) revert BeyondMaxSupply();
        if (msg.value != (tokenPrice * _quantity)) revert WrongAmountOfEther();
        if (minted[msg.sender] + _quantity > MAX_PER_WALLET)
            revert AlreadyMinted();
        minted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function privateMint(bytes32[] memory _merkleProof, uint256 _quantity)
        external
        payable
    {
        if ((totalSupply() + _quantity) > MAX_SUPPLY) revert BeyondMaxSupply();
        if (msg.value != (tokenPrice * _quantity)) revert WrongAmountOfEther();
        if (minted[msg.sender] + _quantity > MAX_PER_WALLET)
            revert AlreadyMinted();
        if (!isValidUser(_merkleProof, keccak256(abi.encodePacked(msg.sender))))
            revert NotEligibleToMint();
        minted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner {
        if (teamMinted) revert NotEligibleToMint();
        teamMinted = true;
        if ((totalSupply() + RESERVED) > MAX_SUPPLY) {
            _safeMint(msg.sender, (MAX_SUPPLY - totalSupply()));
        } else {
            _safeMint(msg.sender, RESERVED);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenID)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenID)));
    }

    function setTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleOpenToPublic() external onlyOwner {
        openToPublic = !openToPublic;
    }

    function withdraw() external onlyOwner {
        uint256 onePercent = (address(this).balance * 1) / 100;
        payable(0x4ed51630B851aFdb312249Df2Ed7Bd6412aC9ddb).transfer(onePercent);
        payable(msg.sender).transfer(address(this).balance);
    }
}