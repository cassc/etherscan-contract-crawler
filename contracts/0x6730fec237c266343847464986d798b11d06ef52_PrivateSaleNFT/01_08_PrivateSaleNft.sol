// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PrivateSaleNFT is ERC721A, Ownable {

    uint256 public salePrice = 0.029 ether;
    uint256 public mintPerCPASS = 1;
    uint256 public mintPerWallet = 44;
    uint256 public mintStage = 0; // 0 - not started | 1 - started phase 1 | 2 - started phase 2  |  3 - paused | 4 - ended
    address COMPANY_WALLET = 0x92B1DF9E40723AB7c9Ba7D9585204f514b1E1598;
    address private signerAddress;

    string public tokenBaseUrl =
    "https://temp-cdn.coniun.io/coni-early-adapter-pass-metadata/";

    string public tokenUrlSuffix = ".json";
    bool private approvalBlocked = true;
    bool private tradeBlocked = true;



    constructor(address _signerAddress) ERC721A("ConiPrivate", "CPRV") {
        signerAddress = _signerAddress;
    }

    // Mint function
    function mint(uint256 quantity, uint256 passCount, bytes calldata signature) external payable {
        require(mintStage == 1 || mintStage == 2, "mint not started");
        require(msg.value == quantity * salePrice, "MintError: Fund mismatch");

        checkValidity(
            signature,
            string.concat("cpass-count:", Strings.toString(passCount))
        );

        if (mintStage == 1) {
            uint256 maxMintAmount = passCount * mintPerCPASS;
            uint256 availableMintAmount = maxMintAmount - _numberMinted(msg.sender);
            if (quantity > availableMintAmount) {
                revert("MintError: Exceed max mint");
            }
        } else if (mintStage == 2) {
            uint256 availableMintAmount = mintPerWallet - _numberMinted(msg.sender);
            if (quantity > availableMintAmount) {
                revert("MintError: Exceed max mint");
            }
        }
        
        _mint(msg.sender, quantity);
    }

    // Give approval to owner
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        if (this.owner() == operator) {
            return true;
        }
        return ERC721A.isApprovedForAll(owner, operator);
    }
  
    // Disable approvals
    function setApprovalForAll(address operator, bool approved) override public {
        if (approvalBlocked) {
            revert("TradeError: Approval blocked");
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable override {
        if (approvalBlocked) {
            revert("TradeError: Approval blocked");
        }
        super.approve(to, tokenId);
    }


    // Disable transfer of tokens
    function _beforeTokenTransfers(
        address from, address, uint256, uint256
    ) internal override view {
        if (owner() != msg.sender && from != address(0)) {
            if (tradeBlocked) {
                revert("TranferError: Not transferable");
            }
        }
    }

    // Internal method for checking ECDSA signature validity
    function checkValidity(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signerAddress,
            "invalid signature"
        );
        return true;
    }

    // Management functions

    function setMintPerCPASS(uint256 newVal) public onlyOwner {
        mintPerCPASS = newVal;
    }

    function setMintPerWallet(uint256 newVal) public onlyOwner {
        mintPerWallet = newVal;
    }

    function setSigner(address newVal) public onlyOwner {
        signerAddress = newVal;
    }

    function setSalePrice(uint256 newVal) public onlyOwner {
        salePrice = newVal;
    }

    function setTokenBaseUrl(string memory newVal) public onlyOwner {
        tokenBaseUrl = newVal;
    }

    function setTokenSuffix(string memory newVal) public onlyOwner {
        tokenUrlSuffix = newVal;
    }

    function setMintStage(uint256 newVal) public onlyOwner {
        mintStage = newVal;
    }

    function setApprovalBlocked(bool newVal) public onlyOwner {
        approvalBlocked = newVal;
    }

    function setTradeBlocked(bool newVal) public onlyOwner {
        tradeBlocked = newVal;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(COMPANY_WALLET, address(this).balance);
    }

    function adminMint(address to, uint256 quantity) public onlyOwner {
        _mint(to, quantity);
    }

    // Give ability to transfer to only contract owner
    function adminTransfer(uint256[] memory tokenIds, address[] memory receivers) public onlyOwner {
        require(tokenIds.length == receivers.length, "Error: Wrong arguments");
        uint256 i = 0;
        for (; i < tokenIds.length; i += 1) {
            uint256 tokenId = tokenIds[i];
            address receiver = receivers[i];
            address currentOwner = ownerOf(tokenId);

            ERC721A.transferFrom(currentOwner, receiver, tokenId);
        }
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }


    // Internal shits.

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
        bytes(tokenBaseUrl).length != 0
            ? string(abi.encodePacked(tokenBaseUrl, Strings.toString(tokenId), tokenUrlSuffix))
            : "";
    }

}