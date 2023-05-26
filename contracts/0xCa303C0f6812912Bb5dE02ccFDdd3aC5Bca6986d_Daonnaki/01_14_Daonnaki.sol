//SPDX-License-Identifier: UNLICENSED

/*
 *  Daonnaki NFT Collection
 *  Created by NFTSociety.io
 */

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NSClaimer.sol";

contract Daonnaki is ERC721A, Ownable, DefaultOperatorFilterer, NSClaimer {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 10000;
    uint256 public currentSupply = 0;

    uint256 public salePrice = 0.0198 ether;
    uint256 public presalePrice = 0.0185 ether;

    //Placeholders
    address private presaleAddress = address(0xA57C2D44EB8f127CA6C43Cf0Aa1bE8800aEc7c93);
    address private wallet = address(0x8A72c401649A23DE311b8108ec7962979689d083);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmcmU4Q47CQxBksyLy6jRLJ6uVcfoZNKeDwKWo5N72B3Lq";

    bool public revealed = false;
    bool public baseLocked = false;

    bool public claimOpened = false;
    bool public presaleOpened = false;
    bool public saleOpened = false;

    mapping(address => uint256) public mintLog;

    constructor()
        ERC721A("Daonnaki", "DAO")
    {
        transferOwnership(msg.sender);
        //Reserved NFTs to be claimed at any time
        currentSupply = 6209;
    }

    //Opensea Operator Filterer method overwrite
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    // - - - -
    
    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        payable( wallet ).transfer( _balance );
    }

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }

    function totalSupply() public view override returns (uint256) {
        return currentSupply;
    }

    function validateSignature( address _addr, bytes memory _s ) internal view returns (bool){
        bytes32 messageHash = keccak256(
            abi.encodePacked( address(this), msg.sender)
        );

        address signer = messageHash.toEthSignedMessageHash().recover(_s);

        if( _addr == signer ) {
            return true;
        } else {
            return false;
        }
    }

    /**
        Claim reserved NFTs
     */
    function claimReserved() external {
        require( 
            claimOpened, 
            "This phase has not yet started." 
        );

        require( 
            !claimLog[ msg.sender ], 
            "You have already claimed your reserved NFTs." 
        );

        require( 
            reserveLog[ msg.sender ] > 0, 
            "You don't have reserved NFTs for claim." 
        );

        uint256 _am = reserveLog[ msg.sender ];

        mintLog[ msg.sender ] += _am;
        claimLog[ msg.sender ] = true;
        claimed += _am;

        _mint( msg.sender, _am );
    }

    /**
        Presale ( Allowlist ) mint
     */
    function presaleMint(uint256 _amount, bytes calldata signature) external payable {
        //Presale opened check
        require( 
            presaleOpened, 
            "Daonnaki: Allowlist mint is not opened yet." 
        );

        //Min 1 NFT check
        require(_amount > 0, "Daonnaki: You must mint at least one NFT");

        //Check presale signature
        require(
            validateSignature(
                presaleAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        //Price check
        require(
            msg.value >= presalePrice * _amount,
            "Daonnaki: Insufficient ETH amount sent."
        );

        uint256 supply = currentSupply;

        require(
            supply + _amount <= maxSupply,
            "Daonnaki: Mint too large, exceeding the collection supply"
        );

        mintLog[ msg.sender ] += _amount;
        currentSupply += _amount;

        _mint( msg.sender, _amount);
    }

    /**
        Phase 3 of the mint
     */
    function publicMint(uint256 _amount) external payable {
        //Public mint check
        require( 
            saleOpened, 
            "Daonnaki: Public mint is not opened yet." 
        );

        //Price check
        require(
            msg.value >= salePrice * _amount,
            "Daonnaki: Insufficient ETH amount sent."
        );

        uint256 supply = currentSupply;

        require(
            supply + _amount <= maxSupply,
            "Daonnaki: Mint too large, exceeding the collection supply"
        );

        mintLog[ msg.sender ] += _amount;
        currentSupply += _amount;

        _mint( msg.sender, _amount );
    }

    function forceMint(uint256 number, address receiver) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Daonnaki: You can't mint more than max supply"
        );

        currentSupply += number;

        _mint( receiver, number );
    }

    /**
        Force-Claim reserved NFTs
     */
    function forceClaim( address _addr ) external onlyOwner {
        require( 
            !claimLog[ _addr ], 
            "Already claimed." 
        );

        require( 
            reserveLog[ _addr ] > 0, 
            "No NFTs for claim on this address." 
        );

        uint256 _am = reserveLog[ _addr ];

        mintLog[ _addr ] += _am;
        claimLog[ _addr ] = true;
        claimed += _am;

        _mint( _addr, _am );
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Daonnaki: You can't mint more than max supply"
        );

        currentSupply += number;

        _mint( msg.sender, number );
    }

    function addToReserve( address _addr, uint256 _am ) public onlyOwner { 
        uint256 supply = currentSupply;

        require(
            supply + _am <= maxSupply,
            "Daonnaki: You can't add more than max supply"
        );

        require( 
            !claimLog[ _addr ], 
            "Already claimed." 
        );

        currentSupply += _am;
        reserveLog[ _addr ] += _am;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        salePrice = _newPrice;
    }
    
    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    function claimOpen() public onlyOwner { 
        claimOpened = true;
    }

    function claimStop() public onlyOwner { 
        claimOpened = false;
    }

    function saleOpen() public onlyOwner { 
        saleOpened = true;
    }
    
    function saleStop() public onlyOwner {
        saleOpened = false;
    }

    function presaleOpen() public onlyOwner {
        presaleOpened = true;
    }
    
    function presaleStop() public onlyOwner {
        presaleOpened = false;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require( baseLocked == false, "Base URI change has been disabled permanently");

        baseURI = _newBaseURI;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
    }

    // FACTORY
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),'.json'))
                : "";
    }
 
}