//SPDX-License-Identifier: MIT

/*************************************
*                                    *
*     developed by brandneo GmbH     *
*        https://brandneo.de         *
*                                    *
**************************************/

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface Booster {
    function ownerOf(uint256 tokenId) view external returns (address);
    function burn(uint256 tokenId) external;
}

contract Baller is ERC721A, ERC721AQueryable, Ownable, DefaultOperatorFilterer {
    enum ContractStatus {
        Claim,
        Paused
    }

    string  public baseURI;
    uint256 public maxSupply = 5979;
    Booster public booster;
    address public payoutWallet = 0x560a249eDd3f784cFDaf05945dB20dB674429ab0;

    ContractStatus public status = ContractStatus.Paused;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(address _boosterAddress, string memory _baseURL) ERC721A ("MOONCOURT BALLER", "BALLER") {
        baseURI = _baseURL;
        booster = Booster(_boosterAddress);
    }

    function setBaseURI(string memory _baseURL) external onlyOwner {
        baseURI = _baseURL;
    }

    function setBoosterAddress(address _boosterAddress) external onlyOwner {
        booster = Booster(_boosterAddress);
    }

    function setContractStatus(ContractStatus _status) external onlyOwner {
        status = _status;
    }

    function setPayoutWallet(address _wallet) external onlyOwner {
        payoutWallet = _wallet;
    }

    function claim(uint256[] calldata tokenIds) external callerIsUser {
        require(status == ContractStatus.Claim, "Claiming not available");
        
        uint256 quantity = tokenIds.length;

        require(_totalMinted() + (quantity * 3) <= maxSupply, "Not enough supply");

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            require(booster.ownerOf(tokenId) == msg.sender, "Not the token owner");
            booster.burn(tokenId);
        }

        _safeMint(msg.sender, quantity * 3);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        address owner = payable(payoutWallet);

        bool success;

        (success,) = owner.call{value : (amount)}("");
        require(success, "Transaction Unsuccessful");
    }

    /* Overrides */

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(to) {
        super.approve(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}