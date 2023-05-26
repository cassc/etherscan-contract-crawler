//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//  ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄  ▄▄▄     ▄▄▄▄▄▄▄    ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄
// █      ██       █       █      ██   █   █       █  █      ██       █       █       █
// █  ▄    █   ▄   █   ▄   █  ▄    █   █   █    ▄▄▄█  █  ▄    █   ▄   █   ▄▄▄▄█  ▄▄▄▄▄█
// █ █ █   █  █ █  █  █ █  █ █ █   █   █   █   █▄▄▄   █ █ █   █  █ █  █  █  ▄▄█ █▄▄▄▄▄
// █ █▄█   █  █▄█  █  █▄█  █ █▄█   █   █▄▄▄█    ▄▄▄█  █ █▄█   █  █▄█  █  █ █  █▄▄▄▄▄  █
// █       █       █       █       █       █   █▄▄▄   █       █       █  █▄▄█ █▄▄▄▄▄█ █
// █▄▄▄▄▄▄██▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄██▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█  █▄▄▄▄▄▄██▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█

// Smart Contract by: @backseats_eth

contract DoodleDogs is ERC721, Ownable {

    // Setup

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // Public Properties

    bool public mintEnabled;

    // Private Properties

    string private _baseTokenURI;

    // Internal Properties

    uint internal price = 0.025 ether;
    address internal withdrawAddress;

    // Events

    event Minted(address indexed _who, uint indexed _amount);
    event FundsWithdrawn(uint indexed _amount);

    // Constructor

    constructor(address _withdrawAddress, string memory _uri) ERC721("Doodle Dogs", "DOODLEDOGS") {
        withdrawAddress = _withdrawAddress;
        _baseTokenURI = _uri;
    }

    // Public Functions

    function mint(uint _amount) public payable {
        require(mintEnabled, 'Mint paused');
        require(doodleDogsMinted() + _amount < 10_001, 'Exceeds max Dog supply');
        require((_amount > 0 && _amount < 21), 'Mint 1-20');
        require(price * _amount == msg.value, "Insufficient ETH");

        for(uint i = 0; i < _amount; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, doodleDogsMinted());
        }
        emit Minted(msg.sender, _amount);
    }

    function doodleDogsMinted() public view returns (uint) {
        return _tokenSupply.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Ownable Functions

    function setMintEnabled(bool _val) public onlyOwner {
        mintEnabled = _val;
    }

    function devMint(uint _amount, address _who) public onlyOwner {
        require(doodleDogsMinted() + _amount < 10_001, 'Exceeds max Dog supply');
        for(uint i = 0; i < _amount; i++) {
            _tokenSupply.increment();
            _safeMint(_who, doodleDogsMinted());
        }
        emit Minted(_who, _amount);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setWithdrawAddress(address _address) public onlyOwner {
        withdrawAddress = _address;
    }

    // Important: Set new price in wei (i.e. 50000000000000000 for 0.05 ETH)
    function setPrice(uint _newPrice) public onlyOwner {
        price = _newPrice;
    }

    // Withdraws the balance of the contract to the team's wallet
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = payable(withdrawAddress).call{value: balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        emit FundsWithdrawn(balance);
    }

}