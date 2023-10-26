// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Plots is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 125;
    uint256 public constant BATCH_LIMIT = 2;
    uint256 public constant MAX_MINT_PER_WALLET = 2;

    IERC20 public paymentToken;
    address public feeAddress;
    uint256 public fee = 1000000 * 10 ** 18;

    string private _baseTokenURI;
    string private _contractURI;

    constructor(
        address _tokenAddress,
        address _feeAddress
    ) ERC721A("Plots", "PLOT") {
        feeAddress = _feeAddress;
        paymentToken = IERC20(_tokenAddress);
        _setBaseURI(
            "ipfs://bafybeihmeu7c5lwnsie2busw77xxquff6e7txnzyy4vuo6fo3k3cnedpmi/"
        );
   
    }

    // set base uri
    function _setBaseURI(string memory baseURI) private {
        _baseTokenURI = baseURI;
    }

    // retrieve base uri
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // mint NFT for token fee
    function mint(uint256 quantity) external {
        require(quantity <= BATCH_LIMIT, "Exceeds batch limit.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Exceeds max supply.");
        require(balanceOf(msg.sender) + quantity <= MAX_MINT_PER_WALLET , "Exceeds max per wallet.");
        paymentToken.transferFrom(msg.sender, feeAddress, fee * quantity);
        _mint(msg.sender, quantity);
    }

    // set fee (only owner)
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    // set the receiver address (only owner)
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }
    
}