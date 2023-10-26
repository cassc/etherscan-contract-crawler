// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//       ██     ▀████▀   ▀███▀▀▀██▄▀███▀   ▀███▀███▄   ▀███▀████▀ ▀███▀   ▄█▀▀▀█▄█
//      ▄██▄      ██       ██   ▀██▄██       █   ███▄    █   ██   ▄█▀    ▄██    ▀█
//     ▄█▀██▓     ██       ██   ▄██ ██       █   █ ███   █   ██ ▄█▀      ▀███▄    
//    ▄█  ▀██     ██       ███████  ██       █   █  ▀██▄ █   █████▄        ▀█████▄
//    ███▓█▓██    █▓       ██       ██       ▓   █   ▀██▄▓   ▓█  ██▓           ▀██
//   ▓▀      ██   █▓       █▓       ██       ▓   ▓     ▓█▓   ▓█   ▀▓▓▄   ██     ██
//    ▓▓▓▓█▓▓█    ▓▓       █▓       ▓█       ▓   ▓   ▀▓▓▓▓   ▓▓    ▓▒▓   ▓     ▀█▓
//   ▓▀      ▓▓   ▒▓       ▓▓       ▓▓▓     ▓▓   ▓     ▓▓▓   ▓▓     ▒▓▓▓ ▓▓     ▓▓
// ▒ ▒ ▒   ▒ ▒▒▒▒▓▒ ▒    ▒▓▒▓▒       ▒ ▒ ▒ ▒▓▒ ▒ ▒ ▒    ▒▓▓▒ ▒ ▒      ▒ ▒▒▓▒ ▒ ▒▓ 

// Contract by @txorigin

contract AIPunks is Ownable, ERC721A {
    uint256 public maxSupply                    = 5000;
    uint256 public maxFreeSupply                = 2000;

    uint256 public maxPerAddressDuringFreeMint  = 3;
    uint256 public maxPerTxDuringMint           = 5;
    uint256 public maxPerAddressDuringMint      = 20;
    
    uint256 public price                        = 0.007 ether;
    bool    public saleIsActive                 = false;

    address constant internal DEV_ADDRESS       = 0xDEADd426B0EC914b636121C5F3973F095D3Fa666;
    address constant internal TEAM_ADDRESS      = 0x1D412eAbeE8222A13898594b91812120BA138814;

    string private _baseTokenURI;

    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public freeMintedAmount;

    constructor() ERC721A("AI Punks", "AIPunks") {}

    modifier mintCompliance() {
        require(saleIsActive, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

    function mint(uint256 _quantity) external payable mintCompliance() {
        require(
            maxSupply >= totalSupply() + _quantity,
            "AIPunks: Exceeds max supply."
        );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(
            _mintedAmount + _quantity <= maxPerAddressDuringMint,
            "AIPunks: Exceeds max mints per address!"
        );
        require(
            _quantity > 0 && _quantity <= maxPerTxDuringMint,
            "Invalid mint amount."
        );
        mintedAmount[msg.sender] = _mintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
        refundIfOver(price * _quantity);
    }

    function freeMint(uint256 _quantity) external mintCompliance() {
        require(
            maxFreeSupply >= totalSupply() + _quantity, 
            "AIPunks: Exceeds max free supply."
        );
        uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
        require(
            _freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,
            "AIPunks: Exceeds max free mints per address!"
        );
        require(
            _quantity > 0 && _quantity <= maxPerAddressDuringFreeMint,
            "Invalid free mint amount."
        );
        freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function devMint(address _receiver, uint256 _quantity) external onlyOwner {
	    require(
            maxSupply >= totalSupply() + _quantity,
            "Cannot reserve more than max supply"
        );
        _safeMint(_receiver, _quantity);
    }

    function refundIfOver(uint256 _price) private {
        require(msg.value >= _price, "Not enough ETH sent.");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTxDuringMint = _amount;
    }

    function setMaxPerAddress(uint256 _amount) external onlyOwner {
        maxPerAddressDuringMint = _amount;
    }

    function setMaxFreePerAddress(uint256 _amount) external onlyOwner {
        maxPerAddressDuringFreeMint = _amount;
    }

    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function addMaxFreeSupply(uint256 _amount) public onlyOwner {
        require(
            maxFreeSupply + _amount <= maxSupply, 
            "Max free supply cannot exceed max supply."
        );
        maxFreeSupply += _amount;
    }

    function cutMaxSupply(uint256 _amount) public onlyOwner {
        require(
            maxSupply - _amount >= totalSupply(), 
            "Supply cannot fall below minted tokens."
        );
        maxSupply -= _amount;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawBalance() external onlyOwner {
        uint256 _balance = address(this).balance;

        (bool success, ) = payable(DEV_ADDRESS).call{
            value: (_balance * 2200) / 10000
        }("");
        require(success, "DEV_ADDRESS transfer failed.");

        (success, ) = payable(TEAM_ADDRESS).call{
            value: address(this).balance
        }("");
        require(success, "TEAM_ADDRESS transfer failed.");
    }
}