// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IBread {
    function mint(address user, uint256 amount) external;
    function burn(address user, uint256 amount) external;
}

contract Duckz is ERC721A, Ownable {
    using SafeMath for uint256;
    
    //Sale States
    bool public isAllowListActive = false;
    bool public isPublicSaleActive = false;
    mapping (address => bool) public mintClaimed;
    
    //Privates
    string private _baseURIextended;
    address private signer;
    address private payoutWallet = 0x7f504FdbdD987fd1E0390DCEa0f3c9D6A4b8c7e3;
    
    //Constants
    uint256 public constant MAX_SUPPLY = 555;
    uint256 public constant PRICE_PER_TOKEN = 0.08 ether;
    uint256 public constant RESERVE_COUNT = 55;
    
    constructor() ERC721A("HypnoDuckzGenesis", "DUCKZ") {
    }

    //Allowed Minting
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function mintAllowList(address _address, bytes calldata _voucher) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(!mintClaimed[_address], "Already claimed mint");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(msg.value >= PRICE_PER_TOKEN, "Ether value sent is not correct");
        require(msg.sender == _address, "Not your voucher");

        bytes32 hash = keccak256(
            abi.encodePacked(_address)
        );
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        mintClaimed[_address] = true;
        _safeMint(_address, 1);
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }
    //
    
    //Public Minting
    function setPublicSaleState(bool _isPublicSaleActive) external onlyOwner {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function mintNFT() external payable {
        uint256 ts = totalSupply();
        require(isPublicSaleActive, "Public sale is not active");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(msg.value >= PRICE_PER_TOKEN, "Ether value sent is not correct");

        _safeMint(msg.sender, 1);
    }
    //

    //Overrides
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    //

    function reserve() external onlyOwner {
        require(totalSupply() == 0, "Tokens already reserved");
        _safeMint(msg.sender, RESERVE_COUNT);
    }
    
    //Withdraw balance
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(payoutWallet).transfer(balance);
    }
    //
}