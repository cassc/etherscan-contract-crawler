// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";

error NoContractMints();
error MaxMintExceeded();
error MaxTeamMintExceeded();
error AlreadyMintedAddress();
error NotEnoughEth();
error SalePhaseClosed();
error publicMintNotOpen();
error CallerNotEligible();
error InvalidEtherAmount(); 

contract Renaissance is ERC721A, Ownable, ReentrancyGuard, ERC2981, OperatorFilterer {

    using ECDSA for bytes32;

    uint256 public constant maxSupply = 3450;

    bool public whitelistMintOpen;
    bool public publicMintOpen;
    bool public freeMintOpen;

    // Public address of the address that signs WL sigs
    address private _signerAddress = 0xabcda23d3ce3404149B74E05029778D9346511DE;

    // OperatorFilterer Default address
    address constant SUBSCRIPTION = address(0);

    // Config
    uint256 teamSupply = 300;
    uint256 teamMinted = 0;

    uint256 advisorSupply = 100;
    uint256 advisorMintedTotal = 0;

    uint256 freeMintSupply = 82;
    uint256 freeMintMinted = 0;

    uint256 saleSupply = 2968;
    uint256 saleMinted = 0;

    uint256 maxMintWL = 15;
    uint256 maxMintPublic = 20;
    uint256 advisorMaxMint = 20;

    uint256 whitelistMintPrice = 0.069 ether;
    uint256 publicMintPrice = 0.079 ether;

    string private _baseTokenURI = "https://red-keen-lamprey-650.mypinata.cloud/ipfs/QmQXnh5xxDRiUj5eWpYc8Wt8PrRjC8qRcsip3DLWKpQBEc/";

    // Mappings
    mapping (address => uint256) freeMints;
    mapping (address => uint256) tokensMinted;
    mapping (address => uint256) advisorMint;
    mapping (address => uint256) advisorMinted;

    // Constructor
    constructor () ERC721A("0xAI Genesis", "0XAI") OperatorFilterer(SUBSCRIPTION, false) {

    }


    // === Minting ===
    // ---------------------

    // Team mint
    function teamMint(uint256 amount) external onlyOwner {
        if (_totalMinted() + amount > maxSupply) revert MaxMintExceeded();
        if (teamMinted + amount > teamSupply) revert MaxTeamMintExceeded();

        teamMinted += amount;
        
        _mint(msg.sender, amount);
  }

    function mintAdvisor(uint256 amount) external {
        if (tx.origin != msg.sender) revert NoContractMints();
        if (advisorMint[msg.sender] != 1) revert CallerNotEligible();
        if (advisorMinted[msg.sender] + amount > advisorMaxMint) revert MaxMintExceeded();
        if (_totalMinted() + amount > maxSupply) revert MaxMintExceeded();
        if (advisorMintedTotal + amount > advisorSupply) revert MaxMintExceeded();

        if (advisorMinted[msg.sender] + amount == advisorMaxMint) {
            advisorMint[msg.sender] = 0;
        }

        advisorMinted[msg.sender] += amount;
        advisorMintedTotal += amount;

        _mint(msg.sender, amount);
    }

    function mintWhitelist (bytes calldata signature, uint256 amount) external payable {
        if (!whitelistMintOpen) revert SalePhaseClosed();
        if (tx.origin != msg.sender) revert NoContractMints();
        if (_totalMinted() + amount > maxSupply) revert MaxMintExceeded();
        if (tokensMinted[msg.sender] + amount > maxMintWL) revert MaxMintExceeded();
        if (saleMinted + amount > saleSupply) revert MaxMintExceeded();
        if (msg.value != whitelistMintPrice*amount) revert InvalidEtherAmount();

        // Signature verification
        require(_signerAddress == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature), "Signer address mismatch.");

        tokensMinted[msg.sender] += amount;
        saleMinted += amount;

        _mint(msg.sender, amount);

    }

    // Public mint
    // Should have a limit on how much can be minted by address
    function mintPublic (uint256 amount) external payable {
        if (!publicMintOpen) revert publicMintNotOpen();
        if (tx.origin != msg.sender) revert NoContractMints();
        if (_totalMinted() + amount > maxSupply) revert MaxMintExceeded();
        if (tokensMinted[msg.sender] + amount > maxMintPublic) revert MaxMintExceeded();
        if (saleMinted + amount > saleSupply) revert MaxMintExceeded();
        if (msg.value != publicMintPrice*amount) revert InvalidEtherAmount();

        tokensMinted[msg.sender] += amount;
        saleMinted += amount;

        _mint(msg.sender, amount);
    }

    // Mint free tokens if caller is eligible
    function mintFree () external {
        if (!freeMintOpen) revert SalePhaseClosed();
        if (tx.origin != msg.sender) revert NoContractMints();
        if (_totalMinted() + 1 > maxSupply) revert MaxMintExceeded();
        if (freeMints[msg.sender] != 1) revert CallerNotEligible();
        if (freeMintMinted + 1 > freeMintSupply) revert MaxMintExceeded();

        freeMints[msg.sender]--;
        tokensMinted[msg.sender] += 1;
        freeMintMinted += 1;

        _mint(msg.sender, 1);

    }

    //
    function userHasAdvisorMint(address userAddress) external view returns(bool) {
        if (advisorMint[userAddress] == 1) {
            return true;
        } else {
            return false;
        }
    }

    function userHasFreeMint(address userAddress) external view returns(bool) {
        if (freeMints[userAddress] == 1) {
            return true;
        } else {
            return false;
        }
    }


    // === Admin Commands ===

    // Withdraw all funds
      function withdraw() public onlyOwner payable {
        (bool os, ) = msg.sender.call{value: address(this).balance}('');
        require(os, 'Withdraw unsuccessful');
    }

    // Set the base URI for tokens
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    // toggle the Whitelist sale
    function toggleWhitelistSale () external onlyOwner {
        whitelistMintOpen = !whitelistMintOpen;
    }

    // Toggle the public sale
    function togglePublicSale () external onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    // Toggle the free mint claim
    function toggleFreeMintClaim () external onlyOwner {
        freeMintOpen = !freeMintOpen;
    }


    function setWhitelistSupply(uint256 whitelistSupply) external onlyOwner {
        saleSupply = whitelistSupply;
    }


    function setFreemintSupply(uint256 freemintSupply) external onlyOwner {
        freeMintSupply = freemintSupply;
    }

    function setMintFree (address walletAddress) external onlyOwner {
        require(freeMints[walletAddress] < 1);
        freeMints[walletAddress] = 1;
    }


    function setMintAdvisor (address walletAddress) external onlyOwner {
        require(advisorMint[walletAddress] < 1);
        advisorMint[walletAddress] = 1;
    }

    // We want the starting token Id to be 1 not 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    // === Info ===
    // Simple getters

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    // Sale status getters and setters
    // We don't really need these since the data is public
    // ======

    function getWhitelistStatus() public view returns (bool) {
        return whitelistMintOpen;
    }

    function getPublicStatus() public view returns (bool) {
        return publicMintOpen;
    }

    function getFreeMintStatus() public view returns (bool) {
        return freeMintOpen;
    }

    // ===== OperatorFilterer

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    // Interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

}